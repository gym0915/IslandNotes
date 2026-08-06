import XCTest
@testable import IslandNotes

@MainActor
final class AppRouterTests: XCTestCase {
    func testPresentNoteLibraryMakesItTheActiveSheet() {
        let router = AppRouter()

        router.presentNoteLibrary()

        XCTAssertEqual(router.presentedSheet, .noteLibrary)
    }

    func testPresentSettingsReplacesTheActiveSheet() {
        let router = AppRouter()
        router.presentNoteLibrary()

        router.presentSettings()

        XCTAssertEqual(router.presentedSheet, .settings)
    }

    func testDismissReturnsToWorkbench() {
        let router = AppRouter()
        router.presentSettings()

        router.dismissSheet()

        XCTAssertNil(router.presentedSheet)
    }

    func testValidWorkbenchDeepLinkDismissesTheActiveSheet() throws {
        let router = AppRouter()
        router.presentNoteLibrary()
        let url = try XCTUnwrap(URL(string: "islandnotes://workbench?noteID=current"))

        XCTAssertTrue(router.handleDeepLink(url))

        XCTAssertNil(router.presentedSheet)
    }

    func testInvalidDeepLinkLeavesTheActiveSheetUnchanged() throws {
        let router = AppRouter()
        router.presentSettings()
        let url = try XCTUnwrap(URL(string: "islandnotes://library"))

        XCTAssertFalse(router.handleDeepLink(url))

        XCTAssertEqual(router.presentedSheet, .settings)
    }
}
