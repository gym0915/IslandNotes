import XCTest
@testable import IslandNotes

final class DeepLinkRoutingTests: XCTestCase {
    func testExpiredNoteIDStillRoutesOnlyToWorkbench() throws {
        let url = try XCTUnwrap(URL(string: "islandnotes://workbench?noteID=expired"))

        XCTAssertEqual(DeepLinkRouter.destination(for: url), .workbench)
    }

    func testUnknownHostIsIgnored() throws {
        let url = try XCTUnwrap(URL(string: "islandnotes://library?noteID=expired"))

        XCTAssertNil(DeepLinkRouter.destination(for: url))
    }
}
