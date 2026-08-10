import SwiftUI

struct LiveActionControl: View {
    let model: LiveActionControlModel
    let width: CGFloat
    let height: CGFloat
    let compactContent: Bool
    var reduceMotionOverride: Bool? = nil
    let action: () -> Void

    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    var body: some View {
        Button(action: action) {
            HStack(spacing: IslandDesign.Spacing.x2) {
                LiveStatusIndicator(
                    state: model.state,
                    reduceMotionOverride: reduceMotionOverride
                )
                Text(model.label)
                    .font(IslandDesign.Typography.action)
                    .foregroundStyle(IslandDesign.Colors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }
            .padding(.leading, IslandDesign.Sizing.liveIndicatorLeadingPadding)
            .padding(
                .trailing,
                compactContent ? IslandDesign.Spacing.x2 : IslandDesign.Spacing.x4
            )
            .frame(width: width, height: height, alignment: .leading)
            .background(IslandDesign.Colors.liveActionBackground, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(
                        IslandDesign.Colors.liveActionBorder,
                        lineWidth: borderWidth
                    )
            }
            .contentShape(Capsule())
        }
        .buttonStyle(
            DockPressStyle(
                isBusy: !model.isEnabled && model.state != .unavailable
            )
        )
        .disabled(!model.isEnabled)
        .accessibilityIdentifier("toggle-pin")
        .accessibilityLabel(model.label)
        .accessibilityValue(model.accessibilityValue)
        .accessibilityHint(model.accessibilityHint)
    }

    private var borderWidth: CGFloat {
        colorSchemeContrast == .increased
            ? IslandDesign.Sizing.increasedContrastStroke
            : IslandDesign.Sizing.hairline
    }
}

struct LiveStatusIndicator: View {
    let state: LiveActionState
    var reduceMotionOverride: Bool? = nil

    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPulseDimmed = false

    var body: some View {
        ZStack {
            switch state {
            case .unavailable, .ready:
                hollowCircle
            case .starting:
                hollowCircle
                progressArc(color: IslandDesign.Colors.primaryText)
            case .live:
                liveDot(isBreathing: true)
            case .stopping:
                liveDot(isBreathing: false)
                progressArc(color: IslandDesign.Colors.workbenchLiveCore)
            }
        }
        .frame(
            width: IslandDesign.Sizing.liveIndicatorSlot,
            height: IslandDesign.Sizing.liveIndicatorSlot
        )
        .accessibilityHidden(true)
        .task(id: pulseTaskID) {
            isPulseDimmed = false
            guard state == .live, !effectiveReduceMotion else { return }

            while !Task.isCancelled {
                withAnimation(.easeInOut(duration: IslandDesign.Motion.livePulseHalfCycle)) {
                    isPulseDimmed.toggle()
                }
                do {
                    try await Task.sleep(
                        for: .seconds(IslandDesign.Motion.livePulseHalfCycle)
                    )
                } catch {
                    return
                }
            }
        }
    }

    private var hollowCircle: some View {
        Circle()
            .strokeBorder(
                IslandDesign.Colors.liveReadyRing,
                lineWidth: indicatorStroke
            )
            .frame(
                width: IslandDesign.Sizing.liveReadyRing,
                height: IslandDesign.Sizing.liveReadyRing
            )
    }

    private func liveDot(isBreathing: Bool) -> some View {
        ZStack {
            Circle()
                .fill(IslandDesign.Colors.workbenchLiveHalo)
                .frame(
                    width: IslandDesign.Sizing.liveStatusHalo,
                    height: IslandDesign.Sizing.liveStatusHalo
                )
                .opacity(
                    isBreathing && isPulseDimmed
                        ? IslandDesign.Opacity.livePulseHalo
                        : 1
                )

            Circle()
                .fill(IslandDesign.Colors.workbenchLiveCore)
                .frame(
                    width: IslandDesign.Sizing.liveStatusDot,
                    height: IslandDesign.Sizing.liveStatusDot
                )
                .opacity(
                    isBreathing && isPulseDimmed
                        ? IslandDesign.Opacity.livePulseCore
                        : 1
                )
        }
    }

    private func progressArc(color: Color) -> some View {
        Circle()
            .trim(from: 0.08, to: 0.7)
            .stroke(
                color,
                style: StrokeStyle(
                    lineWidth: indicatorStroke,
                    lineCap: .round
                )
            )
            .rotationEffect(.degrees(-90))
            .frame(
                width: IslandDesign.Sizing.liveIndicatorSlot,
                height: IslandDesign.Sizing.liveIndicatorSlot
            )
    }

    private var indicatorStroke: CGFloat {
        colorSchemeContrast == .increased
            ? IslandDesign.Sizing.increasedContrastIndicatorStroke
            : IslandDesign.Sizing.liveIndicatorStroke
    }

    private var pulseTaskID: String {
        "\(state)-\(effectiveReduceMotion)"
    }

    private var effectiveReduceMotion: Bool {
        reduceMotionOverride ?? reduceMotion
    }
}
