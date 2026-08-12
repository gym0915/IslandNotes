import SwiftUI

struct MoreMenu: View {
    let openNoteLibrary: () -> Void
    let openSettings: () -> Void

    var body: some View {
        Menu {
            menuItem(
                title: "Note Library",
                icon: .noteLibrary,
                identifier: "open-note-library",
                accessibilityValue: "Opens Note Library",
                action: openNoteLibrary
            )

            menuItem(
                title: "Settings",
                icon: .settings,
                identifier: "open-settings",
                accessibilityValue: "Opens Settings",
                action: openSettings
            )
        } label: {
            AppIconView(icon: .more)
                .foregroundStyle(IslandDesign.Colors.primaryText)
                .frame(
                    width: IslandDesign.Sizing.headerActionTarget,
                    height: IslandDesign.Sizing.headerActionTarget
                )
                .islandInteractiveGlass(
                    shape: .circle,
                    fallbackFill: AnyShapeStyle(IslandDesign.Materials.control),
                    fallbackBorder: IslandDesign.Colors.menuBorder,
                    fallbackBorderWidth: IslandDesign.Sizing.hairline
                )
                .contentShape(Circle())
        }
        .menuStyle(.automatic)
        .accessibilityLabel("More")
        .accessibilityIdentifier("open-more-menu")
    }

    private func menuItem(
        title: String,
        icon: AppIcon,
        identifier: String,
        accessibilityValue: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label {
                Text(title)
            } icon: {
                AppIconView(icon: icon)
            }
        }
        .accessibilityIdentifier(identifier)
        .accessibilityValue(accessibilityValue)
    }
}
