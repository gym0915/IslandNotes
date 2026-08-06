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
                            .font(IslandDesign.Typography.feedback)
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
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: IslandDesign.Spacing.x1) {
                Text("Island Notes")
                    .font(IslandDesign.Typography.productName)
                HStack(spacing: IslandDesign.Spacing.x2) {
                    Circle()
                        .fill(
                            feature.pinState == .pinned
                                ? IslandDesign.Colors.live
                                : IslandDesign.Colors.notLive
                        )
                        .frame(
                            width: IslandDesign.Sizing.statusDot,
                            height: IslandDesign.Sizing.statusDot
                        )
                        .scaleEffect(
                            feature.pinState == .pinned
                                && !(reduceMotionOverride ?? reduceMotion)
                                ? IslandDesign.Motion.livePulseScale
                                : 1
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
            if feature.isEditing {
                ZStack(alignment: .topLeading) {
                    if feature.editingText.isEmpty {
                        Text("Write what matters most…")
                            .font(IslandDesign.Typography.editor)
                            .foregroundStyle(IslandDesign.Colors.placeholder)
                            .padding(.top, IslandDesign.Spacing.x1)
                            .allowsHitTesting(false)
                    }
                    MarkedTextEditor(text: feature.editingText) { proposedText, markedTextActive in
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
                .accessibilityIdentifier("rendered-note")
                .accessibilityHint("Edit the current note source")
            }

            HStack(spacing: IslandDesign.Spacing.x2) {
                if feature.isEditing {
                    Button("Done") {
                        try? feature.completeEditing()
                    }
                    .font(IslandDesign.Typography.action)
                    .buttonStyle(.borderedProminent)
                    .tint(IslandDesign.Colors.primaryText)
                    .accessibilityIdentifier("done-editing")
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
        .background(IslandDesign.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: IslandDesign.Radius.sheet, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: IslandDesign.Radius.sheet, style: .continuous)
                .stroke(
                    IslandDesign.Colors.surfaceBorder,
                    lineWidth: IslandDesign.Sizing.hairline
                )
        }
        .shadow(
            color: IslandDesign.Elevation.card.color,
            radius: IslandDesign.Elevation.card.radius,
            x: IslandDesign.Elevation.card.x,
            y: IslandDesign.Elevation.card.y
        )
    }
}

private struct RenderedNoteView: View {
    let source: String

    var body: some View {
        if source.isEmpty {
            Text("Write what matters most…")
                .font(IslandDesign.Typography.editor)
                .foregroundStyle(IslandDesign.Colors.placeholder)
        } else {
            VStack(alignment: .leading, spacing: IslandDesign.Spacing.x2) {
                ForEach(Array(RenderedNoteContent.lines(from: source).enumerated()), id: \.offset) {
                    offset,
                    line in
                    switch line {
                    case let .text(text):
                        Text(text.isEmpty ? " " : text)
                            .accessibilityLabel(text.isEmpty ? "Blank line" : text)
                    case let .bullet(text):
                        HStack(alignment: .firstTextBaseline, spacing: IslandDesign.Spacing.x2) {
                            Circle()
                                .fill(IslandDesign.Colors.primaryText)
                                .frame(width: 5, height: 5)
                                .accessibilityHidden(true)
                            Text(text.isEmpty ? " " : text)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel(text.isEmpty ? "Empty bullet" : "Bullet, \(text)")
                        .accessibilityIdentifier("rendered-bullet-\(offset)")
                    }
                }
            }
            .font(IslandDesign.Typography.editor)
            .foregroundStyle(IslandDesign.Colors.primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
