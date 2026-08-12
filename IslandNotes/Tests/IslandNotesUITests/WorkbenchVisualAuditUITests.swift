import XCTest

@MainActor
final class WorkbenchVisualAuditUITests: XCTestCase {
    func testCaptureLightWorkbenchFlow() {
        let app = launchAuditApp(suite: "WorkbenchVisualAudit.light")
        selectAppearance("Light", in: app)

        capture("01-empty-light")
        let editor = beginWorkbenchEditing(in: app)
        editor.typeText("- Review the product brief\n- Send the build notes to Maya\n- Book the 4:30 train")
        app.buttons["character-progress"].tap()
        let characterDetail = app.staticTexts["79 used · 161 remaining"]
        XCTAssertTrue(characterDetail.waitForExistence(timeout: 2))
        capture("05-editing-light")
        capture("11-character-count")

        app.buttons["done-editing"].tap()
        XCTAssertTrue(app.renderedNote.waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["character-progress"].exists)
        capture("03-note-light")
        capture("07-go-live-light")

        let live = app.buttons["toggle-pin"]
        live.tap()
        waitForLabel("Live", on: live)
        capture("09-live-light")
        waitForAlternateBreathingPhase()
        capture("14-live-light-breathing-phase")

        app.buttons["delete-current-note"].tap()
        XCTAssertTrue(
            app.otherElements["delete-confirmation"].waitForExistence(timeout: 3)
        )
        capture("12-delete-confirmation")
    }

    func testCaptureDarkWorkbenchFlow() {
        let app = launchAuditApp(suite: "WorkbenchVisualAudit.dark")
        selectAppearance("Dark", in: app)

        capture("02-empty-dark")
        let editor = beginWorkbenchEditing(in: app)
        editor.typeText("- Review the product brief\n- Send the build notes to Maya\n- Book the 4:30 train")
        capture("06-editing-dark")

        app.buttons["done-editing"].tap()
        XCTAssertTrue(app.renderedNote.waitForExistence(timeout: 3))
        capture("04-note-dark")
        capture("08-go-live-dark")

        let live = app.buttons["toggle-pin"]
        live.tap()
        waitForLabel("Live", on: live)
        capture("10-live-dark")
    }

    func testCaptureAccessibilityXXXLWorkbench() {
        let app = launchAuditApp(
            suite: "WorkbenchVisualAudit.accessibility-xxxl",
            accessibilityXXXL: true
        )
        let editor = beginWorkbenchEditing(in: app)
        editor.typeText("Maximum Dynamic Type")
        app.buttons["done-editing"].tap()

        let delete = app.buttons["delete-current-note"]
        XCTAssertTrue(delete.waitForExistence(timeout: 3))
        XCTAssertTrue(delete.isHittable)
        capture("13-accessibility-xxxl")
    }

    func testCaptureLiquidGlassButtonSurfaces() {
        let app = launchAuditApp(suite: "WorkbenchVisualAudit.liquid-glass")
        selectAppearance("Light", in: app)

        app.buttons["open-more-menu"].tap()
        XCTAssertTrue(app.otherElements["more-menu"].waitForExistence(timeout: 3))
        capture("15-more-menu-glass")

        app.buttons["open-settings"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["settings-content"]
                .waitForExistence(timeout: 3)
        )
        capture("16-settings-buttons-glass")
        app.buttons["close-sheet"].tap()

        let editor = beginWorkbenchEditing(in: app)
        editor.typeText("A note for the glass library button")
        app.buttons["done-editing"].tap()
        let move = app.buttons["archive-current-note"]
        XCTAssertTrue(move.waitForExistence(timeout: 3))
        move.tap()

        app.buttons["open-more-menu"].tap()
        app.buttons["open-note-library"].tap()
        XCTAssertTrue(app.buttons["Replace current note"].waitForExistence(timeout: 3))
        capture("17-note-library-buttons-glass")
    }

    private func launchAuditApp(
        suite: String,
        accessibilityXXXL: Bool = false
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--uitesting-reset",
            "--uitesting-fake-live-activity",
            "--uitesting-appearance-suite",
            suite,
            "--uitesting-reset-appearance",
        ]
        if accessibilityXXXL {
            app.launchArguments += [
                "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
            ]
        }
        app.launch()
        XCTAssertTrue(app.renderedNote.waitForExistence(timeout: 5))
        return app
    }

    private func selectAppearance(_ title: String, in app: XCUIApplication) {
        app.buttons["open-more-menu"].tap()
        app.buttons["open-settings"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["settings-content"]
                .waitForExistence(timeout: 3)
        )

        app.buttons["display-mode-menu"].tap()
        let option = app.buttons["appearance-mode-\(title.lowercased())"]
        XCTAssertTrue(option.waitForExistence(timeout: 3))
        option.tap()

        let selected = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", title),
            object: app.buttons["display-mode-menu"]
        )
        XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 3), .completed)
        app.buttons["close-sheet"].tap()
        XCTAssertTrue(app.renderedNote.waitForExistence(timeout: 3))
    }

    private func waitForLabel(_ label: String, on element: XCUIElement) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", label),
            object: element
        )
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 3), .completed)
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func waitForAlternateBreathingPhase() {
        let phase = expectation(description: "Live indicator reaches an alternate breathing phase")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            phase.fulfill()
        }
        wait(for: [phase], timeout: 1)
    }
}
