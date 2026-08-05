import XCTest
@testable import IslandNotes

final class LiveActivityPresentationTests: XCTestCase {
    private let state = IslandNoteActivityAttributes.ContentState(
        body: "Only visible when the surface has enough room",
        version: 7
    )

    func testCompactAndMinimalRegionsDoNotExposeNoteBody() {
        for region in [
            LiveActivityRegion.compactLeading,
            .compactTrailing,
            .minimal,
        ] {
            XCTAssertNil(LiveActivityPresentationModel.presentation(for: region, state: state).body)
        }
    }

    func testExpandedAndLockScreenUseTheSameCurrentBody() {
        let expanded = LiveActivityPresentationModel.presentation(for: .expanded, state: state)
        let lockScreen = LiveActivityPresentationModel.presentation(for: .lockScreen, state: state)

        XCTAssertEqual(expanded.body, state.body)
        XCTAssertEqual(lockScreen.body, state.body)
    }

    func testEveryRegionUsesTheWorkbenchDeepLink() {
        for region in LiveActivityRegion.allCases {
            XCTAssertEqual(
                LiveActivityPresentationModel.presentation(for: region, state: state).destination,
                URL(string: "islandnotes://workbench")
            )
        }
    }
}
