import SwiftUI

struct WorkbenchView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var feature: IslandNotesFeature
    @State private var isMoreMenuPresented = false
    var reduceMotionOverride: Bool? = nil
    let openNoteLibrary: () -> Void
    let openSettings: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: IslandDesign.Spacing.x6) {
                    header
                    noteSurface
                    if let feedback = feature.feedbackMessage,
                       feature.deleteConfirmation == nil {
                        HintMessageView(message: feedback)
                    }
                    ActionDock(feature: feature)
                }
                .padding(.horizontal, IslandDesign.Spacing.x6)
                .padding(.top, IslandDesign.Spacing.x4)
                .padding(.bottom, IslandDesign.Spacing.x8)
            }
            .scrollDismissesKeyboard(.interactively)
            .allowsHitTesting(feature.deleteConfirmation == nil)
            .accessibilityHidden(feature.deleteConfirmation != nil)
            .accessibilityIdentifier("workbench-root")

            if isMoreMenuPresented {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture { dismissMoreMenu() }
                    .accessibilityHidden(true)

                MoreMenu(
                    openNoteLibrary: {
                        dismissMoreMenu()
                        openNoteLibrary()
                    },
                    openSettings: {
                        dismissMoreMenu()
                        openSettings()
                    }
                )
                .padding(.top, IslandDesign.Sizing.menuTopOffset)
                .padding(.trailing, IslandDesign.Spacing.x6)
                .transition(
                    .opacity.combined(
                        with: .scale(
                            scale: IslandDesign.Motion.menuScale,
                            anchor: .topTrailing
                        )
                    )
                )
                .zIndex(1)
            }

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
                        cancel: feature.cancelDelete
                    ) {
                        Task { try? await feature.confirmDeleteCurrentNote() }
                    }
                    .padding(.horizontal, IslandDesign.Spacing.x4)
                    .padding(.bottom, IslandDesign.Spacing.x4)
                }
                .transition(deleteConfirmationTransition)
                .zIndex(2)
            }
        }
        .animation(
            IslandDesign.Motion.menu(reduceMotion: reduceMotionOverride ?? reduceMotion),
            value: isMoreMenuPresented
        )
        .animation(
            IslandDesign.Motion.animation(reduceMotion: reduceMotionOverride ?? reduceMotion),
            value: feature.deleteConfirmation != nil
        )
        .background(IslandDesign.Colors.canvas)
        .navigationBarHidden(true)
    }

    private var deleteConfirmationMessage: String? {
        guard case let .pending(message)? = feature.deleteConfirmation else { return nil }
        return message
    }

    private var deleteConfirmationTransition: AnyTransition {
        guard !(reduceMotionOverride ?? reduceMotion) else { return .opacity }
        return .move(edge: .bottom).combined(with: .opacity)
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: IslandDesign.Spacing.x2) {
                Spacer()
                    .frame(width: IslandDesign.Sizing.minimumTouchTarget)
                    .accessibilityHidden(true)
                Spacer(minLength: IslandDesign.Spacing.x2)
                headerIdentity
                    .fixedSize(horizontal: true, vertical: false)
                Spacer(minLength: IslandDesign.Spacing.x2)
                moreButton
            }

            HStack {
                headerIdentity
                Spacer(minLength: IslandDesign.Spacing.x2)
                moreButton
            }
        }
        .frame(minHeight: IslandDesign.Sizing.minimumTouchTarget)
    }

    private var headerIdentity: some View {
        VStack(spacing: IslandDesign.Spacing.x1) {
            Text("Island Notes")
                .font(IslandDesign.Typography.screenTitle)
                .foregroundStyle(IslandDesign.Colors.primaryText)
            HStack(spacing: IslandDesign.Spacing.x2) {
                AppIconView(icon: .live, size: IslandDesign.Sizing.smallIcon)
                    .foregroundStyle(
                        feature.pinState == .pinned
                            ? IslandDesign.Colors.live
                            : IslandDesign.Colors.secondaryText
                    )
                Text(feature.pinState == .pinned ? "Live" : "Not Live")
                    .font(IslandDesign.Typography.caption)
                    .foregroundStyle(IslandDesign.Colors.secondaryText)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(feature.pinState == .pinned ? "Live" : "Not Live")
        }
    }

    private var moreButton: some View {
        IslandIconButton(icon: .more, label: "More") {
            isMoreMenuPresented.toggle()
        }
        .accessibilityIdentifier("open-more-menu")
        .accessibilityValue(isMoreMenuPresented ? "Expanded" : "Collapsed")
    }

    private func dismissMoreMenu() {
        isMoreMenuPresented = false
    }

    private var noteSurface: some View {
        IslandSurface(elevation: .card, radius: IslandDesign.Radius.card) {
            VStack(alignment: .trailing, spacing: IslandDesign.Spacing.x2) {
                if feature.isEditing {
                    ZStack(alignment: .topLeading) {
                        if feature.editingText.isEmpty {
                            Text("Write what matters most…")
                                .font(IslandDesign.Typography.editor)
                                .foregroundStyle(IslandDesign.Colors.placeholder)
                                .padding(.top, IslandDesign.Spacing.x1)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                        MarkedTextEditor(text: feature.editingText) {
                            proposedText,
                            markedTextActive in
                            feature.stageEditorText(
                                proposedText: proposedText,
                                markedTextActive: markedTextActive
                            ).acceptedText
                        }
                        .frame(minHeight: IslandDesign.Sizing.editorMinimumHeight)
                    }
                } else {
                    Button(action: feature.beginEditing) {
                        RenderedNoteView(source: feature.currentNote?.body ?? "")
                            .frame(
                                maxWidth: .infinity,
                                minHeight: IslandDesign.Sizing.editorMinimumHeight,
                                alignment: .topLeading
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!feature.canBeginEditing)
                    .accessibilityIdentifier("rendered-note")
                    .accessibilityHint(
                        feature.canBeginEditing
                            ? "Edit the current note source"
                            : feature.noteMutationAvailability.accessibilityHint
                    )
                }

                HStack(spacing: IslandDesign.Spacing.x2) {
                    if feature.isEditing {
                        Button("Done") {
                            try? feature.completeEditing()
                        }
                        .buttonStyle(IslandButtonStyle(kind: .primary))
                        .disabled(!feature.canCompleteEditing)
                        .accessibilityIdentifier("done-editing")
                        .accessibilityHint(feature.noteMutationAvailability.accessibilityHint)
                    }

                    Spacer(minLength: IslandDesign.Spacing.x2)

                    CharacterProgressView(
                        progress: feature.characterProgress,
                        isExpanded: feature.isCharacterCountVisible,
                        didReachLimit: feature.didReachCharacterLimit,
                        reveal: feature.revealCharacterCount
                    )
                }
            }
            .padding(IslandDesign.Spacing.x6)
        }
    }
}
