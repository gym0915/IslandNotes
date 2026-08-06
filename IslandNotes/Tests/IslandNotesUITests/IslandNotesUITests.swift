import XCTest

@MainActor
final class IslandNotesUITests: XCTestCase {
    private func launchCleanApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-reset"]
        app.launch()
        return app
    }

    func testMoreMenuShowsOnlyTopLevelDestinationsAndDismissesOutside() {
        let app = launchCleanApp()

        XCTAssertTrue(app.staticTexts["Island Notes"].waitForExistence(timeout: 5))
        let moreButton = app.buttons["open-more-menu"]
        XCTAssertTrue(moreButton.exists)
        moreButton.tap()

        let menu = app.otherElements["more-menu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 2))
        XCTAssertEqual(menu.buttons.count, 2)
        XCTAssertTrue(app.buttons["open-note-library"].exists)
        XCTAssertTrue(app.buttons["open-settings"].exists)

        app.scrollViews["workbench-root"]
            .coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.9))
            .tap()

        XCTAssertFalse(menu.exists)
    }

    func testViewingEditingAndDoneRendersOnlyExactBulletLines() {
        let app = launchCleanApp()
        let renderedNote = app.buttons["rendered-note"]

        let editor = beginWorkbenchEditing(in: app)
        XCTAssertEqual(editor.value as? String, "")
        editor.typeText("Plain line\n- Bullet line\n# literal heading\n* literal star")
        app.buttons["done-editing"].tap()

        XCTAssertTrue(renderedNote.waitForExistence(timeout: 3))
        XCTAssertFalse(editor.exists)
        XCTAssertTrue(app.staticTexts["Plain line"].exists)
        let bullet = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "Bullet, Bullet line"))
            .firstMatch
        XCTAssertTrue(bullet.exists)
        XCTAssertTrue(app.staticTexts["# literal heading"].exists)
        XCTAssertTrue(app.staticTexts["* literal star"].exists)
    }

    func testNoteLibraryUsesTheSharedSheetAndCloseReturnsToWorkbench() {
        let app = launchCleanApp()

        XCTAssertTrue(app.buttons["open-more-menu"].waitForExistence(timeout: 5))
        app.buttons["open-more-menu"].tap()
        app.buttons["open-note-library"].tap()

        XCTAssertTrue(app.otherElements["app-sheet"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Note Library"].exists)
        let closeButton = app.buttons["close-sheet"]
        XCTAssertGreaterThanOrEqual(closeButton.frame.height, 44)
        closeButton.tap()

        XCTAssertTrue(app.scrollViews["workbench-root"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.otherElements["app-sheet"].exists)
    }

    func testSettingsUsesTheSharedSheetWithTransitionalContent() {
        let app = launchCleanApp()

        XCTAssertTrue(app.buttons["open-more-menu"].waitForExistence(timeout: 5))
        app.buttons["open-more-menu"].tap()
        app.buttons["open-settings"].tap()

        XCTAssertTrue(app.otherElements["app-sheet"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Settings"].exists)
        XCTAssertTrue(app.staticTexts["Appearance settings are coming in a later update."].exists)
        XCTAssertGreaterThanOrEqual(app.buttons["close-sheet"].frame.height, 44)
    }

    func testEmptyWorkbenchExposesDisplaySurfaceLibraryAndDisabledActions() {
        let app = launchCleanApp()

        XCTAssertTrue(app.buttons["rendered-note"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textViews["current-note-editor"].exists)
        XCTAssertTrue(app.buttons["open-more-menu"].exists)
        XCTAssertFalse(app.buttons["archive-current-note"].isEnabled)
        XCTAssertFalse(app.buttons["toggle-pin"].isEnabled)
        XCTAssertFalse(app.buttons["delete-current-note"].isEnabled)
    }

    func testEditingEnablesActionsAndDeleteShowsIrreversibleConfirmation() {
        let app = launchCleanApp()
        let editor = beginWorkbenchEditing(in: app)

        editor.typeText("A note to keep")

        XCTAssertFalse(app.buttons["delete-current-note"].isEnabled)
        app.buttons["done-editing"].tap()

        let delete = app.buttons["delete-current-note"]
        let enabled = NSPredicate(format: "isEnabled == true")
        let enabledExpectation = XCTNSPredicateExpectation(predicate: enabled, object: delete)
        XCTAssertEqual(XCTWaiter.wait(for: [enabledExpectation], timeout: 3), .completed)
        XCTAssertTrue(app.buttons["archive-current-note"].isEnabled)
        XCTAssertTrue(app.buttons["toggle-pin"].isEnabled)

        delete.tap()

        XCTAssertTrue(app.alerts["Delete this note?"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["This cannot be undone."].exists)
        XCTAssertTrue(app.buttons["Cancel"].exists)
        XCTAssertTrue(app.buttons["Delete Note"].exists)
    }

    func testLibraryIsReachableWhenEmpty() {
        let app = launchCleanApp()
        XCTAssertTrue(app.buttons["open-more-menu"].waitForExistence(timeout: 5))

        app.buttons["open-more-menu"].tap()
        app.buttons["open-note-library"].tap()

        XCTAssertTrue(app.staticTexts["No notes yet"].waitForExistence(timeout: 3))
    }

    func testArchivingAndSelectingLibraryNoteReturnsItToWorkbench() {
        let app = launchCleanApp()
        let editor = beginWorkbenchEditing(in: app)
        editor.typeText("Old note from library")
        app.buttons["done-editing"].tap()

        let archive = app.buttons["archive-current-note"]
        let enabled = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isEnabled == true"),
            object: archive
        )
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 3), .completed)
        archive.tap()

        XCTAssertTrue(app.buttons["open-more-menu"].waitForExistence(timeout: 3))
        app.buttons["open-more-menu"].tap()
        app.buttons["open-note-library"].tap()
        let archivedNote = app.buttons["Note: Old note from library"]
        XCTAssertTrue(archivedNote.waitForExistence(timeout: 3))

        archivedNote.tap()

        XCTAssertTrue(app.buttons["rendered-note"].waitForExistence(timeout: 3))
        XCTAssertFalse(editor.exists)
        XCTAssertTrue(app.buttons["rendered-note"].label.contains("Old note from library"))
    }

    func testDraftSurvivesOpeningAndClosingNoteLibrary() {
        let app = launchCleanApp()
        let editor = beginWorkbenchEditing(in: app)
        editor.typeText("Draft across a sheet")

        app.buttons["open-more-menu"].tap()
        app.buttons["open-note-library"].tap()
        XCTAssertTrue(app.otherElements["app-sheet"].waitForExistence(timeout: 3))
        app.buttons["close-sheet"].tap()

        XCTAssertTrue(editor.waitForExistence(timeout: 3))
        XCTAssertEqual(editor.value as? String, "Draft across a sheet")
        XCTAssertFalse(app.buttons["archive-current-note"].isEnabled)
    }

    func testDraftSurvivesOrdinaryBackgroundAndResume() {
        let app = launchCleanApp()
        let editor = beginWorkbenchEditing(in: app)
        editor.typeText("Draft after background")

        XCUIDevice.shared.press(.home)
        app.activate()

        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        XCTAssertEqual(editor.value as? String, "Draft after background")
    }

    func testEditingStopsAt240CharactersAndRingShowsDraftCount() {
        let app = launchCleanApp()
        let editor = beginWorkbenchEditing(in: app)

        editor.typeText(String(repeating: "A", count: 241))

        XCTAssertEqual((editor.value as? String)?.count, 240)
        app.buttons["character-progress"].tap()
        XCTAssertTrue(
            app.descendants(matching: .any)["character-progress-detail"]
                .waitForExistence(timeout: 2)
        )
        XCTAssertEqual(
            app.buttons["character-progress"].value as? String,
            "240 used, 0 remaining"
        )
    }

    func testFailedDoneKeepsEditorDraftAndShowsSaveFeedback() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-reset", "--uitesting-save-failure"]
        app.launch()
        let renderedNote = app.buttons["rendered-note"]
        XCTAssertTrue(renderedNote.waitForExistence(timeout: 5))
        XCTAssertTrue(renderedNote.label.contains("Last committed source"))
        let editor = beginWorkbenchEditing(in: app)

        editor.typeText(" + unsaved")
        app.buttons["done-editing"].tap()

        XCTAssertTrue(editor.waitForExistence(timeout: 3))
        XCTAssertEqual(editor.value as? String, "Last committed source + unsaved")
        XCTAssertFalse(renderedNote.exists)
        XCTAssertTrue(app.staticTexts["Your note hasn't been saved."].exists)
    }
}
