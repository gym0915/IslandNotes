import SwiftUI

enum IslandSurfaceElevation: CaseIterable, Sendable {
    case control
    case card
    case menu

    fileprivate var shadow: IslandDesign.Elevation.Shadow {
        switch self {
        case .control: IslandDesign.Elevation.control
        case .card: IslandDesign.Elevation.card
        case .menu: IslandDesign.Elevation.menu
        }
    }

    fileprivate var background: AnyShapeStyle {
        switch self {
        case .control: AnyShapeStyle(IslandDesign.Materials.control)
        case .card: AnyShapeStyle(IslandDesign.Colors.surface)
        case .menu: AnyShapeStyle(IslandDesign.Materials.menu)
        }
    }

    fileprivate var border: Color? {
        switch self {
        case .control: IslandDesign.Colors.surfaceBorder
        case .card: nil
        case .menu: IslandDesign.Colors.menuBorder
        }
    }
}

struct IslandSurface<Content: View>: View {
    let elevation: IslandSurfaceElevation
    let radius: CGFloat
    private let content: Content

    init(
        elevation: IslandSurfaceElevation = .card,
        radius: CGFloat = IslandDesign.Radius.card,
        @ViewBuilder content: () -> Content
    ) {
        self.elevation = elevation
        self.radius = radius
        self.content = content()
    }

    var body: some View {
        content
            .background(elevation.background)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                if let border = elevation.border {
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .stroke(border, lineWidth: IslandDesign.Sizing.hairline)
                }
            }
            .shadow(
                color: elevation.shadow.color,
                radius: elevation.shadow.radius,
                x: elevation.shadow.x,
                y: elevation.shadow.y
            )
    }
}

private struct IslandSurfacePreviewGallery: View {
    var body: some View {
        VStack(spacing: IslandDesign.Spacing.x6) {
            ForEach(IslandSurfaceElevation.allCases, id: \.self) { elevation in
                IslandSurface(elevation: elevation) {
                    Text(String(describing: elevation).capitalized)
                        .font(IslandDesign.Typography.body)
                        .foregroundStyle(IslandDesign.Colors.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(IslandDesign.Spacing.x4)
                }
            }
        }
        .padding(IslandDesign.Spacing.x8)
        .background(IslandDesign.Colors.canvas)
    }
}

#Preview("Surface elevations · Light") {
    IslandSurfacePreviewGallery()
        .preferredColorScheme(.light)
}

#Preview("Surface elevations · Dark") {
    IslandSurfacePreviewGallery()
        .preferredColorScheme(.dark)
}
