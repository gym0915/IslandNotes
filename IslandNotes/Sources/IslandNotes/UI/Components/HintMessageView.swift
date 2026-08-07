import SwiftUI
import UIKit

struct RecoverableFeedbackAnnouncementState {
    private var lastMessage: String?

    mutating func nextAnnouncement(for message: String) -> String? {
        guard lastMessage != message else { return nil }
        lastMessage = message
        return message
    }
}

struct HintMessageView: View {
    let message: String
    @State private var announcementState = RecoverableFeedbackAnnouncementState()

    var body: some View {
        Text(message)
            .font(IslandDesign.Typography.feedback)
            .foregroundStyle(IslandDesign.Colors.secondaryText)
            .padding(.horizontal, IslandDesign.Spacing.x4)
            .padding(.vertical, IslandDesign.Spacing.x2)
            .background(IslandDesign.Colors.raisedSurface, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(
                        IslandDesign.Colors.border,
                        lineWidth: IslandDesign.Sizing.hairline
                    )
            }
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier("transient-feedback")
            .accessibilityLabel("Recoverable message")
            .accessibilityValue(message)
            .accessibilityHint("You can try the action again.")
            .onAppear(perform: announceFeedback)
            .onChange(of: message) { _, _ in announceFeedback() }
    }

    private func announceFeedback() {
        guard let announcement = announcementState.nextAnnouncement(for: message) else {
            return
        }
        UIAccessibility.post(notification: .announcement, argument: announcement)
    }
}
