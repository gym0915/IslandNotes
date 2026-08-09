import XCTest

@MainActor
final class IslandNotesUITests: XCTestCase {
    private func launchCleanApp() -> XCUIApplication {
        launchApp(
            appearanceSuite: "IslandNotesUITests.clean",
            resetsAppearance: true
        )
    }

    private func launchApp(
        appearanceSuite: String,
        resetsAppearance: Bool
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--uitesting-reset",
            "--uitesting-fake-live-activity",
            "--uitesting-appearance-suite",
            appearanceSuite,
        ]
        if resetsAppearance {
            app.launchArguments.append("--uitesting-reset-appearance")
        }
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
        let library = app.buttons["open-note-library"]
        let settings = app.buttons["open-settings"]
        XCTAssertTrue(library.exists)
        XCTAssertTrue(settings.exists)
        XCTAssertEqual(library.value as? String, "Opens Note Library")
        XCTAssertEqual(settings.value as? String, "Opens Settings")
        XCTAssertGreaterThanOrEqual(library.frame.height, 44)
        XCTAssertGreaterThanOrEqual(settings.frame.height, 44)

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
        let title = app.staticTexts["sheet-title"]
        XCTAssertTrue(title.exists)
        XCTAssertEqual(title.label, "Note Library")
        let closeButton = app.buttons["close-sheet"]
        XCTAssertGreaterThanOrEqual(closeButton.frame.height, 44)
        closeButton.tap()

        XCTAssertTrue(app.scrollViews["workbench-root"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.otherElements["app-sheet"].exists)
    }

    func testSettingsUsesPrototypeAppearanceAndSupportGroups() {
        let app = launchCleanApp()

        openSettings(in: app)

        XCTAssertTrue(app.otherElements["app-sheet"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Settings"].exists)
        XCTAssertTrue(app.staticTexts["Appearance"].exists)
        XCTAssertTrue(app.staticTexts["Support"].exists)
        XCTAssertEqual(app.buttons["display-mode-menu"].value as? String, "Automatic")
        XCTAssertTrue(app.buttons["settings-feedback"].exists)
        XCTAssertTrue(app.buttons["settings-website"].exists)
        XCTAssertTrue(app.buttons["settings-about"].exists)
        XCTAssertFalse(app.staticTexts["Privacy"].exists)
        XCTAssertGreaterThanOrEqual(app.buttons["close-sheet"].frame.height, 44)

        for identifier in ["settings-feedback", "settings-website", "settings-about"] {
            app.buttons[identifier].tap()
            XCTAssertTrue(app.otherElements["app-sheet"].exists)
            XCTAssertTrue(settingsContent(in: app).exists)
        }
    }

    func testSettingsSelectsAutomaticLightAndDarkWithImmediateSheetSemantics() {
        let app = launchCleanApp()
        openSettings(in: app)

        selectAppearance("Dark", in: app)
        XCTAssertEqual(settingsContent(in: app).value as? String, "Dark")

        selectAppearance("Light", in: app)
        XCTAssertEqual(settingsContent(in: app).value as? String, "Light")

        selectAppearance("Automatic", in: app)
        XCTAssertEqual(settingsContent(in: app).value as? String, "Automatic")
    }

    func testAppearanceSelectionPersistsAfterTerminationAndRelaunch() {
        let suite = "IslandNotesUITests.persistence.\(UUID().uuidString)"
        var app = launchApp(appearanceSuite: suite, resetsAppearance: true)
        openSettings(in: app)
        selectAppearance("Dark", in: app)
        app.terminate()

        app = launchApp(appearanceSuite: suite, resetsAppearance: false)
        openSettings(in: app)

        XCTAssertEqual(app.buttons["display-mode-menu"].value as? String, "Dark")
        XCTAssertEqual(settingsContent(in: app).value as? String, "Dark")
    }

    func testEmptyWorkbenchExposesDisplaySurfaceLibraryAndDisabledActions() {
        let app = launchCleanApp()

        let productTitle = app.staticTexts["Island Notes"]
        XCTAssertTrue(productTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Not Live"].exists)
        XCTAssertTrue(app.buttons["rendered-note"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textViews["current-note-editor"].exists)
        let moreButton = app.buttons["open-more-menu"]
        XCTAssertTrue(moreButton.exists)
        XCTAssertFalse(productTitle.frame.intersects(moreButton.frame))
        XCTAssertFalse(app.buttons["archive-current-note"].isEnabled)
        XCTAssertFalse(app.buttons["toggle-pin"].isEnabled)
        XCTAssertFalse(app.buttons["delete-current-note"].isEnabled)

        let progress = app.buttons["character-progress"]
        XCTAssertGreaterThanOrEqual(progress.frame.width, 44)
        XCTAssertGreaterThanOrEqual(progress.frame.height, 44)
        XCTAssertEqual(progress.value as? String, "0 used, 240 remaining")
    }

    func testTappingDisplaySurfaceOpensExactSourceEditorAndDoneAction() {
        let app = launchCleanApp()

        let editor = beginWorkbenchEditing(in: app)

        XCTAssertTrue(editor.exists)
        XCTAssertFalse(app.buttons["rendered-note"].exists)
        XCTAssertTrue(app.buttons["done-editing"].exists)
        XCTAssertFalse(app.staticTexts["Write what matters most…"].exists)
    }

    func testEditorProgressDoneAndActionsRemainHittableAtMaximumDynamicType() {
        let app = XCUIApplication()
        app.launchArguments = [
            "--uitesting-reset",
            "--uitesting-fake-live-activity",
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge",
        ]
        app.launch()

        let workbench = app.scrollViews["workbench-root"]
        let productTitle = app.staticTexts["Island Notes"]
        let moreButton = app.buttons["open-more-menu"]
        XCTAssertTrue(productTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(moreButton.isHittable)
        XCTAssertFalse(productTitle.frame.intersects(moreButton.frame))

        let renderedNote = app.buttons["rendered-note"]
        makeHittable(renderedNote, in: workbench)
        renderedNote.tap()

        let editor = app.textViews["current-note-editor"]
        makeHittable(editor, in: workbench)
        editor.tap()
        editor.typeText("Maximum Dynamic Type")

        let characterProgress = app.buttons["character-progress"]
        makeHittable(characterProgress, in: workbench)
        characterProgress.tap()
        XCTAssertEqual(characterProgress.value as? String, "20 used, 220 remaining")
        XCTAssertFalse(app.descendants(matching: .any)["character-progress-detail"].exists)

        let done = app.buttons["done-editing"]
        makeHittable(done, in: workbench)
        done.tap()
        XCTAssertTrue(renderedNote.waitForExistence(timeout: 3))

        for identifier in ["archive-current-note", "toggle-pin", "delete-current-note"] {
            makeHittable(app.buttons[identifier], in: workbench)
        }
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
        let toggleLive = app.buttons["toggle-pin"]
        XCTAssertTrue(toggleLive.isEnabled)

        delete.tap()

        XCTAssertTrue(app.alerts["Delete this note?"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["This cannot be undone."].exists)
        XCTAssertTrue(app.buttons["Cancel"].exists)
        XCTAssertTrue(app.buttons["Delete Note"].exists)
    }

    func testDeterministicUITestLiveTransitionUpdatesHeaderAndRemainsStoppable() {
        let app = launchCleanApp()
        let editor = beginWorkbenchEditing(in: app)
        editor.typeText("A deterministic Live note")
        app.buttons["done-editing"].tap()

        let toggleLive = app.buttons["toggle-pin"]
        XCTAssertTrue(toggleLive.waitForExistence(timeout: 3))
        toggleLive.tap()

        let liveAction = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Live"),
            object: toggleLive
        )
        XCTAssertEqual(XCTWaiter.wait(for: [liveAction], timeout: 3), .completed)
        XCTAssertTrue(app.staticTexts["Live"].firstMatch.exists)

        toggleLive.tap()
        let goLiveAction = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Go Live"),
            object: toggleLive
        )
        XCTAssertEqual(XCTWaiter.wait(for: [goLiveAction], timeout: 3), .completed)
        XCTAssertTrue(app.staticTexts["Not Live"].exists)
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
        let archivedNote = app.staticTexts["Old note from library"]
        XCTAssertTrue(archivedNote.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["RECENT"].exists)
        let replace = app.buttons["Replace current note"]
        XCTAssertTrue(replace.exists)
        XCTAssertGreaterThanOrEqual(replace.frame.width, 44)
        XCTAssertGreaterThanOrEqual(replace.frame.height, 44)

        archivedNote.tap()
        XCTAssertTrue(app.otherElements["app-sheet"].exists)

        replace.tap()
        XCTAssertTrue(app.buttons["rendered-note"].waitForExistence(timeout: 3))
        XCTAssertFalse(editor.exists)
        XCTAssertTrue(app.buttons["rendered-note"].label.contains("Old note from library"))
    }

    func testLibraryReplacementArchivesCommittedOutgoingNoteAndDiscardsLivingDraft() {
        let app = launchCleanApp()

        let candidateEditor = beginWorkbenchEditing(in: app)
        candidateEditor.typeText("Library candidate")
        app.buttons["done-editing"].tap()
        app.buttons["archive-current-note"].tap()

        let outgoingEditor = beginWorkbenchEditing(in: app)
        outgoingEditor.typeText("Outgoing committed")
        app.buttons["done-editing"].tap()

        app.buttons["rendered-note"].tap()
        let livingDraft = app.textViews["current-note-editor"]
        XCTAssertTrue(livingDraft.waitForExistence(timeout: 2))
        livingDraft.typeText(" unsaved")

        app.buttons["open-more-menu"].tap()
        app.buttons["open-note-library"].tap()
        XCTAssertTrue(app.staticTexts["Library candidate"].waitForExistence(timeout: 3))
        app.buttons["Replace current note"].tap()

        let rendered = app.buttons["rendered-note"]
        XCTAssertTrue(rendered.waitForExistence(timeout: 3))
        XCTAssertTrue(rendered.label.contains("Library candidate"))
        XCTAssertFalse(livingDraft.exists)

        app.buttons["open-more-menu"].tap()
        app.buttons["open-note-library"].tap()
        XCTAssertTrue(app.staticTexts["Outgoing committed"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["Outgoing committed unsaved"].exists)
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
        XCTAssertFalse(app.descendants(matching: .any)["character-progress-detail"].exists)
        XCTAssertFalse(app.staticTexts["240 used · 0 remaining"].exists)
        XCTAssertEqual(
            app.buttons["character-progress"].value as? String,
            "240 used, 0 remaining"
        )
        XCTAssertEqual(
            app.buttons["character-progress"].label,
            "Character limit reached"
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
        let feedback = app.descendants(matching: .any)["transient-feedback"]
        XCTAssertTrue(feedback.waitForExistence(timeout: 2))
        XCTAssertEqual(feedback.label, "Recoverable message")
        XCTAssertEqual(feedback.value as? String, "Your note hasn't been saved.")
    }

    private func openSettings(in app: XCUIApplication) {
        XCTAssertTrue(app.buttons["open-more-menu"].waitForExistence(timeout: 5))
        app.buttons["open-more-menu"].tap()
        app.buttons["open-settings"].tap()
        XCTAssertTrue(settingsContent(in: app).waitForExistence(timeout: 3))
    }

    private func selectAppearance(_ title: String, in app: XCUIApplication) {
        let menu = app.buttons["display-mode-menu"]
        XCTAssertTrue(menu.waitForExistence(timeout: 2))
        menu.tap()

        let option = app.buttons["appearance-mode-\(title.lowercased())"]
        XCTAssertTrue(option.waitForExistence(timeout: 2))
        option.tap()

        let selected = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", title),
            object: menu
        )
        XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 3), .completed)
    }

    private func settingsContent(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)["settings-content"]
    }
}
