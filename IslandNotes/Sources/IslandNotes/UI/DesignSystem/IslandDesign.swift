import SwiftUI
import UIKit

enum IslandDesign {
    enum Colors {
        static var canvas: Color {
            adaptive(light: 0xF5F5F2, dark: 0x0A0A0A)
        }

        static var surface: Color {
            adaptive(light: 0xFFFFFF, dark: 0x141414)
        }

        static var raisedSurface: Color {
            adaptive(light: 0xFAFAF8, dark: 0x1C1C1C)
        }

        static var primaryText: Color {
            adaptive(light: 0x171717, dark: 0xF5F5F2)
        }

        static var secondaryText: Color {
            adaptive(light: 0x70706D, dark: 0xA3A39F)
        }

        static var separator: Color {
            adaptive(light: 0xE7E7E2, dark: 0x30302E)
        }

        static var placeholder: Color {
            secondaryText.opacity(0.55)
        }

        static var progressTrack: Color {
            secondaryText.opacity(0.18)
        }

        static var surfaceBorder: Color {
            separator.opacity(0.5)
        }

        static var menuBorder: Color {
            separator.opacity(0.8)
        }

        static var notLive: Color {
            secondaryText.opacity(0.35)
        }

        static let scrim = Color.black.opacity(0.32)
        static let live = Color(red: 0.27, green: 0.58, blue: 0.31)
        static let destructive = Color(red: 0.84, green: 0.22, blue: 0.17)
        static let limit = Color(red: 0.91, green: 0.48, blue: 0.12)

        private static func adaptive(light: UInt32, dark: UInt32) -> Color {
            Color(
                uiColor: UIColor { traits in
                    UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
                }
            )
        }
    }

    enum Typography {
        static let productName = Font.system(.largeTitle, design: .default, weight: .bold)
        static let sheetTitle = Font.system(.headline, design: .default, weight: .semibold)
        static let menuItem = Font.system(.body, design: .default, weight: .medium)
        static let body = Font.system(.body, design: .default, weight: .regular)
        static let caption = Font.system(.caption, design: .default, weight: .semibold)
        static let action = Font.system(.subheadline, design: .default, weight: .semibold)
        static let feedback = Font.system(.footnote, design: .default, weight: .semibold)
        static let editor = Font.system(.title2, design: .default, weight: .regular)
    }

    enum Spacing {
        static let x1: CGFloat = 4
        static let x2: CGFloat = 8
        static let x4: CGFloat = 16
        static let x6: CGFloat = 24
        static let x8: CGFloat = 32
    }

    enum Radius {
        static let compact: CGFloat = 14
        static let card: CGFloat = 22
        static let sheet: CGFloat = 34
        static let pill: CGFloat = 1_000
    }

    enum Elevation {
        struct Shadow {
            let color: Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }

        static let menu = Shadow(color: .black.opacity(0.14), radius: 22, x: 0, y: 12)
        static let card = Shadow(color: .black.opacity(0.06), radius: 22, x: 0, y: 10)
    }

    enum Materials {
        static let menu: Material = .ultraThinMaterial
        static let control: Material = .thinMaterial
    }

    enum Sizing {
        static let minimumTouchTarget: CGFloat = 44
        static let icon: CGFloat = 20
        static let smallIcon: CGFloat = 18
        static let largeIcon: CGFloat = 28
        static let menuWidth: CGFloat = 216
        static let menuTopOffset: CGFloat = 64
        static let statusDot: CGFloat = 7
        static let characterRing: CGFloat = 34
        static let listBullet: CGFloat = 5
        static let editorMinimumHeight: CGFloat = 310
        static let actionHeight: CGFloat = 48
        static let hairline: CGFloat = 1
        static let progressStroke: CGFloat = 4
    }

    enum Motion {
        static let quick: Double = 0.16
        static let standard: Double = 0.18
        static let deliberate: Double = 0.21
        static let menuScale: CGFloat = 0.96
        static let livePulseScale: CGFloat = 1.08

        static func menu(reduceMotion: Bool) -> Animation? {
            reduceMotion ? nil : .easeOut(duration: standard)
        }
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }
}
