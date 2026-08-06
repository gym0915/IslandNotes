import SwiftUI
import XCTest
@testable import IslandNotes

@MainActor
final class AppearanceSettingsTests: XCTestCase {
    func testDefaultsToAutomaticWhenNothingHasBeenStored() {
        withDefaults { defaults in
            XCTAssertEqual(AppearanceSettings(defaults: defaults).mode, .automatic)
        }
    }

    func testLoadsEveryStoredAppearanceMode() {
        withDefaults { defaults in
            for mode in AppearanceMode.allCases {
                defaults.set(mode.rawValue, forKey: "appearance-mode")

                XCTAssertEqual(AppearanceSettings(defaults: defaults).mode, mode)
            }
        }
    }

    func testInvalidStoredAppearanceModeFallsBackToAutomatic() {
        withDefaults { defaults in
            defaults.set("sepia", forKey: "appearance-mode")

            XCTAssertEqual(AppearanceSettings(defaults: defaults).mode, .automatic)
        }
    }

    func testSelectionPersistsAcrossInstances() {
        withDefaults { defaults in
            let settings = AppearanceSettings(defaults: defaults)

            settings.select(.dark)

            XCTAssertEqual(settings.mode, .dark)
            XCTAssertEqual(AppearanceSettings(defaults: defaults).mode, .dark)
        }
    }

    func testAppearanceModesHaveStableEnglishTitles() {
        XCTAssertEqual(AppearanceMode.automatic.title, "Automatic")
        XCTAssertEqual(AppearanceMode.light.title, "Light")
        XCTAssertEqual(AppearanceMode.dark.title, "Dark")
    }

    func testColorSchemeMapping() {
        XCTAssertNil(AppearanceMode.automatic.colorScheme)
        XCTAssertEqual(AppearanceMode.light.colorScheme, .light)
        XCTAssertEqual(AppearanceMode.dark.colorScheme, .dark)
    }

    private func withDefaults(
        _ operation: (UserDefaults) throws -> Void
    ) rethrows {
        let suiteName = "AppearanceSettingsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        try operation(defaults)
    }
}
