import SwiftUI

struct AppSheetContainer<Content: View>: View {
    let title: String
    let close: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: IslandDesign.Spacing.x2) {
                Color.clear
                    .frame(
                        width: IslandDesign.Sizing.minimumTouchTarget,
                        height: IslandDesign.Sizing.minimumTouchTarget
                    )
                    .accessibilityHidden(true)

                Spacer(minLength: 0)

                Text(title)
                    .font(IslandDesign.Typography.sheetTitle)
                    .foregroundStyle(IslandDesign.Colors.primaryText)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("sheet-title")

                Spacer(minLength: 0)

                IslandIconButton(icon: .close, label: "Close", action: close)
                    .accessibilityIdentifier("close-sheet")
            }
            .padding(.horizontal, IslandDesign.Spacing.x4)
            .padding(.vertical, IslandDesign.Spacing.x2)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(IslandDesign.Colors.canvas)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("app-sheet")
    }
}

extension View {
    func islandSheetPresentationStyle() -> some View {
        presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(IslandDesign.Radius.sheet)
            .presentationBackground(IslandDesign.Colors.canvas)
    }
}
