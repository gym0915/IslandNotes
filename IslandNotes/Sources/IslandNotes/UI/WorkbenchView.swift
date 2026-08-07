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
                    if let feedback = feature.feedbackMessage {
                        HintMessageView(message: feedback)
                    }
                    ActionDock(feature: feature)
                }
                .padding(.horizontal, IslandDesign.Spacing.x6)
                .padding(.top, IslandDesign.Spacing.x4)
                .padding(.bottom, IslandDesign.Spacing.x8)
            }
            .scrollDismissesKeyboard(.interactively)
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
        }
        .animation(
            IslandDesign.Motion.menu(reduceMotion: reduceMotionOverride ?? reduceMotion),
            value: isMoreMenuPresented
        )
        .background(IslandDesign.Colors.canvas)
        .navigationBarHidden(true)
        .alert(
            "Delete this note?",
            isPresented: Binding(
                get: { feature.deleteConfirmation != nil },
                set: { if !$0 { feature.cancelDelete() } }
            )
        ) {
            Button("Cancel", role: .cancel) { feature.cancelDelete() }
            Button("Delete Note", role: .destructive) {
                Task { try? await feature.confirmDeleteCurrentNote() }
            }
        } message: {
            Text("This cannot be undone.")
        }
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
