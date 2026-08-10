import SwiftUI

enum AppIcon: String, CaseIterable {
    case more = "lucide-ellipsis"
    case noteLibrary = "lucide-library"
    case settings = "lucide-settings"
    case close = "lucide-x"
    case moveToLibrary = "lucide-archive"
    case delete = "lucide-trash-2"
    case replace = "lucide-replace"
    case appearance = "lucide-monitor"
    case light = "lucide-sun"
    case dark = "lucide-moon"
    case feedback = "lucide-message-circle"
    case website = "lucide-globe"
    case about = "lucide-info"
    case check = "lucide-check"
    case noteBrand = "lucide-notebook-text"
    case chevronDown = "lucide-chevron-down"
    case chevronRight = "lucide-chevron-right"

    static let automatic: AppIcon = .appearance

    var assetName: String {
        rawValue
    }
}

struct AppIconView: View {
    let icon: AppIcon
    var size = IslandDesign.Sizing.icon

    var body: some View {
        Image(icon.assetName)
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
