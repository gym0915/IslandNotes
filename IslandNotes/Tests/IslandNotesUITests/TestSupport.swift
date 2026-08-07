import XCTest

@MainActor
func beginWorkbenchEditing(
    in app: XCUIApplication,
    file: StaticString = #filePath,
    line: UInt = #line
) -> XCUIElement {
    let renderedNote = app.buttons["rendered-note"]
    XCTAssertTrue(renderedNote.waitForExistence(timeout: 5), file: file, line: line)
    XCTAssertFalse(app.textViews["current-note-editor"].exists, file: file, line: line)
    renderedNote.tap()

    let editor = app.textViews["current-note-editor"]
    XCTAssertTrue(editor.waitForExistence(timeout: 2), file: file, line: line)
    return editor
}

@MainActor
func makeHittable(
    _ element: XCUIElement,
    in scrollView: XCUIElement,
    maximumSwipes: Int = 8,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertTrue(element.waitForExistence(timeout: 5), file: file, line: line)
    for _ in 0 ..< maximumSwipes where !element.isHittable {
        scrollView.swipeUp()
    }
    XCTAssertTrue(element.isHittable, file: file, line: line)
}
