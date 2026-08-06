import SwiftUI

struct IslandIconButton: View {
    let icon: AppIcon
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AppIconView(icon: icon)
                .foregroundStyle(IslandDesign.Colors.primaryText)
                .frame(
                    width: IslandDesign.Sizing.minimumTouchTarget,
                    height: IslandDesign.Sizing.minimumTouchTarget
                )
                .background(IslandDesign.Materials.control, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(IslandIconPressStyle())
        .accessibilityLabel(Text(label))
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
