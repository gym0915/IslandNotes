import ActivityKit
import SwiftUI
import WidgetKit

@main
struct IslandNotesWidgetBundle: WidgetBundle {
    var body: some Widget {
        IslandNotesLiveActivityWidget()
    }
}

struct IslandNotesLiveActivityWidget: Widget {
    private let accent = Color(red: 0.36, green: 0.52, blue: 0.40)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: IslandNoteActivityAttributes.self) { context in
            LockScreenNoteView(state: context.state)
                .activityBackgroundTint(Color(uiColor: .secondarySystemBackground))
                .activitySystemActionForegroundColor(.primary)
                .widgetURL(LiveActivityPresentationModel.workbenchURL)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("已固定", systemImage: "pin.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(accent)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text("便签")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                DynamicIslandExpandedRegion(.center) {
                    RenderedActivityNoteView(source: context.state.body)
                        .font(.callout)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(accent)
                            .frame(width: 6, height: 6)
                        Text("轻点返回工作台")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Image(systemName: "pin.fill")
                    .foregroundStyle(accent)
                    .accessibilityLabel("便签已固定")
            } compactTrailing: {
                Circle()
                    .fill(accent)
                    .frame(width: 7, height: 7)
                    .accessibilityLabel("固定中")
            } minimal: {
                Image(systemName: "note.text")
                    .foregroundStyle(accent)
                    .accessibilityLabel("固定便签")
            }
            .keylineTint(accent)
            .widgetURL(LiveActivityPresentationModel.workbenchURL)
        }
    }
}

private struct LockScreenNoteView: View {
    let state: IslandNoteActivityAttributes.ContentState

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "pin.fill")
                .font(.callout.weight(.semibold))
                .foregroundStyle(Color(red: 0.36, green: 0.52, blue: 0.40))
                .padding(9)
                .background(.primary.opacity(0.07), in: Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text("固定便签")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                RenderedActivityNoteView(source: state.body)
                    .font(.body)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .accessibilityElement(children: .combine)
    }
}

private struct RenderedActivityNoteView: View {
    let source: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(RenderedNoteContent.lines(from: source).enumerated()), id: \.offset) {
                _,
                line in
                switch line {
                case let .text(text):
                    Text(text.isEmpty ? " " : text)
                case let .bullet(text):
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("•")
                            .accessibilityHidden(true)
                        Text(text.isEmpty ? " " : text)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(text.isEmpty ? "Empty bullet" : "Bullet, \(text)")
                }
            }
        }
        .multilineTextAlignment(.leading)
    }
}

#if DEBUG
private extension IslandNoteActivityAttributes {
    static let preview = IslandNoteActivityAttributes(
        noteID: UUID(uuidString: "D82B5CC2-2E3E-4DCC-8E47-69208949813D")!
    )
}

private extension IslandNoteActivityAttributes.ContentState {
    static let previewShort = Self(body: "记得拿钥匙。", version: 1)
    static let previewLong = Self(
        body: "这是一条用来检查系统截断、动态字体和较窄设备宽度的长便签；展示不承诺包含全部正文。",
        version: 2
    )
    static let previewMultiline = Self(body: "First line\n第二行仍然保留\n第三行", version: 3)
    static let previewEmoji = Self(body: "出发 🧭🌿👨‍👩‍👧‍👦", version: 4)
}

#Preview("锁屏 · 文本矩阵", as: .content, using: IslandNoteActivityAttributes.preview) {
    IslandNotesLiveActivityWidget()
} contentStates: {
    IslandNoteActivityAttributes.ContentState.previewShort
    IslandNoteActivityAttributes.ContentState.previewLong
    IslandNoteActivityAttributes.ContentState.previewMultiline
    IslandNoteActivityAttributes.ContentState.previewEmoji
}

#Preview("灵动岛 · 紧凑态", as: .dynamicIsland(.compact), using: IslandNoteActivityAttributes.preview) {
    IslandNotesLiveActivityWidget()
} contentStates: {
    IslandNoteActivityAttributes.ContentState.previewShort
    IslandNoteActivityAttributes.ContentState.previewLong
    IslandNoteActivityAttributes.ContentState.previewMultiline
    IslandNoteActivityAttributes.ContentState.previewEmoji
}

#Preview("灵动岛 · Minimal", as: .dynamicIsland(.minimal), using: IslandNoteActivityAttributes.preview) {
    IslandNotesLiveActivityWidget()
} contentStates: {
    IslandNoteActivityAttributes.ContentState.previewShort
    IslandNoteActivityAttributes.ContentState.previewLong
    IslandNoteActivityAttributes.ContentState.previewMultiline
    IslandNoteActivityAttributes.ContentState.previewEmoji
}

#Preview("灵动岛 · 展开态", as: .dynamicIsland(.expanded), using: IslandNoteActivityAttributes.preview) {
    IslandNotesLiveActivityWidget()
} contentStates: {
    IslandNoteActivityAttributes.ContentState.previewShort
    IslandNoteActivityAttributes.ContentState.previewLong
    IslandNoteActivityAttributes.ContentState.previewMultiline
    IslandNoteActivityAttributes.ContentState.previewEmoji
}
#endif
