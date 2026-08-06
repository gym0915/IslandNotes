import SwiftUI

struct HintMessageView: View {
    let message: String

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
    }
}
