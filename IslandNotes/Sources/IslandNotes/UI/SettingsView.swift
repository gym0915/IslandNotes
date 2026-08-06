import SwiftUI

struct SettingsView: View {
    var body: some View {
        VStack(spacing: IslandDesign.Spacing.x4) {
            AppIconView(icon: .settings, size: 28)
                .foregroundStyle(IslandDesign.Colors.secondaryText)
            Text("Appearance settings are coming in a later update.")
                .font(IslandDesign.Typography.body)
                .foregroundStyle(IslandDesign.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(IslandDesign.Spacing.x8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("settings-content")
    }
}
