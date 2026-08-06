import SwiftUI

struct AppSheetContainer<Content: View>: View {
    let title: String
    let close: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(title)
                    .font(IslandDesign.Typography.sheetTitle)
                    .foregroundStyle(IslandDesign.Colors.primaryText)
                    .multilineTextAlignment(.center)

                HStack {
                    Spacer()
                    Button(action: close) {
                        AppIconView(icon: .close, size: IslandDesign.Sizing.smallIcon)
                            .frame(
                                width: IslandDesign.Sizing.minimumTouchTarget,
                                height: IslandDesign.Sizing.minimumTouchTarget
                            )
                            .background(IslandDesign.Colors.raisedSurface, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("close-sheet")
                    .accessibilityLabel("Close")
                }
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
