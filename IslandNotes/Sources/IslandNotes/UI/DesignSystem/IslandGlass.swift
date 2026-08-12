import SwiftUI

enum IslandGlassShape: Equatable, Sendable {
    case circle
    case capsule
    case roundedRectangle(CGFloat)
}

struct IslandGlassEffectGroup<Content: View>: View {
    let spacing: CGFloat?
    private let content: Content

    init(
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.content = content()
    }

    @ViewBuilder
    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
    }
}

private struct IslandInteractiveGlassModifier: ViewModifier {
    let shape: IslandGlassShape
    let tint: Color?
    let fallbackFill: AnyShapeStyle
    let fallbackBorder: Color
    let fallbackBorderWidth: CGFloat

    @Environment(\.isEnabled) private var isEnabled

    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            glass(content)
        } else {
            fallback(content)
        }
    }

    @available(iOS 26.0, *)
    @ViewBuilder
    private func glass(_ content: Content) -> some View {
        let glass = Glass.regular
            .tint(tint)
            .interactive(isEnabled)

        switch shape {
        case .circle:
            content.glassEffect(glass, in: Circle())
        case .capsule:
            content.glassEffect(glass, in: Capsule())
        case let .roundedRectangle(radius):
            content.glassEffect(
                glass,
                in: RoundedRectangle(cornerRadius: radius, style: .continuous)
            )
        }
    }

    @ViewBuilder
    private func fallback(_ content: Content) -> some View {
        switch shape {
        case .circle:
            content
                .background(fallbackFill, in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(fallbackBorder, lineWidth: fallbackBorderWidth)
                }
        case .capsule:
            content
                .background(fallbackFill, in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(fallbackBorder, lineWidth: fallbackBorderWidth)
                }
        case let .roundedRectangle(radius):
            let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
            content
                .background(fallbackFill, in: shape)
                .overlay {
                    shape.strokeBorder(fallbackBorder, lineWidth: fallbackBorderWidth)
                }
        }
    }
}

extension View {
    func islandInteractiveGlass(
        shape: IslandGlassShape,
        tint: Color? = nil,
        fallbackFill: AnyShapeStyle = AnyShapeStyle(IslandDesign.Materials.control),
        fallbackBorder: Color = .clear,
        fallbackBorderWidth: CGFloat = 0
    ) -> some View {
        modifier(
            IslandInteractiveGlassModifier(
                shape: shape,
                tint: tint,
                fallbackFill: fallbackFill,
                fallbackBorder: fallbackBorder,
                fallbackBorderWidth: fallbackBorderWidth
            )
        )
    }
}
