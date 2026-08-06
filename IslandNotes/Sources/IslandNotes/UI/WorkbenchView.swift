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
                    editorPaper
                    if let feedback = feature.feedbackMessage {
                        Text(feedback)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(IslandDesign.Colors.secondaryText)
                            .accessibilityIdentifier("transient-feedback")
                    }
                    ActionDock(feature: feature)
                }
                .padding(.horizontal, IslandDesign.Spacing.x6)
                .padding(.top, IslandDesign.Spacing.x2)
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
                .padding(.top, 64)
                .padding(.trailing, IslandDesign.Spacing.x6)
                .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .topTrailing)))
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
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: IslandDesign.Spacing.x1) {
                Text("Island Notes")
                    .font(IslandDesign.Typography.productName)
                HStack(spacing: IslandDesign.Spacing.x2) {
                    Circle()
                        .fill(
                            feature.pinState == .pinned
                                ? IslandDesign.Colors.live
                                : IslandDesign.Colors.secondaryText.opacity(0.35)
                        )
                        .frame(width: 7, height: 7)
                        .scaleEffect(
                            feature.pinState == .pinned
                                && !(reduceMotionOverride ?? reduceMotion) ? 1.08 : 1
                        )
                    Text(feature.pinState == .pinned ? "Live" : "Not Live")
                        .font(IslandDesign.Typography.caption)
                        .foregroundStyle(IslandDesign.Colors.secondaryText)
                }
                .accessibilityElement(children: .combine)
            }
            Spacer()
            Button {
                isMoreMenuPresented.toggle()
            } label: {
                AppIconView(icon: .more)
                    .frame(
                        width: IslandDesign.Sizing.minimumTouchTarget,
                        height: IslandDesign.Sizing.minimumTouchTarget
                    )
                    .background(IslandDesign.Materials.control, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("open-more-menu")
            .accessibilityLabel("More")
            .accessibilityValue(isMoreMenuPresented ? "Expanded" : "Collapsed")
        }
    }

    private func dismissMoreMenu() {
        isMoreMenuPresented = false
    }

    private var editorPaper: some View {
        VStack(alignment: .trailing, spacing: IslandDesign.Spacing.x2) {
            ZStack(alignment: .topLeading) {
                if feature.editingText.isEmpty {
                    Text("Write what matters most…")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, IslandDesign.Spacing.x1)
                        .allowsHitTesting(false)
                }
                MarkedTextEditor(text: feature.editingText) { proposedText, markedTextActive in
                    let staged = feature.stageEditorText(
                        proposedText: proposedText,
                        markedTextActive: markedTextActive
                    )
                    guard !markedTextActive else { return }
                    Task {
                        try? feature.persistStagedEditorText(staged.acceptedText)
                    }
                }
                .frame(minHeight: 310)
            }

            CharacterProgressView(
                progress: feature.characterProgress,
                isExpanded: feature.isCharacterCountVisible,
                didReachLimit: feature.didReachCharacterLimit,
                reveal: feature.revealCharacterCount
            )
        }
        .padding(IslandDesign.Spacing.x6)
        .background(IslandDesign.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: IslandDesign.Radius.sheet, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: IslandDesign.Radius.sheet, style: .continuous)
                .stroke(IslandDesign.Colors.separator.opacity(0.5), lineWidth: 1)
        }
        .shadow(
            color: IslandDesign.Elevation.card.color,
            radius: IslandDesign.Elevation.card.radius,
            x: IslandDesign.Elevation.card.x,
            y: IslandDesign.Elevation.card.y
        )
    }
}
