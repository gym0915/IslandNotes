import SwiftUI

struct WorkbenchView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var feature: IslandNotesFeature
    var reduceMotionOverride: Bool? = nil
    let openLibrary: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                editorPaper
                if let feedback = feature.feedbackMessage {
                    Label(feedback, systemImage: "exclamationmark.circle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("transient-feedback")
                }
                ActionDock(feature: feature)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .accessibilityIdentifier("workbench-root")
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationBarHidden(true)
        .alert(
            "删除当前便签？",
            isPresented: Binding(
                get: { feature.deleteConfirmation != nil },
                set: { if !$0 { feature.cancelDelete() } }
            )
        ) {
            Button("取消", role: .cancel) { feature.cancelDelete() }
            Button("删除", role: .destructive) {
                Task { try? await feature.confirmDeleteCurrentNote() }
            }
        } message: {
            Text("删除后无法恢复")
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("灵动岛便签")
                    .font(.largeTitle.bold())
                HStack(spacing: 6) {
                    Circle()
                        .fill(feature.pinState == .pinned ? Color(red: 0.48, green: 0.66, blue: 0.50) : .secondary.opacity(0.35))
                        .frame(width: 7, height: 7)
                        .scaleEffect(
                            feature.pinState == .pinned
                                && !(reduceMotionOverride ?? reduceMotion) ? 1.08 : 1
                        )
                    Text(feature.pinState == .pinned ? "挂起中" : "未挂起")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
            Spacer()
            Button(action: openLibrary) {
                Image(systemName: "tray.full")
                    .font(.title3.weight(.semibold))
                    .frame(width: 46, height: 46)
                    .background(.thinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("open-library")
            .accessibilityLabel("打开便签库")
            .accessibilityHint("查看并取回以前的便签")
        }
    }

    private var editorPaper: some View {
        VStack(alignment: .trailing, spacing: 10) {
            ZStack(alignment: .topLeading) {
                if feature.editingText.isEmpty {
                    Text("写下此刻最重要的一句话…")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 5)
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
        .padding(22)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.primary.opacity(0.04), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.05), radius: 22, y: 10)
    }
}
