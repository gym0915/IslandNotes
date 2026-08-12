import SwiftUI

struct WorkbenchHeader: View {
    let openNoteLibrary: () -> Void
    let openSettings: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: IslandDesign.Spacing.x2) {
                Color.clear
                    .frame(
                        width: IslandDesign.Sizing.headerActionTarget,
                        height: IslandDesign.Sizing.headerActionTarget
                    )
                    .accessibilityHidden(true)
                Spacer(minLength: IslandDesign.Spacing.x2)
                title
                    .fixedSize(horizontal: true, vertical: false)
                Spacer(minLength: IslandDesign.Spacing.x2)
                moreButton
            }

            HStack(spacing: IslandDesign.Spacing.x2) {
                title
                Spacer(minLength: IslandDesign.Spacing.x2)
                moreButton
            }
        }
        .frame(minHeight: IslandDesign.Sizing.headerActionTarget)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("workbench-header")
    }

    private var title: some View {
        Text("Island Notes")
            .font(IslandDesign.Typography.workbenchTitle)
            .foregroundStyle(IslandDesign.Colors.primaryText)
            .lineLimit(1)
    }

    private var moreButton: some View {
        MoreMenu(
            openNoteLibrary: openNoteLibrary,
            openSettings: openSettings
        )
            .frame(
                width: IslandDesign.Sizing.headerActionTarget,
                height: IslandDesign.Sizing.headerActionTarget
            )
    }
}

#Preview("Workbench Header · Light") {
    WorkbenchHeader(openNoteLibrary: {}, openSettings: {})
        .padding(IslandDesign.Spacing.x6)
        .background(IslandDesign.Colors.workbenchCanvas)
        .preferredColorScheme(.light)
}

#Preview("Workbench Header · Dark") {
    WorkbenchHeader(openNoteLibrary: {}, openSettings: {})
        .padding(IslandDesign.Spacing.x6)
        .background(IslandDesign.Colors.workbenchCanvas)
        .preferredColorScheme(.dark)
}
