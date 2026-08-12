import SwiftUI

struct MoreMenu: View {
    let openNoteLibrary: () -> Void
    let openSettings: () -> Void

    var body: some View {
        IslandGlassEffectGroup(spacing: IslandDesign.Spacing.x2) {
            VStack(spacing: IslandDesign.Spacing.x2) {
                menuButton(
                    title: "Note Library",
                    icon: .noteLibrary,
                    identifier: "open-note-library",
                    accessibilityValue: "Opens Note Library",
                    action: openNoteLibrary
                )

                menuButton(
                    title: "Settings",
                    icon: .settings,
                    identifier: "open-settings",
                    accessibilityValue: "Opens Settings",
                    action: openSettings
                )
            }
        }
        .padding(.vertical, IslandDesign.Spacing.x2)
        .frame(width: IslandDesign.Sizing.menuWidth)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("more-menu")
    }

    private func menuButton(
        title: String,
        icon: AppIcon,
        identifier: String,
        accessibilityValue: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: IslandDesign.Spacing.x4) {
                AppIconView(icon: icon)
                Text(title)
                    .font(IslandDesign.Typography.menuItem)
                Spacer(minLength: 0)
            }
            .foregroundStyle(IslandDesign.Colors.primaryText)
            .padding(.horizontal, IslandDesign.Spacing.x4)
            .frame(minHeight: IslandDesign.Sizing.minimumTouchTarget)
            .islandInteractiveGlass(
                shape: .roundedRectangle(IslandDesign.Radius.compact),
                fallbackFill: AnyShapeStyle(IslandDesign.Materials.menu),
                fallbackBorder: IslandDesign.Colors.menuBorder,
                fallbackBorderWidth: IslandDesign.Sizing.hairline
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
        .accessibilityValue(accessibilityValue)
    }
}
