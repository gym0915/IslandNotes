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

@MainActor
func selectMoreMenuItem(
    _ title: String,
    in app: XCUIApplication,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let moreButton = app.buttons["open-more-menu"]
    XCTAssertTrue(moreButton.waitForExistence(timeout: 5), file: file, line: line)
    moreButton.tap()

    let index: Int
    switch title {
    case "Note Library":
        index = 0
    case "Settings":
        index = 1
    default:
        XCTFail("Unsupported Workbench menu item: \(title)", file: file, line: line)
        return
    }

    let item = app.cells.element(boundBy: index)
    XCTAssertTrue(item.waitForExistence(timeout: 3), file: file, line: line)
    item.tap()
}
