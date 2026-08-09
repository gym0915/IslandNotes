import Foundation
import Observation
import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable, Sendable {
    case automatic
    case light
    case dark

    var id: Self { self }

    var title: String {
        switch self {
        case .automatic: "Automatic"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

@MainActor
@Observable
final class AppearanceSettings {
    private static let storageKey = "appearance-mode"

    private let defaults: UserDefaults?
    private(set) var mode: AppearanceMode

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        mode = defaults.string(forKey: Self.storageKey)
            .flatMap(AppearanceMode.init(rawValue:)) ?? .automatic
    }

#if DEBUG
    init(previewMode: AppearanceMode) {
        defaults = nil
        mode = previewMode
    }
#endif

    func select(_ mode: AppearanceMode) {
        self.mode = mode
        defaults?.set(mode.rawValue, forKey: Self.storageKey)
    }
}
