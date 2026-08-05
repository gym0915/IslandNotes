import XCTest

final class IslandNotesUITests: XCTestCase {
    private func launchCleanApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting-reset"]
        app.launch()
        return app
    }

    func testEmptyWorkbenchExposesEditorLibraryAndDisabledActions() {
        let app = launchCleanApp()

        XCTAssertTrue(app.textViews["current-note-editor"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["open-library"].exists)
        XCTAssertFalse(app.buttons["archive-current-note"].isEnabled)
        XCTAssertFalse(app.buttons["toggle-pin"].isEnabled)
        XCTAssertFalse(app.buttons["delete-current-note"].isEnabled)
    }

    func testEditingEnablesActionsAndDeleteShowsIrreversibleConfirmation() {
        let app = launchCleanApp()
        let editor = app.textViews["current-note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))

        editor.tap()
        editor.typeText("A note to keep")

        let delete = app.buttons["delete-current-note"]
        let enabled = NSPredicate(format: "isEnabled == true")
        let enabledExpectation = XCTNSPredicateExpectation(predicate: enabled, object: delete)
        XCTAssertEqual(XCTWaiter.wait(for: [enabledExpectation], timeout: 3), .completed)
        XCTAssertTrue(app.buttons["archive-current-note"].isEnabled)
        XCTAssertTrue(app.buttons["toggle-pin"].isEnabled)

        delete.tap()

        XCTAssertTrue(app.alerts["删除当前便签？"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["删除后无法恢复"].exists)
        XCTAssertTrue(app.buttons["取消"].exists)
        XCTAssertTrue(app.buttons["删除"].exists)
    }

    func testLibraryIsReachableWhenEmpty() {
        let app = launchCleanApp()
        XCTAssertTrue(app.buttons["open-library"].waitForExistence(timeout: 5))

        app.buttons["open-library"].tap()

        XCTAssertTrue(app.staticTexts["便签库还是空的"].waitForExistence(timeout: 3))
    }

    func testArchivingAndSelectingLibraryNoteReturnsItToWorkbench() {
        let app = launchCleanApp()
        let editor = app.textViews["current-note-editor"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText("Old note from library")

        let archive = app.buttons["archive-current-note"]
        let enabled = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isEnabled == true"),
            object: archive
        )
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 3), .completed)
        archive.tap()

        XCTAssertTrue(app.buttons["open-library"].waitForExistence(timeout: 3))
        app.buttons["open-library"].tap()
        let archivedNote = app.buttons["便签：Old note from library"]
        XCTAssertTrue(archivedNote.waitForExistence(timeout: 3))

        archivedNote.tap()

        XCTAssertTrue(editor.waitForExistence(timeout: 3))
        XCTAssertEqual(editor.value as? String, "Old note from library")
    }
}
