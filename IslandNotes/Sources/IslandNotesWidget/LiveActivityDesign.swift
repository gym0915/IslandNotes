import SwiftUI

enum LiveActivityDesign {
    static let brandMarkSize: CGFloat = 22
    static let compactBrandMarkSize: CGFloat = 18
    static let contentSpacing: CGFloat = 12
    static let lockScreenPadding: CGFloat = 16
    static let lockScreenCornerRadius: CGFloat = 24
    static let lockScreenBorderWidth: CGFloat = 1

    static let expandedFont: Font = .callout
    static let lockScreenFont: Font = .system(size: 17, weight: .medium)

    static func lockScreenForegroundColor(usesDarkAppearance: Bool) -> Color {
        usesDarkAppearance ? .white : .black
    }

    static func lockScreenBackgroundColor(usesDarkAppearance: Bool) -> Color {
        usesDarkAppearance
            ? .black.opacity(0.46)
            : .white.opacity(0.56)
    }

    static func lockScreenBorderColor(usesDarkAppearance: Bool) -> Color {
        usesDarkAppearance
            ? .white.opacity(0.16)
            : .white.opacity(0.72)
    }
}
