import XCTest
@testable import IslandNotes

final class ProjectSmokeTests: XCTestCase {
    func testAppModuleIsAvailableToTheFunctionalTestTarget() {
        XCTAssertEqual(IslandNotesApp.minimumSupportedMajorVersion, 17)
    }
}
