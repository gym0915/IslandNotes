import SwiftUI

struct DockIconAction: View {
    let icon: AppIcon
    let label: String
    let identifier: String
    let state: DockActionState
    let action: () -> Void

    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(IslandDesign.Colors.dockControlBackground)
                Circle()
                    .strokeBorder(
                        IslandDesign.Colors.surfaceBorder,
                        lineWidth: borderWidth
                    )

                if state.isBusy {
                    ProgressView()
                        .controlSize(.small)
                        .tint(IslandDesign.Colors.primaryText)
                } else {
                    AppIconView(icon: icon)
                        .foregroundStyle(IslandDesign.Colors.primaryText)
                }
            }
            .frame(
                width: IslandDesign.Sizing.dockIconTarget,
                height: IslandDesign.Sizing.dockIconTarget
            )
            .shadow(
                color: IslandDesign.Elevation.control.color,
                radius: IslandDesign.Elevation.control.radius,
                x: IslandDesign.Elevation.control.x,
                y: IslandDesign.Elevation.control.y
            )
            .contentShape(Circle())
        }
        .buttonStyle(DockPressStyle(isBusy: state.isBusy))
        .disabled(!state.isEnabled)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(label)
        .accessibilityHint(state.accessibilityHint)
    }

    private var borderWidth: CGFloat {
        colorSchemeContrast == .increased
            ? IslandDesign.Sizing.increasedContrastStroke
            : 0
    }
}

struct DockPressStyle: ButtonStyle {
    let isBusy: Bool

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(opacity(isPressed: configuration.isPressed))
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

    private func opacity(isPressed: Bool) -> Double {
        if isPressed { return IslandDesign.Opacity.pressed }
        if isBusy { return IslandDesign.Opacity.busy }
        return isEnabled ? 1 : IslandDesign.Opacity.disabled
    }
}
