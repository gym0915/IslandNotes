import UIKit
import XCTest
@testable import IslandNotes

final class DesignSystemTests: XCTestCase {
    func testEveryProductIconHasAStableAssetName() {
        let expectedAssetNames: [AppIcon: String] = [
            .more: "lucide-ellipsis",
            .noteLibrary: "lucide-library",
            .settings: "lucide-settings",
            .close: "lucide-x",
            .moveToLibrary: "lucide-archive",
            .live: "lucide-radio",
            .delete: "lucide-trash-2",
            .replace: "lucide-replace",
            .appearance: "lucide-monitor",
            .light: "lucide-sun",
            .dark: "lucide-moon",
            .feedback: "lucide-message-circle",
            .website: "lucide-globe",
            .about: "lucide-info",
            .check: "lucide-check",
            .noteBrand: "lucide-notebook-text",
        ]

        XCTAssertEqual(Set(expectedAssetNames.keys), Set(AppIcon.allCases))
        for (icon, expectedAssetName) in expectedAssetNames {
            XCTAssertEqual(icon.assetName, expectedAssetName)
        }
    }

    func testEveryProductIconLoadsFromTheCompiledAssetCatalog() {
        for icon in AppIcon.allCases {
            XCTAssertNotNil(UIImage(named: icon.assetName), icon.assetName)
        }
    }

    func testAutomaticAppearanceUsesTheAppearanceIcon() {
        XCTAssertEqual(AppIcon.automatic, .appearance)
        XCTAssertEqual(AppIcon.automatic.assetName, "lucide-monitor")
    }

    func testActionsExposeStableEnglishSemanticValues() {
        XCTAssertEqual(IslandActionKind.primary.accessibilityValue, "Primary")
        XCTAssertEqual(IslandActionKind.neutral.accessibilityValue, "Neutral")
        XCTAssertEqual(IslandActionKind.live.accessibilityValue, "Live")
        XCTAssertEqual(IslandActionKind.destructive.accessibilityValue, "Destructive")
    }

    func testNormativeSpacingScaleContainsOnlyApprovedValues() {
        XCTAssertEqual(
            [
                IslandDesign.Spacing.x1,
                IslandDesign.Spacing.x2,
                IslandDesign.Spacing.x4,
                IslandDesign.Spacing.x6,
                IslandDesign.Spacing.x8,
            ],
            [4, 8, 16, 24, 32]
        )
    }

    func testNormativeRadiusScaleContainsOnlyApprovedValues() {
        XCTAssertEqual(
            [
                IslandDesign.Radius.compact,
                IslandDesign.Radius.card,
                IslandDesign.Radius.sheet,
                IslandDesign.Radius.pill,
            ],
            [14, 22, 34, 1_000]
        )
    }

    func testMotionDurationsRemainWithinNormativeRange() {
        let durations = [
            IslandDesign.Motion.quick,
            IslandDesign.Motion.standard,
            IslandDesign.Motion.deliberate,
        ]

        XCTAssertEqual(durations, [0.16, 0.18, 0.21])
        XCTAssertTrue(durations.allSatisfy { 0.16 ... 0.21 ~= $0 })
    }

    func testReduceMotionRemovesInteractiveScaleAndAnimation() {
        XCTAssertEqual(
            IslandDesign.Motion.interactiveScale(isPressed: true, reduceMotion: false),
            IslandDesign.Motion.pressedScale
        )
        XCTAssertEqual(
            IslandDesign.Motion.interactiveScale(isPressed: true, reduceMotion: true),
            1
        )
        XCTAssertNotNil(IslandDesign.Motion.animation(reduceMotion: false))
        XCTAssertNil(IslandDesign.Motion.animation(reduceMotion: true))
    }
}
