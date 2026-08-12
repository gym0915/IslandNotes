import SwiftUI

struct CharacterProgressView: View {
    let progress: CharacterProgress
    let isExpanded: Bool
    let didReachLimit: Bool
    let reveal: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: IslandDesign.Spacing.x2) {
                detail
                progressButton
            }

            VStack(alignment: .trailing, spacing: IslandDesign.Spacing.x2) {
                detail
                progressButton
            }
        }
    }

    @ViewBuilder
    private var detail: some View {
        if isExpanded {
            Text("\(progress.used) used · \(progress.remaining) remaining")
                .font(IslandDesign.Typography.capacity)
                .foregroundStyle(IslandDesign.Colors.canvas)
                .padding(.horizontal, IslandDesign.Spacing.x4)
                .padding(.vertical, IslandDesign.Spacing.x2)
                .background(IslandDesign.Colors.primaryText, in: Capsule())
                .transition(.opacity)
                .accessibilityIdentifier("character-progress-detail")
                .accessibilityHidden(true)
        }
    }

    private var progressButton: some View {
        Button(action: reveal) {
            ZStack {
                Circle()
                    .strokeBorder(
                        IslandDesign.Colors.progressTrack,
                        lineWidth: IslandDesign.Sizing.progressStroke
                    )
                Circle()
                    .inset(by: IslandDesign.Sizing.progressStroke / 2)
                    .trim(
                        from: 0,
                        to: CGFloat(progress.used) / CGFloat(TextLimiter.maximumCharacterCount)
                    )
                    .stroke(
                        didReachLimit
                            ? IslandDesign.Colors.limit
                            : IslandDesign.Colors.progress,
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
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("character-progress")
        .accessibilityLabel(didReachLimit ? "Character limit reached" : "Character count")
        .accessibilityValue(progress.accessibilityValue)
        .accessibilityHint("Shows used and remaining characters")
    }
}
