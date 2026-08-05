import XCTest
@testable import IslandNotes

@MainActor
final class ActivityKitControllerContractTests: XCTestCase {
    func testProductionControllerConformsToLiveActivityBoundary() {
        let controller: any LiveActivityControlling = ActivityKitLiveActivityController()
        XCTAssertNotNil(controller)
    }
}
