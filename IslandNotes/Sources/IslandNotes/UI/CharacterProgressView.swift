import SwiftUI

struct CharacterProgressView: View {
    let progress: CharacterProgress
    let isExpanded: Bool
    let didReachLimit: Bool
    let reveal: () -> Void

    var body: some View {
        HStack(spacing: IslandDesign.Spacing.x2) {
            if isExpanded {
                Text("\(progress.used) used · \(progress.remaining) remaining")
                    .font(IslandDesign.Typography.caption)
                    .foregroundStyle(IslandDesign.Colors.secondaryText)
                    .transition(.opacity)
                    .accessibilityIdentifier("character-progress-detail")
            }

            Button(action: reveal) {
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
                .frame(
                    minWidth: IslandDesign.Sizing.minimumTouchTarget,
                    minHeight: IslandDesign.Sizing.minimumTouchTarget
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
}
