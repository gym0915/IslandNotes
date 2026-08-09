import SwiftUI

struct SettingsRow: View {
    let title: String
    let icon: AppIcon
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: IslandDesign.Spacing.x4) {
                AppIconView(icon: icon)
                    .foregroundStyle(IslandDesign.Colors.primaryText)

                Text(title)
                    .font(IslandDesign.Typography.body)
                    .foregroundStyle(IslandDesign.Colors.primaryText)

                Spacer(minLength: 0)

                AppIconView(icon: .chevronRight, size: IslandDesign.Sizing.smallIcon)
                    .foregroundStyle(IslandDesign.Colors.secondaryText)
            }
            .padding(.horizontal, IslandDesign.Spacing.x4)
            .frame(minHeight: IslandDesign.Sizing.minimumTouchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(SettingsRowButtonStyle())
        .accessibilityIdentifier(identifier)
    }
}

private struct SettingsRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                    ? IslandDesign.Colors.raisedSurface
                    : Color.clear
            )
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}
