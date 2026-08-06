import XCTest

@MainActor
final class DeepLinkUITests: XCTestCase {
    func testExpiredDeepLinkColdLaunchConvergesOnCurrentWorkbench() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--uitesting-reset",
            "--uitesting-open-url",
            "islandnotes://workbench?noteID=expired",
        ]
        app.launch()

        XCTAssertTrue(app.scrollViews["workbench-root"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["rendered-note"].exists)
        XCTAssertFalse(app.textViews["current-note-editor"].exists)
        XCTAssertFalse(app.buttons["toggle-pin"].isEnabled)
    }

    func testMaximumDynamicTypeKeepsEditorAndActionsReachable() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--uitesting-reset",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
        ]
        app.launch()

        XCTAssertTrue(app.buttons["rendered-note"].waitForExistence(timeout: 5))
        app.buttons["rendered-note"].tap()
        let editor = app.textViews["current-note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 2))
        editor.typeText("最大字号也能操作")
        app.buttons["done-editing"].tap()

        let archive = app.buttons["archive-current-note"]
        XCTAssertTrue(archive.waitForExistence(timeout: 3))
        XCTAssertGreaterThanOrEqual(archive.frame.height, 44)
        XCTAssertTrue(app.buttons["toggle-pin"].exists)
        XCTAssertTrue(app.buttons["delete-current-note"].exists)
    }

    func testPrimaryControlsExposeMeaningfulAccessibilityLabels() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-reset"]
        app.launch()

        XCTAssertTrue(app.buttons["rendered-note"].waitForExistence(timeout: 5))
        app.buttons["rendered-note"].tap()
        XCTAssertTrue(app.textViews["current-note-editor"].waitForExistence(timeout: 2))
        XCTAssertEqual(app.textViews["current-note-editor"].label, "Current note")
        XCTAssertEqual(app.buttons["open-more-menu"].label, "More")
        XCTAssertEqual(app.buttons["character-progress"].label, "Character count")
        XCTAssertGreaterThanOrEqual(app.buttons["character-progress"].frame.width, 44)
        XCTAssertGreaterThanOrEqual(app.buttons["character-progress"].frame.height, 44)
    }

    func testSimulatorActivityKitStartUpdateAndEndChain() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-reset"]
        app.launch()

        XCTAssertTrue(app.buttons["rendered-note"].waitForExistence(timeout: 5))
        app.buttons["rendered-note"].tap()
        let editor = app.textViews["current-note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 2))
        editor.typeText("Simulator live activity")
        app.buttons["done-editing"].tap()

        let toggle = app.buttons["toggle-pin"]
        let enabled = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isEnabled == true"),
            object: toggle
        )
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 3), .completed)
        toggle.tap()

        let pinned = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Live"),
            object: toggle
        )
        XCTAssertEqual(XCTWaiter.wait(for: [pinned], timeout: 5), .completed)

        app.buttons["rendered-note"].tap()
        XCTAssertTrue(editor.waitForExistence(timeout: 2))
        editor.typeText(" updated")
        XCTAssertEqual(editor.value as? String, "Simulator live activity updated")
        app.buttons["done-editing"].tap()

        toggle.tap()
        let unpinned = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Go Live"),
            object: toggle
        )
        XCTAssertEqual(XCTWaiter.wait(for: [unpinned], timeout: 5), .completed)
        XCTAssertFalse(app.descendants(matching: .any)["transient-feedback"].exists)
    }
}
