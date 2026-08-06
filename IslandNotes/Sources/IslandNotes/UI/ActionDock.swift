import SwiftUI

struct ActionDock: View {
    @Bindable var feature: IslandNotesFeature

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: IslandDesign.Spacing.x2) { actionButtons }
            VStack(spacing: IslandDesign.Spacing.x2) { actionButtons }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        ActionButton(
            title: "Move to Note Library",
            icon: .moveToLibrary,
            identifier: "archive-current-note",
            role: nil,
            isEnabled: feature.canArchive
        ) {
            Task { try? await feature.archiveCurrentNote() }
        }

        ActionButton(
            title: feature.pinState == .pinned ? "Live" : "Go Live",
            icon: .live,
            identifier: "toggle-pin",
            role: nil,
            isEnabled: feature.pinState == .pinned || feature.canPin,
            isProminent: feature.pinState == .pinned
        ) {
            Task {
                if feature.pinState == .pinned {
                    await feature.cancelPinning()
                } else {
                    await feature.startPinning()
                }
            }
        }

        ActionButton(
            title: "Delete Note",
            icon: .delete,
            identifier: "delete-current-note",
            role: .destructive,
            isEnabled: feature.canDelete
        ) {
            feature.requestDelete()
        }
    }
}

private struct ActionButton: View {
    let title: String
    let icon: AppIcon
    let identifier: String
    let role: ButtonRole?
    let isEnabled: Bool
    var isProminent = false
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: IslandDesign.Spacing.x2) {
                AppIconView(icon: icon, size: IslandDesign.Sizing.smallIcon)
                Text(title)
            }
                .font(IslandDesign.Typography.action)
                .frame(maxWidth: .infinity, minHeight: IslandDesign.Sizing.actionHeight)
        }
        .buttonStyle(.bordered)
        .tint(isProminent ? IslandDesign.Colors.live : nil)
        .disabled(!isEnabled)
        .accessibilityIdentifier(identifier)
        .accessibilityHint(isEnabled ? "" : "The current note needs non-whitespace text")
    }
}
