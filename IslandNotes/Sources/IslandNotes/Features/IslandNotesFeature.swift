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
    @ObservationIgnored private var pendingActivityUpdate: PendingActivityUpdate?
    @ObservationIgnored private var activityUpdateTask: Task<Void, Never>?

    var currentNote: NoteSnapshot? { workspace.currentNote }
    var library: [NoteSnapshot] { workspace.library }
    private(set) var pinState: PinState = .unpinned
    private(set) var editingText = ""
    private(set) var didReachCharacterLimit = false
    private(set) var isCharacterCountVisible = false
    private(set) var deleteConfirmation: DeleteConfirmation?
    private(set) var feedbackMessage: String?
    private(set) var hasActivityInconsistency = false

    var characterProgress: CharacterProgress {
        let used = min(editingText.count, TextLimiter.maximumCharacterCount)
        return CharacterProgress(
            used: used,
            remaining: TextLimiter.maximumCharacterCount - used
        )
    }

    var canArchive: Bool { currentNote.map { NoteContent.isActionable($0.body) } == true }
    var canPin: Bool { currentNote.map { NoteContent.isActionable($0.body) } == true }
    var canDelete: Bool { currentNote.map { NoteContent.isActionable($0.body) } == true }
    let canOpenLibrary = true

    init(
        workspace: NoteWorkspace,
        liveActivityController: LiveActivityControlling
    ) {
        self.workspace = workspace
        self.liveActivityController = liveActivityController
    }

    convenience init(
        modelContext: ModelContext,
        liveActivityController: LiveActivityControlling,
        now: @escaping () -> Date = Date.init
    ) {
        self.init(
            workspace: NoteWorkspace(modelContext: modelContext, now: now),
            liveActivityController: liveActivityController
        )
    }

    func bootstrap() async throws {
        try workspace.bootstrap()
        editingText = currentNote?.body ?? ""
        await reconcileActivities()
    }

    func editCurrentNote(
        proposedText: String,
        markedTextActive: Bool
    ) async throws {
        let limitResult = stageEditorText(
            proposedText: proposedText,
            markedTextActive: markedTextActive
        )
        guard !markedTextActive else { return }
        try persistStagedEditorText(limitResult.acceptedText)
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
        editingText = limitResult.acceptedText
        didReachCharacterLimit = limitResult.wasTruncated
        return limitResult
    }

    func persistStagedEditorText(_ stagedText: String) throws {
        guard editingText == stagedText else { return }
        do {
            guard try workspace.commitCurrentNote(stagedText) else { return }
            feedbackMessage = nil
        } catch {
            feedbackMessage = "内容尚未保存"
            throw error
        }
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

    func completeEditing() throws {
        try persistStagedEditorText(editingText)
    }

    func revealCharacterCount() {
        isCharacterCountVisible = true
    }

    func archiveCurrentNote() async throws {
        guard canArchive, let currentNote else { return }
        guard await endCurrentActivityBarrier(noteID: currentNote.id) else { return }

        do {
            guard try workspace.moveCurrentNoteToLibrary() else { return }
        } catch {
            feedbackMessage = "放入便签库未完成"
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
            feedbackMessage = "交换未完成"
            throw error
        }

        resetEditingStateAfterCurrentNoteChange()
    }

    func requestDelete() {
        guard canDelete else { return }
        deleteConfirmation = .pending(message: "删除后无法恢复")
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
            feedbackMessage = "删除未完成"
            throw error
        }

        deleteConfirmation = nil
        resetEditingStateAfterCurrentNoteChange()
    }

    func startPinning() async {
        guard canPin, let currentNote else { return }
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
            feedbackMessage = "挂起未完成，请重试"
            return
        }

        let refreshed = await liveActivityController.activities().filter(\.isActive)
        pinState = refreshed.count == 1 && refreshed.first?.noteID == currentNote.id
            ? .pinned
            : .unpinned
        hasActivityInconsistency = pinState == .unpinned && !refreshed.isEmpty
        if pinState == .unpinned {
            feedbackMessage = "挂起未完成，请重试"
        }
    }

    func cancelPinning() async {
        guard let currentNote else { return }
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
            feedbackMessage = "系统展示可能尚未同步"
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
        feedbackMessage = "系统展示正在整理，请重试"
    }

#if DEBUG
    static func preview(
        modelContext: ModelContext,
        liveActivityController: LiveActivityControlling,
        records: [NoteRecord],
        currentNoteID: UUID,
        pinState: PinState = .unpinned,
        didReachCharacterLimit: Bool = false,
        isCharacterCountVisible: Bool = false,
        deleteConfirmation: DeleteConfirmation? = nil,
        feedbackMessage: String? = nil
    ) -> IslandNotesFeature {
        let workspace = NoteWorkspace(modelContext: modelContext)
        workspace.loadPreview(records: records, currentNoteID: currentNoteID)
        let feature = IslandNotesFeature(
            workspace: workspace,
            liveActivityController: liveActivityController
        )
        feature.editingText = workspace.currentNote?.body ?? ""
        feature.pinState = pinState
        feature.didReachCharacterLimit = didReachCharacterLimit
        feature.isCharacterCountVisible = isCharacterCountVisible
        feature.deleteConfirmation = deleteConfirmation
        feature.feedbackMessage = feedbackMessage
        return feature
    }
#endif

    private func resetEditingStateAfterCurrentNoteChange() {
        pinState = .unpinned
        didReachCharacterLimit = false
        isCharacterCountVisible = false
        editingText = currentNote?.body ?? ""
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
        feedbackMessage = "取消挂起尚未完成"
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
