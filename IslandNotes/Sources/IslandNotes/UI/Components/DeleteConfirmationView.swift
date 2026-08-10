import SwiftUI

struct DeleteConfirmationView: View {
    let message: String
    let feedback: String?
    let isBusy: Bool
    let cancel: () -> Void
    let confirm: () -> Void

    var body: some View {
        IslandSurface(elevation: .menu, radius: IslandDesign.Radius.card) {
            ViewThatFits(in: .vertical) {
                VStack(spacing: IslandDesign.Spacing.x4) {
                    explanation
                    actions
                }

                VStack(spacing: IslandDesign.Spacing.x4) {
                    ScrollView {
                        explanation
                    }
                    .scrollIndicators(.hidden)
                    .frame(maxHeight: .infinity)

                    actions
                }
            }
            .padding(IslandDesign.Spacing.x6)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("delete-confirmation")
    }

    private var explanation: some View {
        VStack(spacing: IslandDesign.Spacing.x4) {
            VStack(spacing: IslandDesign.Spacing.x2) {
                Text("Delete this note?")
                    .font(IslandDesign.Typography.sheetTitle)
                    .foregroundStyle(IslandDesign.Colors.primaryText)
                    .accessibilitySortPriority(4)

                Text(message)
                    .font(IslandDesign.Typography.body)
                    .foregroundStyle(IslandDesign.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .accessibilitySortPriority(3)
            }

            if let feedback {
                HintMessageView(message: feedback)
            }
        }
    }

    private var actions: some View {
        VStack(spacing: IslandDesign.Spacing.x2) {
            Button("Delete Note", role: .destructive, action: confirm)
                .buttonStyle(DeleteConfirmationButtonStyle(kind: .destructive))
                .disabled(isBusy)
                .accessibilityIdentifier("confirm-delete-note")
                .accessibilitySortPriority(2)

            Button("Cancel", action: cancel)
                .buttonStyle(DeleteConfirmationButtonStyle(kind: .neutral))
                .disabled(isBusy)
                .accessibilityIdentifier("cancel-delete")
                .accessibilitySortPriority(1)
        }
    }
}

private struct DeleteConfirmationButtonStyle: ButtonStyle {
    let kind: IslandActionKind

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(IslandDesign.Typography.action)
            .foregroundStyle(kind.foreground)
            .frame(maxWidth: .infinity, minHeight: IslandDesign.Sizing.actionHeight)
            .background(
                kind.background,
                in: RoundedRectangle(
                    cornerRadius: IslandDesign.Radius.compact,
                    style: .continuous
                )
            )
            .opacity(isEnabled ? (configuration.isPressed ? 0.72 : 1) : 0.42)
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
}
