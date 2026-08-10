import SwiftUI

struct WorkbenchScaffold<Header: View, NoteSurface: View>: View {
    let isEditing: Bool
    @ViewBuilder let header: Header
    @ViewBuilder let noteSurface: NoteSurface

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        WorkbenchScaffoldLayout(isEditing: isEditing) {
            header
            noteSurface
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, IslandDesign.Spacing.x4)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("workbench-root")
    }

    private var horizontalPadding: CGFloat {
        dynamicTypeSize.isAccessibilitySize
            ? IslandDesign.Spacing.x4
            : IslandDesign.Spacing.x6
    }
}

private struct WorkbenchScaffoldLayout: Layout {
    let isEditing: Bool

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        proposal.replacingUnspecifiedDimensions(
            by: CGSize(width: 320, height: 640)
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        guard subviews.count == 2 else { return }

        let widthProposal = ProposedViewSize(width: bounds.width, height: nil)
        let headerSize = subviews[0].sizeThatFits(widthProposal)
        var headerGap = isEditing
            ? IslandDesign.Workbench.editingHeaderGap
            : IslandDesign.Workbench.headerGap
        var bottomGap = isEditing
            ? IslandDesign.Workbench.editingBottomGap
            : IslandDesign.Workbench.bottomGap
        let minimumHeaderGap = isEditing
            ? IslandDesign.Workbench.minimumEditingHeaderGap
            : IslandDesign.Workbench.minimumHeaderGap
        let minimumBottomGap = IslandDesign.Workbench.minimumBottomGap
        let minimumSurfaceHeight = isEditing
            ? IslandDesign.Workbench.minimumEditingSurfaceHeight
            : IslandDesign.Workbench.minimumSurfaceHeight

        let desiredMinimumHeight = headerSize.height
            + headerGap
            + minimumSurfaceHeight
            + bottomGap
        var deficit = max(0, desiredMinimumHeight - bounds.height)
        deficit = compress(
            &headerGap,
            toward: minimumHeaderGap,
            by: deficit
        )
        _ = compress(
            &bottomGap,
            toward: minimumBottomGap,
            by: deficit
        )

        let surfaceHeight = max(
            0,
            bounds.height - headerSize.height - headerGap - bottomGap
        )

        subviews[0].place(
            at: bounds.origin,
            anchor: .topLeading,
            proposal: ProposedViewSize(
                width: bounds.width,
                height: headerSize.height
            )
        )
        subviews[1].place(
            at: CGPoint(
                x: bounds.minX,
                y: bounds.minY + headerSize.height + headerGap
            ),
            anchor: .topLeading,
            proposal: ProposedViewSize(
                width: bounds.width,
                height: surfaceHeight
            )
        )
    }

    private func compress(
        _ value: inout CGFloat,
        toward minimum: CGFloat,
        by deficit: CGFloat
    ) -> CGFloat {
        let reduction = min(deficit, max(0, value - minimum))
        value -= reduction
        return deficit - reduction
    }
}
