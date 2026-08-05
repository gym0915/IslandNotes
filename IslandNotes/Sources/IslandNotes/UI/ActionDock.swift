import SwiftUI

struct ActionDock: View {
    @Bindable var feature: IslandNotesFeature

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) { actionButtons }
            VStack(spacing: 10) { actionButtons }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        ActionButton(
            title: "放入便签库",
            systemImage: "tray.and.arrow.down",
            identifier: "archive-current-note",
            role: nil,
            isEnabled: feature.canArchive
        ) {
            Task { try? await feature.archiveCurrentNote() }
        }

        ActionButton(
            title: feature.pinState == .pinned ? "取消挂起" : "挂起",
            systemImage: feature.pinState == .pinned ? "pin.slash" : "pin",
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
            title: "删除",
            systemImage: "trash",
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
    let systemImage: String
    let identifier: String
    let role: ButtonRole?
    let isEnabled: Bool
    var isProminent = false
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 48)
        }
        .buttonStyle(.bordered)
        .tint(isProminent ? Color(red: 0.48, green: 0.66, blue: 0.50) : nil)
        .disabled(!isEnabled)
        .accessibilityIdentifier(identifier)
        .accessibilityHint(isEnabled ? "" : "当前便签需要包含非空白内容")
    }
}
