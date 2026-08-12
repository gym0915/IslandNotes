import SwiftUI
import UIKit

struct WorkbenchNoteSurface: View {
    let source: String
    let editingText: String
    let isEditing: Bool
    let canBeginEditing: Bool
    let beginEditingHint: String
    let progress: CharacterProgress
    let isCharacterCountExpanded: Bool
    let didReachCharacterLimit: Bool
    let feedbackIsPresented: Bool
    let beginEditing: () -> Void
    let stageEditorText: (String, Bool) -> String
    let markedTextDidChange: (Bool) -> Void
    let revealCharacterCount: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        IslandSurface(
            elevation: .card,
            radius: IslandDesign.Radius.sheet,
            background: IslandDesign.Colors.workbenchSurface
        ) {
            ZStack(alignment: .bottomTrailing) {
                if isEditing {
                    editor
                } else {
                    renderedNote
                }

                if isEditing {
                    CharacterProgressView(
                        progress: progress,
                        isExpanded: isCharacterCountExpanded,
                        didReachLimit: didReachCharacterLimit,
                        reveal: revealCharacterCount
                    )
                    .padding(.bottom, feedbackAvoidance)
                } else {
                    Color.clear
                        .frame(
                            width: IslandDesign.Sizing.minimumTouchTarget,
                            height: IslandDesign.Sizing.minimumTouchTarget
                        )
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .padding(surfacePadding)
        }
        .overlay {
            RoundedRectangle(
                cornerRadius: IslandDesign.Radius.sheet,
                style: .continuous
            )
            .strokeBorder(
                IslandDesign.Colors.workbenchSurfaceBorder,
                lineWidth: IslandDesign.Sizing.hairline
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("workbench-note-surface")
    }

    private var surfacePadding: CGFloat {
        dynamicTypeSize.isAccessibilitySize
            ? IslandDesign.Spacing.x4
            : IslandDesign.Spacing.x6
    }

    private var progressTrailingSpace: CGFloat {
        guard isEditing else { return 0 }
        return max(
            IslandDesign.Sizing.minimumTouchTarget,
            IslandDesign.Sizing.characterRing
        ) + IslandDesign.Spacing.x2
    }

    private var progressBottomSpace: CGFloat {
        guard isEditing else { return 0 }
        let accessoryHeight = isCharacterCountExpanded && dynamicTypeSize.isAccessibilitySize
            ? IslandDesign.Sizing.expandedCharacterAccessoryHeight
            : progressTrailingSpace
        return accessoryHeight + feedbackAvoidance
    }

    private var feedbackAvoidance: CGFloat {
        guard feedbackIsPresented else { return 0 }
        return dynamicTypeSize.isAccessibilitySize
            ? IslandDesign.Workbench.accessibilityFeedbackAvoidance
            : IslandDesign.Workbench.feedbackAvoidance
    }

    private var editorInsets: UIEdgeInsets {
        UIEdgeInsets(
            top: IslandDesign.Spacing.x1,
            left: 0,
            bottom: progressBottomSpace,
            right: progressTrailingSpace
        )
    }

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            if editingText.isEmpty {
                Text("Write what matters most…")
                    .font(IslandDesign.Typography.editor)
                    .foregroundStyle(IslandDesign.Colors.placeholder)
                    .padding(.top, IslandDesign.Spacing.x1)
                    .allowsHitTesting(false)
                    .accessibilityLabel("")
                    .accessibilityHidden(true)
            }

            MarkedTextEditor(
                text: editingText,
                textContainerInset: editorInsets,
                onChange: stageEditorText,
                onMarkedTextChange: markedTextDidChange
            )
        }
    }

    private var renderedNote: some View {
        ScrollView {
            RenderedNoteView(source: source)
                .padding(.trailing, progressTrailingSpace)
                .padding(.bottom, progressBottomSpace)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: beginEditingIfAvailable)
        .disabled(!canBeginEditing)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction {
            beginEditingIfAvailable()
        }
        .accessibilityIdentifier("rendered-note")
        .accessibilityLabel(renderedNoteAccessibilityLabel)
        .accessibilityHint(
            canBeginEditing ? "Edit the current note source" : beginEditingHint
        )
    }

    private var renderedNoteAccessibilityLabel: String {
        source.isEmpty
            ? "Add something you want to keep close, then go live on Dynamic Island."
            : source
    }

    private func beginEditingIfAvailable() {
        guard canBeginEditing else { return }
        beginEditing()
    }
}
