import Foundation
import Observation
import SwiftData

enum PinState: Equatable, Sendable {
    case unpinned
    case pinned
}

enum DeleteConfirmation: Equatable, Sendable {
    case pending(message: String)
}

private struct PendingActivityUpdate: Equatable, Sendable {
    let noteID: UUID
    let body: String
    let version: Int
}

@MainActor
@Observable
final class IslandNotesFeature {
    private let workspace: NoteWorkspace
    private let liveActivityController: LiveActivityControlling
    private let characterDetailScheduler: CharacterDetailScheduler
    @ObservationIgnored private var pendingActivityUpdate: PendingActivityUpdate?
    @ObservationIgnored private var activityUpdateTask: Task<Void, Never>?
    @ObservationIgnored private var characterDetailCancellation: CharacterDetailCancellation?

    var currentNote: NoteSnapshot? { workspace.currentNote }
    var library: [NoteSnapshot] { workspace.library }
    private(set) var pinState: PinState = .unpinned
    private(set) var editingDraft: String?
    private(set) var isCharacterCountVisible = false
    private(set) var deleteConfirmation: DeleteConfirmation?
    private(set) var feedbackMessage: String?
    private(set) var hasActivityInconsistency = false
    private(set) var isArchiveInFlight = false
    private(set) var isLiveTransitionInFlight = false

    var isEditing: Bool { editingDraft != nil }
    var editingText: String { editingDraft ?? currentNote?.body ?? "" }
    var didReachCharacterLimit: Bool {
        characterProgress.used == TextLimiter.maximumCharacterCount
    }

    var characterProgress: CharacterProgress {
        let source = editingDraft ?? currentNote?.body ?? ""
        let used = min(source.count, TextLimiter.maximumCharacterCount)
        return CharacterProgress(
            used: used,
            remaining: TextLimiter.maximumCharacterCount - used
        )
    }

    var canArchive: Bool {
        !isArchiveInFlight
            && !isLiveTransitionInFlight
            && currentNote.map { NoteContent.isActionable($0.body) } == true
    }
    var canPin: Bool {
        !isArchiveInFlight
            && !isLiveTransitionInFlight
            && currentNote.map { NoteContent.isActionable($0.body) } == true
    }
    var canTogglePin: Bool {
        guard !isArchiveInFlight, !isLiveTransitionInFlight else { return false }
        return pinState == .pinned || canPin
    }
    var canDelete: Bool {
        !isArchiveInFlight
            && !isLiveTransitionInFlight
            && currentNote.map { NoteContent.isActionable($0.body) } == true
    }
    let canOpenLibrary = true

    init(
        workspace: NoteWorkspace,
        liveActivityController: LiveActivityControlling,
        characterDetailScheduler: CharacterDetailScheduler
    ) {
        self.workspace = workspace
        self.liveActivityController = liveActivityController
        self.characterDetailScheduler = characterDetailScheduler
    }

    convenience init(
        modelContext: ModelContext,
        liveActivityController: LiveActivityControlling,
        now: @escaping () -> Date = Date.init
    ) {
        self.init(
            workspace: NoteWorkspace(modelContext: modelContext, now: now),
            liveActivityController: liveActivityController,
            characterDetailScheduler: .live
        )
    }

    func bootstrap() async throws {
        try workspace.bootstrap()
        editingDraft = nil
        await reconcileActivities()
    }

    func beginEditing() {
        guard editingDraft == nil else { return }
        let source = currentNote?.body ?? ""
        editingDraft = source
        feedbackMessage = nil
    }

    @discardableResult
    func stageEditorText(
        proposedText: String,
        markedTextActive: Bool
    ) -> TextLimitResult {
        let limitResult = TextLimiter.limit(
            proposedText: proposedText,
            markedTextActive: markedTextActive
        )
        guard editingDraft != nil else { return limitResult }
        editingDraft = limitResult.acceptedText
        return limitResult
    }

    func completeEditing() throws {
        guard let editingDraft else { return }
        let finalized = TextLimiter.limit(
            proposedText: editingDraft,
            markedTextActive: false
        )
        self.editingDraft = finalized.acceptedText
        do {
            guard try workspace.commitCurrentNote(finalized.acceptedText) else { return }
            feedbackMessage = nil
        } catch {
            feedbackMessage = "Your note hasn't been saved."
            throw error
        }
        self.editingDraft = nil
        if pinState == .pinned, let currentNote {
            enqueueActivityUpdate(
                PendingActivityUpdate(
                    noteID: currentNote.id,
                    body: currentNote.body,
                    version: currentNote.contentVersion
                )
            )
        }
    }

    func revealCharacterCount() {
        characterDetailCancellation?.cancel()
        isCharacterCountVisible = true
        characterDetailCancellation = characterDetailScheduler.schedule { [weak self] in
            self?.isCharacterCountVisible = false
            self?.characterDetailCancellation = nil
        }
    }

    func archiveCurrentNote() async throws {
        guard canArchive, let currentNote else { return }
        isArchiveInFlight = true
        defer { isArchiveInFlight = false }
        guard await endCurrentActivityBarrier(noteID: currentNote.id) else { return }

        do {
            guard try workspace.moveCurrentNoteToLibrary() else { return }
        } catch {
            feedbackMessage = "Couldn't move the note to your library."
            throw error
        }

        resetEditingStateAfterCurrentNoteChange()
    }

    func selectLibraryNote(id: UUID) async throws {
        guard library.contains(where: { $0.id == id }),
              let currentNote else { return }
        guard await endCurrentActivityBarrier(noteID: currentNote.id) else { return }

        do {
            guard try workspace.replaceCurrentNote(withLibraryNoteID: id) else { return }
        } catch {
            feedbackMessage = "Couldn't replace the current note."
            throw error
        }

        resetEditingStateAfterCurrentNoteChange()
    }

    func requestDelete() {
        guard canDelete else { return }
        deleteConfirmation = .pending(message: "This cannot be undone.")
    }

    func cancelDelete() {
        deleteConfirmation = nil
    }

    func confirmDeleteCurrentNote() async throws {
        guard deleteConfirmation != nil,
              let currentNote else { return }
        guard await endCurrentActivityBarrier(noteID: currentNote.id) else { return }

        do {
            guard try workspace.deleteCurrentNote() else { return }
        } catch {
            feedbackMessage = "Couldn't delete the note."
            throw error
        }

        deleteConfirmation = nil
        resetEditingStateAfterCurrentNoteChange()
    }

    func startPinning() async {
        guard canPin, let currentNote else { return }
        isLiveTransitionInFlight = true
        defer { isLiveTransitionInFlight = false }
        await reconcileActivities()
        if pinState == .pinned { return }
        guard !hasActivityInconsistency else { return }
        feedbackMessage = nil

        let attributes = IslandNoteActivityAttributes(noteID: currentNote.id)
        let state = IslandNoteActivityAttributes.ContentState(
            body: currentNote.body,
            version: currentNote.contentVersion
        )
        do {
            try ActivityPayloadSizer.validate(attributes: attributes, state: state)
            try await liveActivityController.request(
                noteID: currentNote.id,
                body: currentNote.body,
                version: currentNote.contentVersion
            )
        } catch {
            pinState = .unpinned
            feedbackMessage = "Couldn't start Live. Try again."
            return
        }

        let refreshed = await liveActivityController.activities().filter(\.isActive)
        pinState = refreshed.count == 1 && refreshed.first?.noteID == currentNote.id
            ? .pinned
            : .unpinned
        hasActivityInconsistency = pinState == .unpinned && !refreshed.isEmpty
        if pinState == .unpinned {
            feedbackMessage = "Couldn't start Live. Try again."
        }
    }

    func cancelPinning() async {
        guard canTogglePin, let currentNote else { return }
        isLiveTransitionInFlight = true
        defer { isLiveTransitionInFlight = false }
        _ = await endCurrentActivityBarrier(noteID: currentNote.id)
    }

    func flushPendingActivityUpdate() async {
        activityUpdateTask?.cancel()
        activityUpdateTask = nil
        guard let pendingActivityUpdate else { return }

        let activities = await liveActivityController.activities()
            .filter { $0.isActive && $0.noteID == pendingActivityUpdate.noteID }
        guard activities.count == 1, let activity = activities.first else {
            self.pendingActivityUpdate = nil
            pinState = .unpinned
            return
        }

        let attributes = IslandNoteActivityAttributes(noteID: pendingActivityUpdate.noteID)
        let state = IslandNoteActivityAttributes.ContentState(
            body: pendingActivityUpdate.body,
            version: pendingActivityUpdate.version
        )

        do {
            try ActivityPayloadSizer.validate(attributes: attributes, state: state)
            try await liveActivityController.update(
                activityID: activity.activityID,
                body: pendingActivityUpdate.body,
                version: pendingActivityUpdate.version
            )
            self.pendingActivityUpdate = nil
            feedbackMessage = nil
        } catch {
            feedbackMessage = "Live may not be up to date."
        }

        let refreshed = await liveActivityController.activities()
            .filter { $0.isActive && $0.noteID == pendingActivityUpdate.noteID }
        pinState = refreshed.isEmpty ? .unpinned : .pinned
        if refreshed.isEmpty {
            self.pendingActivityUpdate = nil
        }
    }

    func reconcileActivities() async {
        guard let currentNote else { return }
        feedbackMessage = nil

        let active = await liveActivityController.activities()
            .filter(\.isActive)
        let currentActivities = active
            .filter { $0.noteID == currentNote.id }
            .sorted { $0.activityID < $1.activityID }
        let keeperID = currentActivities.first?.activityID
        let activitiesToEnd = active.filter { $0.activityID != keeperID }

        for activity in activitiesToEnd {
            try? await liveActivityController.end(activityID: activity.activityID)
        }

        let refreshed = await liveActivityController.activities()
            .filter(\.isActive)
        let refreshedCurrent = refreshed.filter { $0.noteID == currentNote.id }

        if refreshed.isEmpty {
            pinState = .unpinned
            hasActivityInconsistency = false
            return
        }

        if refreshed.count == 1, refreshedCurrent.count == 1 {
            pinState = .pinned
            hasActivityInconsistency = false
            return
        }

        pinState = .unpinned
        hasActivityInconsistency = true
        feedbackMessage = "Live is being reconciled. Try again."
    }

#if DEBUG
    static func preview(
        modelContext: ModelContext,
        liveActivityController: LiveActivityControlling,
        records: [NoteRecord],
        currentNoteID: UUID,
        pinState: PinState = .unpinned,
        editingDraft: String? = nil,
        isCharacterCountVisible: Bool = false,
        deleteConfirmation: DeleteConfirmation? = nil,
        feedbackMessage: String? = nil
    ) -> IslandNotesFeature {
        let workspace = NoteWorkspace(modelContext: modelContext)
        workspace.loadPreview(records: records, currentNoteID: currentNoteID)
        let feature = IslandNotesFeature(
            workspace: workspace,
            liveActivityController: liveActivityController,
            characterDetailScheduler: .live
        )
        feature.editingDraft = editingDraft
        feature.pinState = pinState
        feature.isCharacterCountVisible = isCharacterCountVisible
        feature.deleteConfirmation = deleteConfirmation
        feature.feedbackMessage = feedbackMessage
        return feature
    }
#endif

    private func resetEditingStateAfterCurrentNoteChange() {
        pinState = .unpinned
        characterDetailCancellation?.cancel()
        characterDetailCancellation = nil
        isCharacterCountVisible = false
        editingDraft = nil
    }

    private func endCurrentActivityBarrier(noteID: UUID) async -> Bool {
        feedbackMessage = nil
        let currentActivities = await liveActivityController.activities()
            .filter { $0.isActive && $0.noteID == noteID }

        for activity in currentActivities {
            try? await liveActivityController.end(activityID: activity.activityID)
        }

        let remaining = await liveActivityController.activities()
            .filter { $0.isActive && $0.noteID == noteID }
        if remaining.isEmpty {
            activityUpdateTask?.cancel()
            activityUpdateTask = nil
            pendingActivityUpdate = nil
            pinState = .unpinned
            hasActivityInconsistency = false
            return true
        }

        pinState = .pinned
        hasActivityInconsistency = false
        feedbackMessage = "Couldn't stop Live."
        return false
    }

    private func enqueueActivityUpdate(_ update: PendingActivityUpdate) {
        pendingActivityUpdate = update
        activityUpdateTask?.cancel()
        activityUpdateTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            await self?.flushPendingActivityUpdate()
        }
    }
}
