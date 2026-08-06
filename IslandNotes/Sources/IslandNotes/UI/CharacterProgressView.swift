import SwiftUI

struct CharacterProgressView: View {
    let progress: CharacterProgress
    let isExpanded: Bool
    let didReachLimit: Bool
    let reveal: () -> Void

    var body: some View {
        Button(action: reveal) {
            HStack(spacing: IslandDesign.Spacing.x2) {
                ZStack {
                    Circle()
                        .stroke(
                            IslandDesign.Colors.progressTrack,
                            lineWidth: IslandDesign.Sizing.progressStroke
                        )
                    Circle()
                        .trim(from: 0, to: CGFloat(progress.used) / 240)
                        .stroke(
                            didReachLimit
                                ? IslandDesign.Colors.limit
                                : IslandDesign.Colors.primaryText,
                            style: StrokeStyle(
                                lineWidth: IslandDesign.Sizing.progressStroke,
                                lineCap: .round
                            )
                        )
                        .rotationEffect(.degrees(-90))
                }
                .frame(
                    width: IslandDesign.Sizing.characterRing,
                    height: IslandDesign.Sizing.characterRing
                )

                if isExpanded {
                    Text("\(progress.used) used · \(progress.remaining) remaining")
                        .font(IslandDesign.Typography.caption)
                        .foregroundStyle(IslandDesign.Colors.secondaryText)
                        .transition(.opacity)
                }
            }
            .frame(
                minWidth: IslandDesign.Sizing.minimumTouchTarget,
                minHeight: IslandDesign.Sizing.minimumTouchTarget,
                alignment: .trailing
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("character-progress")
        .accessibilityLabel("Character count")
        .accessibilityValue(progress.accessibilityValue)
        .accessibilityHint("Shows used and remaining characters")
    }
}
