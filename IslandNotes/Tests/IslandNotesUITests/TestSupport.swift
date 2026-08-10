import XCTest

@MainActor
extension XCUIApplication {
    var renderedNote: XCUIElement {
        descendants(matching: .any)["rendered-note"].firstMatch
    }
}

@MainActor
func beginWorkbenchEditing(
    in app: XCUIApplication,
    file: StaticString = #filePath,
    line: UInt = #line
) -> XCUIElement {
    let renderedNote = app.renderedNote
    XCTAssertTrue(renderedNote.waitForExistence(timeout: 5), file: file, line: line)
    XCTAssertFalse(app.textViews["current-note-editor"].exists, file: file, line: line)
    renderedNote.tap()

    let editor = app.textViews["current-note-editor"]
    XCTAssertTrue(editor.waitForExistence(timeout: 2), file: file, line: line)
    return editor
}
