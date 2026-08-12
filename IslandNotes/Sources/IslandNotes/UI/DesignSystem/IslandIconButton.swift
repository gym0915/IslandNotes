import SwiftUI

struct IslandIconButton: View {
    let icon: AppIcon
    let label: String
    var kind: IslandActionKind = .neutral
    var role: ButtonRole?
    let action: () -> Void

    init(
        icon: AppIcon,
        label: String,
        kind: IslandActionKind = .neutral,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.label = label
        self.kind = kind
        self.role = role
        self.action = action
    }

    var body: some View {
        Button(role: role, action: action) {
            AppIconView(icon: icon)
                .foregroundStyle(kind.foreground)
                .frame(
                    width: IslandDesign.Sizing.minimumTouchTarget,
                    height: IslandDesign.Sizing.minimumTouchTarget
                )
                .islandInteractiveGlass(
                    shape: .circle,
                    tint: kind.glassTint,
                    fallbackFill: background,
                    fallbackBorder: kind.border,
                    fallbackBorderWidth: IslandDesign.Sizing.hairline
                )
                .contentShape(Circle())
        }
        .buttonStyle(IslandIconPressStyle())
        .accessibilityLabel(Text(label))
    }

    private var background: AnyShapeStyle {
        if kind == .neutral {
            AnyShapeStyle(IslandDesign.Materials.control)
        } else {
            AnyShapeStyle(kind.background)
        }
    }
}

private struct IslandIconPressStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(isEnabled ? (configuration.isPressed ? 0.72 : 1) : 0.42)
            .scaleEffect(
                IslandDesign.Motion.interactiveScale(
                    isPressed: configuration.isPressed,
                    reduceMotion: reduceMotion
                )
            )
            .animation(
                IslandDesign.Motion.animation(reduceMotion: reduceMotion),
                value: configuration.isPressed
            )
    }
}

#Preview("Icon button · Light") {
    HStack(spacing: IslandDesign.Spacing.x4) {
        IslandIconButton(icon: .moveToLibrary, label: "Move to Note Library") {}
        IslandIconButton(icon: .delete, label: "Delete Note") {}
            .disabled(true)
    }
    .padding(IslandDesign.Spacing.x6)
    .background(IslandDesign.Colors.canvas)
    .preferredColorScheme(.light)
}

#Preview("Icon button · Dark") {
    HStack(spacing: IslandDesign.Spacing.x4) {
        IslandIconButton(icon: .moveToLibrary, label: "Move to Note Library") {}
        IslandIconButton(icon: .delete, label: "Delete Note") {}
            .disabled(true)
    }
    .padding(IslandDesign.Spacing.x6)
    .background(IslandDesign.Colors.canvas)
    .preferredColorScheme(.dark)
}
