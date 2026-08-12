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

        static var workbenchCanvas: Color {
            adaptive(light: 0xF4F4F5, dark: 0x000000)
        }

        static var workbenchSurface: Color {
            adaptive(light: 0xF8F8F9, dark: 0x121213)
        }

        static var workbenchSurfaceBorder: Color {
            adaptive(light: 0xFFFFFF, dark: 0x343436)
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

        static var border: Color {
            separator
        }

        static var placeholder: Color {
            secondaryText.opacity(0.45)
        }

        static var progressTrack: Color {
            secondaryText.opacity(0.18)
        }

        static var progress: Color {
            primaryText
        }

        static var dockControlBackground: Color {
            adaptive(light: 0xFDFDFD, dark: 0x101010)
        }

        static var liveActionBackground: Color {
            adaptive(light: 0xF4F4F5, dark: 0x000000)
        }

        static var liveActionBorder: Color {
            adaptive(light: 0xE4E4E5, dark: 0x1A1A1A)
        }

        static var liveReadyRing: Color {
            adaptive(light: 0x85858A, dark: 0x8C8C8F)
        }

        static var workbenchLiveCore: Color {
            adaptive(light: 0x3F743A, dark: 0x3F743A)
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
        static let workbenchTitle = Font.system(size: 20, weight: .bold)
        static let screenTitle = Font.system(.headline, design: .default, weight: .semibold)
        static let sheetTitle = screenTitle
        static let menuItem = Font.system(.body, design: .default, weight: .medium)
        static let body = Font.system(.body, design: .default, weight: .regular)
        static let noteBody = Font.system(.title2, design: .default, weight: .regular)
        static let caption = Font.system(.caption, design: .default, weight: .semibold)
        static let metadata = Font.system(.caption, design: .monospaced, weight: .regular)
        static let capacity = Font.system(.caption, design: .monospaced, weight: .semibold)
        static let action = Font.system(.subheadline, design: .default, weight: .semibold)
        static let feedback = Font.system(.footnote, design: .default, weight: .semibold)
        static let editor = noteBody
        static let editorTextStyle: UIFont.TextStyle = .title2
    }

    enum Spacing {
        static let x1: CGFloat = 4
        static let x2: CGFloat = 8
        static let x4: CGFloat = 16
        static let x6: CGFloat = 24
        static let x8: CGFloat = 32

    }

    enum Radius {
        static let settingsItem: CGFloat = 10
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

        static let control = Shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 6)
        static let menu = Shadow(color: .black.opacity(0.14), radius: 22, x: 0, y: 12)
        static let card = Shadow(color: .black.opacity(0.06), radius: 22, x: 0, y: 10)
    }

    enum Materials {
        static let menu: Material = .ultraThinMaterial
        static let control: Material = .thinMaterial
    }

    enum Sizing {
        static let minimumTouchTarget: CGFloat = 44
        static let icon: CGFloat = 22
        static let smallIcon: CGFloat = 18
        static let largeIcon: CGFloat = 28
        static let menuWidth: CGFloat = 216
        // The menu starts below the 48pt header action target with an 8pt
        // visual gap, matching the workbench screenshot.
        static let menuTopOffset: CGFloat = 72
        static let statusDot: CGFloat = 7
        static let characterRing: CGFloat = 32
        static let listBullet: CGFloat = 5
        static let actionHeight: CGFloat = 48
        static let hairline: CGFloat = 1
        static let progressStroke: CGFloat = 3
        static let dockIconTarget: CGFloat = 56
        static let dockActionHeight: CGFloat = 56
        static let liveActionWidth: CGFloat = 140
        static let compactLiveActionWidth: CGFloat = 116
        static let accessibilityActionHeight: CGFloat = 72
        static let liveIndicatorSlot: CGFloat = 16
        static let liveReadyRing: CGFloat = 14
        static let liveStatusDot: CGFloat = 14
        static let liveIndicatorStroke: CGFloat = 2
        static let liveIndicatorLeadingPadding: CGFloat = 20
        static let headerActionTarget: CGFloat = 48
        static let increasedContrastStroke: CGFloat = 2
        static let increasedContrastIndicatorStroke: CGFloat = 3
        static let expandedCharacterAccessoryHeight: CGFloat = 120
    }

    enum Opacity {
        static let pressed = 0.72
        static let disabled = 0.42
        static let busy = 0.72
        static let livePulseCore = 0.18
    }

    enum Workbench {
        static let noteSurfaceAspectRatio: CGFloat = 3.0 / 4.0
        static let noteSurfaceCenterYOffset: CGFloat = 3
        static let headerGap: CGFloat = 72
        static let editingHeaderGap: CGFloat = 24
        static let bottomGap: CGFloat = 32
        static let editingBottomGap: CGFloat = 16
        static let feedbackAvoidance: CGFloat = 72
        static let accessibilityFeedbackAvoidance: CGFloat = 104
        static let dockOuterControlInset: CGFloat = 16
    }

    enum Motion {
        static let quick: Double = 0.16
        static let standard: Double = 0.18
        static let deliberate: Double = 0.21
        static let menuScale: CGFloat = 0.96
        static let livePulseTransitionDuration: Double = 1.15
        static let livePulseEndpointHold: Double = 0.25
        static let pressedScale: CGFloat = 0.97
        static let workbenchEditingResponse: Double = 0.42
        static let workbenchEditingDamping: Double = 0.92

        static func animation(
            duration: Double = standard,
            reduceMotion: Bool
        ) -> Animation? {
            reduceMotion ? nil : .easeOut(duration: duration)
        }

        static func menu(reduceMotion: Bool) -> Animation? {
            animation(reduceMotion: reduceMotion)
        }

        static func workbenchEditing(reduceMotion: Bool) -> Animation? {
            guard !reduceMotion else { return nil }
            return .spring(
                response: workbenchEditingResponse,
                dampingFraction: workbenchEditingDamping,
                blendDuration: 0.08
            )
        }

        static func interactiveScale(isPressed: Bool, reduceMotion: Bool) -> CGFloat {
            isPressed && !reduceMotion ? pressedScale : 1
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
