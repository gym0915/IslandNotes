import SwiftUI

struct SettingsView: View {
    @Bindable var appearance: AppearanceSettings

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: IslandDesign.Spacing.x6) {
                settingsGroup(title: "Appearance") {
                    appearanceMenu
                }

                settingsGroup(title: "Support") {
                    VStack(spacing: 0) {
                        SettingsRow(
                            title: "Feedback",
                            icon: .feedback,
                            identifier: "settings-feedback",
                            action: {}
                        )
                        groupDivider
                        SettingsRow(
                            title: "Website",
                            icon: .website,
                            identifier: "settings-website",
                            action: {}
                        )
                        groupDivider
                        SettingsRow(
                            title: "About",
                            icon: .about,
                            identifier: "settings-about",
                            action: {}
                        )
                    }
                }
            }
            .padding(.horizontal, IslandDesign.Spacing.x4)
            .padding(.top, IslandDesign.Spacing.x2)
            .padding(.bottom, IslandDesign.Spacing.x8)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("settings-content")
        .accessibilityValue(appearance.mode.title)
    }

    private var appearanceMenu: some View {
        Menu {
            ForEach(AppearanceMode.allCases) { mode in
                Button {
                    appearance.select(mode)
                } label: {
                    if appearance.mode == mode {
                        Label(mode.title, image: AppIcon.check.assetName)
                    } else {
                        Text(mode.title)
                    }
                }
                .accessibilityIdentifier("appearance-mode-\(mode.rawValue)")
                .accessibilityValue(appearance.mode == mode ? "Selected" : "Not selected")
            }
        } label: {
            HStack(spacing: IslandDesign.Spacing.x4) {
                AppIconView(icon: .appearance)
                    .foregroundStyle(IslandDesign.Colors.primaryText)

                Text("Display Mode")
                    .font(IslandDesign.Typography.body)
                    .foregroundStyle(IslandDesign.Colors.primaryText)

                Spacer(minLength: 0)

                Text(appearance.mode.title)
                    .font(IslandDesign.Typography.body)
                    .foregroundStyle(IslandDesign.Colors.secondaryText)

                AppIconView(icon: .chevronDown, size: IslandDesign.Sizing.smallIcon)
                    .foregroundStyle(IslandDesign.Colors.secondaryText)
            }
            .padding(.horizontal, IslandDesign.Spacing.x4)
            .frame(minHeight: IslandDesign.Sizing.actionHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("display-mode-menu")
        .accessibilityValue(appearance.mode.title)
    }

    private var groupDivider: some View {
        Divider()
            .overlay(IslandDesign.Colors.separator)
            .padding(.leading, IslandDesign.Spacing.x4 * 3)
    }

    private func settingsGroup<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: IslandDesign.Spacing.x2) {
            Text(title)
                .font(IslandDesign.Typography.caption)
                .foregroundStyle(IslandDesign.Colors.secondaryText)
                .textCase(.uppercase)
                .padding(.horizontal, IslandDesign.Spacing.x1)

            IslandSurface(content: content)
        }
    }
}
