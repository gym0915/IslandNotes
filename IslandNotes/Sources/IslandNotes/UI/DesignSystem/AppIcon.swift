import SwiftUI

enum AppIcon: String {
    case more = "lucide-ellipsis"
    case noteLibrary = "lucide-library"
    case settings = "lucide-settings"
    case close = "lucide-x"
    case moveToLibrary = "lucide-archive"
    case live = "lucide-radio"
    case delete = "lucide-trash-2"
}

struct AppIconView: View {
    let icon: AppIcon
    var size = IslandDesign.Sizing.icon

    var body: some View {
        Image(icon.rawValue)
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}
