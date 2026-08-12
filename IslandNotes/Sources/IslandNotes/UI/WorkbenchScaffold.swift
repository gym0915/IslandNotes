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
        let headerGap = isEditing
            ? IslandDesign.Workbench.editingHeaderGap
            : IslandDesign.Workbench.headerGap
        let bottomGap = isEditing
            ? IslandDesign.Workbench.editingBottomGap
            : IslandDesign.Workbench.bottomGap
        let availableSurfaceHeight = max(
            0,
            bounds.height - headerSize.height - headerGap - bottomGap
        )
        let screenCenterAdjustment = IslandDesign.Workbench.noteSurfaceCenterYOffset
        let preferredSurfaceHeight = bounds.width
            / IslandDesign.Workbench.noteSurfaceAspectRatio
        let surfaceWidth: CGFloat
        let surfaceHeight: CGFloat
        if isEditing {
            // Keep the editing surface at the Workbench content width. The
            // keyboard is allowed to reduce only its vertical extent.
            surfaceWidth = bounds.width
            surfaceHeight = min(preferredSurfaceHeight, availableSurfaceHeight)
        } else {
            // Display state remains a strict 3:4 surface, adapting its width
            // only when a smaller device cannot fit the full-height version.
            surfaceWidth = min(
                bounds.width,
                availableSurfaceHeight * IslandDesign.Workbench.noteSurfaceAspectRatio
            )
            surfaceHeight = surfaceWidth / IslandDesign.Workbench.noteSurfaceAspectRatio
        }
        let surfaceMinY = bounds.minY
            + headerSize.height
            + headerGap
            + screenCenterAdjustment
        let surfaceMaxY = bounds.maxY - bottomGap - surfaceHeight
        let centeredSurfaceMinY = bounds.midY
            - (surfaceHeight / 2)
            + screenCenterAdjustment
        let clampedSurfaceMinY = min(
            max(centeredSurfaceMinY, surfaceMinY),
            surfaceMaxY
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
                x: bounds.midX,
                y: clampedSurfaceMinY + (surfaceHeight / 2)
            ),
            anchor: .center,
            proposal: ProposedViewSize(
                width: surfaceWidth,
                height: surfaceHeight
            )
        )
    }
}
