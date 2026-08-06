import SwiftUI

enum IslandActionKind: CaseIterable, Equatable, Sendable {
    case primary
    case neutral
    case live
    case destructive

    var accessibilityValue: String {
        switch self {
        case .primary: "Primary"
        case .neutral: "Neutral"
        case .live: "Live"
        case .destructive: "Destructive"
        }
    }

    fileprivate var background: Color {
        switch self {
        case .primary: IslandDesign.Colors.primaryText
        case .neutral: IslandDesign.Colors.raisedSurface
        case .live: IslandDesign.Colors.surface
        case .destructive: IslandDesign.Colors.destructive
        }
    }

    fileprivate var foreground: Color {
        switch self {
        case .primary: IslandDesign.Colors.canvas
        case .neutral, .live: IslandDesign.Colors.primaryText
        case .destructive: .white
        }
    }

    fileprivate var border: Color {
        switch self {
        case .live: IslandDesign.Colors.border
        case .primary, .neutral, .destructive: .clear
        }
    }
}

struct IslandButtonStyle: ButtonStyle {
    let kind: IslandActionKind

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(kind: IslandActionKind = .neutral) {
        self.kind = kind
    }

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: IslandDesign.Spacing.x2) {
            if kind == .live {
                Circle()
                    .fill(IslandDesign.Colors.live)
                    .frame(
                        width: IslandDesign.Sizing.statusDot,
                        height: IslandDesign.Sizing.statusDot
                    )
                    .accessibilityHidden(true)
            }

            configuration.label
        }
            .font(IslandDesign.Typography.action)
            .foregroundStyle(kind.foreground)
            .padding(.horizontal, IslandDesign.Spacing.x4)
            .frame(
                minWidth: IslandDesign.Sizing.minimumTouchTarget,
                minHeight: IslandDesign.Sizing.actionHeight
            )
            .background(kind.background, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(kind.border, lineWidth: IslandDesign.Sizing.hairline)
            }
            .contentShape(Capsule())
            .opacity(opacity(isPressed: configuration.isPressed))
            .scaleEffect(
                IslandDesign.Motion.interactiveScale(
                    isPressed: configuration.isPressed,
                    reduceMotion: reduceMotion
                )
            )
            .animation(
                IslandDesign.Motion.animation(reduceMotion: reduceMotion),
                value: configuration.isPressed
            )
    }

    private func opacity(isPressed: Bool) -> Double {
        guard isEnabled else { return 0.42 }
        return isPressed ? 0.72 : 1
    }
}

private struct IslandButtonPreviewGallery: View {
    var body: some View {
        VStack(alignment: .leading, spacing: IslandDesign.Spacing.x4) {
            ForEach(IslandActionKind.allCases, id: \.self) { kind in
                Button(kind.accessibilityValue) {}
                    .buttonStyle(IslandButtonStyle(kind: kind))
            }

            Button("Disabled") {}
                .buttonStyle(IslandButtonStyle(kind: .primary))
                .disabled(true)

            Text("Press and hold an enabled action to inspect its pressed state.")
                .font(IslandDesign.Typography.caption)
                .foregroundStyle(IslandDesign.Colors.secondaryText)
        }
        .padding(IslandDesign.Spacing.x6)
        .background(IslandDesign.Colors.canvas)
    }
}

#Preview("Actions · Light") {
    IslandButtonPreviewGallery()
        .preferredColorScheme(.light)
}

#Preview("Actions · Dark") {
    IslandButtonPreviewGallery()
        .preferredColorScheme(.dark)
}
