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
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: IslandNoteActivityAttributes.self) { context in
            let presentation = LiveActivityPresentationModel.presentation(
                for: .lockScreen,
                state: context.state
            )

            LiveActivityNoteView(
                presentation: presentation,
                surface: .lockScreen
            )
            .activityBackgroundTint(.clear)
            .activitySystemActionForegroundColor(.primary)
            .widgetURL(presentation.destination)
        } dynamicIsland: { context in
            let presentation = LiveActivityPresentationModel.presentation(
                for: .expanded,
                state: context.state
            )

            return DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    LiveActivityNoteView(
                        presentation: presentation,
                        surface: .expandedIsland
                    )
                }
            } compactLeading: {
                brandMark(for: .compactLeading, state: context.state)
            } compactTrailing: {
                EmptyView()
            } minimal: {
                brandMark(for: .minimal, state: context.state)
            }
            .keylineTint(.white)
            .widgetURL(presentation.destination)
        }
    }

    @ViewBuilder
    private func brandMark(
        for region: LiveActivityRegion,
        state: IslandNoteActivityAttributes.ContentState
    ) -> some View {
        let presentation = LiveActivityPresentationModel.presentation(for: region, state: state)

        if presentation.brandMark == .notebookText {
            LiveActivityBrandMarkView(size: LiveActivityDesign.compactBrandMarkSize)
                .foregroundStyle(.white)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(presentation.accessibilityLabel ?? "Island Notes")
        }
    }
}

#if DEBUG
private extension IslandNoteActivityAttributes {
    static let preview = IslandNoteActivityAttributes(
        noteID: UUID(uuidString: "D82B5CC2-2E3E-4DCC-8E47-69208949813D")!
    )
}

private extension IslandNoteActivityAttributes.ContentState {
    static let previewPlain = Self(
        body: "Review the product brief",
        version: 1
    )
    static let previewBullets = Self(
        body: "Review the product brief\n- Send the build notes to Maya\n- Book the 4:30 train",
        version: 2
    )
    static let previewMultiline = Self(
        body: "First line\nSecond line stays visible\nThird line\nFourth line is truncated",
        version: 3
    )
    static let previewEmoji = Self(
        body: "Depart 🧭🌿👨‍👩‍👧‍👦\n- Bring the build notes",
        version: 4
    )
}

#Preview("Lock Screen · Content Matrix", as: .content, using: IslandNoteActivityAttributes.preview) {
    IslandNotesLiveActivityWidget()
} contentStates: {
    IslandNoteActivityAttributes.ContentState.previewPlain
    IslandNoteActivityAttributes.ContentState.previewBullets
    IslandNoteActivityAttributes.ContentState.previewMultiline
    IslandNoteActivityAttributes.ContentState.previewEmoji
}

#Preview("Dynamic Island · Compact", as: .dynamicIsland(.compact), using: IslandNoteActivityAttributes.preview) {
    IslandNotesLiveActivityWidget()
} contentStates: {
    IslandNoteActivityAttributes.ContentState.previewPlain
    IslandNoteActivityAttributes.ContentState.previewBullets
    IslandNoteActivityAttributes.ContentState.previewMultiline
    IslandNoteActivityAttributes.ContentState.previewEmoji
}

#Preview("Dynamic Island · Minimal", as: .dynamicIsland(.minimal), using: IslandNoteActivityAttributes.preview) {
    IslandNotesLiveActivityWidget()
} contentStates: {
    IslandNoteActivityAttributes.ContentState.previewPlain
    IslandNoteActivityAttributes.ContentState.previewBullets
    IslandNoteActivityAttributes.ContentState.previewMultiline
    IslandNoteActivityAttributes.ContentState.previewEmoji
}

#Preview("Dynamic Island · Expanded", as: .dynamicIsland(.expanded), using: IslandNoteActivityAttributes.preview) {
    IslandNotesLiveActivityWidget()
} contentStates: {
    IslandNoteActivityAttributes.ContentState.previewPlain
    IslandNoteActivityAttributes.ContentState.previewBullets
    IslandNoteActivityAttributes.ContentState.previewMultiline
    IslandNoteActivityAttributes.ContentState.previewEmoji
}
#endif
