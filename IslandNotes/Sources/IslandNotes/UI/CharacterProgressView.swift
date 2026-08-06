import SwiftUI

struct CharacterProgressView: View {
    let progress: CharacterProgress
    let isExpanded: Bool
    let didReachLimit: Bool
    let reveal: () -> Void

    var body: some View {
        Button(action: reveal) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(.secondary.opacity(0.18), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: CGFloat(progress.used) / 240)
                        .stroke(
                            didReachLimit ? Color.orange : Color.primary,
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 34, height: 34)

                if isExpanded {
                    Text("\(progress.used) used · \(progress.remaining) remaining")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .transition(.opacity)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("character-progress")
        .accessibilityLabel("Character count")
        .accessibilityValue(progress.accessibilityValue)
        .accessibilityHint("Shows used and remaining characters")
    }
}
