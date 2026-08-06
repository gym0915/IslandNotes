import SwiftUI

struct MoreMenu: View {
    let openNoteLibrary: () -> Void
    let openSettings: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            menuButton(
                title: "Note Library",
                icon: .noteLibrary,
                identifier: "open-note-library",
                action: openNoteLibrary
            )

            Divider()
                .overlay(IslandDesign.Colors.separator)
                .padding(.horizontal, IslandDesign.Spacing.x4)

            menuButton(
                title: "Settings",
                icon: .settings,
                identifier: "open-settings",
                action: openSettings
            )
        }
        .padding(.vertical, IslandDesign.Spacing.x2)
        .frame(width: IslandDesign.Sizing.menuWidth)
        .background(
            IslandDesign.Materials.menu,
            in: RoundedRectangle(
                cornerRadius: IslandDesign.Radius.compact,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: IslandDesign.Radius.compact,
                style: .continuous
            )
            .stroke(IslandDesign.Colors.separator.opacity(0.8), lineWidth: 1)
        }
        .shadow(
            color: IslandDesign.Elevation.menu.color,
            radius: IslandDesign.Elevation.menu.radius,
            x: IslandDesign.Elevation.menu.x,
            y: IslandDesign.Elevation.menu.y
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("more-menu")
    }

    private func menuButton(
        title: String,
        icon: AppIcon,
        identifier: String,
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}
