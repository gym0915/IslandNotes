import SwiftUI

#if DEBUG
private let initialUITestingMarkedTextActive = ProcessInfo.processInfo.arguments.contains(
    "--uitesting-active-marked-text"
)
#else
private let initialUITestingMarkedTextActive = false
#endif

struct WorkbenchView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Bindable var feature: IslandNotesFeature
    @State private var liveTransition: LiveActionTransition?
    @State private var editorComposition = WorkbenchEditorCompositionState(
        hasMarkedText: initialUITestingMarkedTextActive
    )

    var reduceMotionOverride: Bool? = nil
    let openNoteLibrary: () -> Void
    let openSettings: () -> Void

    private var deleteConfirmationMessage: String? {
        guard case let .pending(message)? = feature.deleteConfirmation else { return nil }
        return message
    }

    private var dockModel: WorkbenchActionDockModel {
        WorkbenchActionDockModel.make(
            contentAvailability: feature.contentActionAvailability,
            liveAvailability: feature.liveActionAvailability,
            pinState: feature.pinState,
            transition: liveTransition
        )
    }

    private var canCommitEditing: Bool {
        editorComposition.canSubmit(featureCanComplete: feature.canCompleteEditing)
    }

    private var doneAccessibilityHint: String {
        if editorComposition.hasMarkedText {
            return "Finish composing text before saving"
        }
        return feature.noteMutationAvailability.accessibilityHint
    }

    private var deleteConfirmationTransition: AnyTransition {
        guard !(reduceMotionOverride ?? reduceMotion) else { return .opacity }
        return .move(edge: .bottom).combined(with: .opacity)
    }

    var body: some View {
        ZStack {
            ZStack {
                WorkbenchScaffold(isEditing: feature.isEditing) {
                    WorkbenchHeader(
                        openNoteLibrary: openNoteLibrary,
                        openSettings: openSettings
                    )
                } noteSurface: {
                    WorkbenchNoteSurface(
                        source: feature.currentNote?.body ?? "",
                        editingText: feature.editingText,
                        isEditing: feature.isEditing,
                        canBeginEditing: feature.canBeginEditing,
                        beginEditingHint: feature.noteMutationAvailability.accessibilityHint,
                        progress: feature.characterProgress,
                        isCharacterCountExpanded: feature.isCharacterCountVisible,
                        didReachCharacterLimit: feature.didReachCharacterLimit,
                        feedbackIsPresented: feature.feedbackMessage != nil,
                        beginEditing: feature.beginEditing,
                        stageEditorText: stageEditorText,
                        markedTextDidChange: { markedTextActive in
                            editorComposition.textDidChange(
                                markedTextActive: markedTextActive
                            )
                        },
                        revealCharacterCount: feature.revealCharacterCount
                    )
                }

                if let feedback = feature.feedbackMessage,
                   feature.deleteConfirmation == nil {
                    HintMessageView(message: feedback)
                        .padding(.horizontal, IslandDesign.Spacing.x4)
                        .padding(.bottom, IslandDesign.Spacing.x2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .zIndex(2)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if feature.isEditing {
                    EditingCommitBar(
                        isEnabled: canCommitEditing,
                        accessibilityValue: editorComposition.hasMarkedText
                            ? "Waiting for text composition"
                            : "",
                        accessibilityHint: doneAccessibilityHint,
                        commit: commitEditing
                    )
                } else {
                    WorkbenchActionDock(
                        model: dockModel,
                        reduceMotionOverride: reduceMotionOverride,
                        move: moveCurrentNote,
                        toggleLive: toggleLive,
                        delete: feature.requestDelete
                    )
                }
            }
            .allowsHitTesting(feature.deleteConfirmation == nil)
            .accessibilityHidden(feature.deleteConfirmation != nil)

            if let deleteConfirmationMessage {
                ZStack(alignment: .bottom) {
                    IslandDesign.Colors.scrim
                        .contentShape(Rectangle())
                        .ignoresSafeArea()
                        .onTapGesture {}
                        .accessibilityHidden(true)

                    DeleteConfirmationView(
                        message: deleteConfirmationMessage,
                        feedback: feature.feedbackMessage,
                        isBusy: !feature.noteMutationAvailability.isEnabled,
                        cancel: feature.cancelDelete,
                        confirm: confirmDelete
                    )
                    .padding(.horizontal, IslandDesign.Spacing.x4)
                    .padding(.bottom, IslandDesign.Spacing.x4)
                }
                .transition(deleteConfirmationTransition)
                .zIndex(3)
            }
        }
        .animation(
            IslandDesign.Motion.animation(reduceMotion: reduceMotionOverride ?? reduceMotion),
            value: feature.deleteConfirmation != nil
        )
        .animation(
            IslandDesign.Motion.workbenchEditing(
                reduceMotion: reduceMotionOverride ?? reduceMotion
            ),
            value: feature.isEditing
        )
        .background(IslandDesign.Colors.workbenchCanvas.ignoresSafeArea())
        .navigationBarHidden(true)
        .onChange(of: feature.isEditing) { _, isEditing in
            editorComposition.editingDidChange(isEditing)
        }
    }

    private func stageEditorText(_ proposedText: String, _ markedTextActive: Bool) -> String {
        feature.stageEditorText(
            proposedText: proposedText,
            markedTextActive: markedTextActive
        ).acceptedText
    }

    private func commitEditing() {
        guard canCommitEditing else { return }
        try? feature.completeEditing()
    }

    private func moveCurrentNote() {
        Task { try? await feature.archiveCurrentNote() }
    }

    private func toggleLive() {
        guard liveTransition == nil else { return }
        let wasPinned = feature.pinState == .pinned
        liveTransition = wasPinned ? .stopping : .starting
        Task {
            if wasPinned {
                await feature.cancelPinning()
            } else {
                await feature.startPinning()
            }
            liveTransition = nil
        }
    }

    private func confirmDelete() {
        Task { try? await feature.confirmDeleteCurrentNote() }
    }

}

struct WorkbenchEditorCompositionState: Equatable {
    private(set) var hasMarkedText: Bool = false

    mutating func textDidChange(markedTextActive: Bool) {
        hasMarkedText = markedTextActive
    }

    mutating func editingDidChange(_ isEditing: Bool) {
        if !isEditing {
            hasMarkedText = false
        }
    }

    func canSubmit(featureCanComplete: Bool) -> Bool {
        featureCanComplete && !hasMarkedText
    }
}
