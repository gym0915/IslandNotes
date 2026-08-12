import XCTest
@testable import IslandNotes

final class LiveActivityPresentationTests: XCTestCase {
    private let state = IslandNoteActivityAttributes.ContentState(
        body: "Review the product brief\n- Send the build notes to Maya\n# Heading stays literal",
        version: 7
    )

    func testCompactLeadingAndMinimalShowOnlyTheApprovedBrandMark() {
        for region in [LiveActivityRegion.compactLeading, .minimal] {
            let presentation = LiveActivityPresentationModel.presentation(for: region, state: state)

            XCTAssertEqual(presentation.brandMark, .notebookText)
            XCTAssertNil(presentation.body)
            XCTAssertNil(presentation.lineLimit)
            XCTAssertEqual(presentation.accessibilityLabel, "Island Notes")
        }
    }

    func testCompactTrailingIsEmpty() {
        let presentation = LiveActivityPresentationModel.presentation(for: .compactTrailing, state: state)

        XCTAssertNil(presentation.brandMark)
        XCTAssertNil(presentation.body)
        XCTAssertNil(presentation.lineLimit)
        XCTAssertNil(presentation.accessibilityLabel)
    }

    func testExpandedAndLockScreenUseTheSameRenderedCurrentBodyAndThreeLineLimit() {
        let expanded = LiveActivityPresentationModel.presentation(for: .expanded, state: state)
        let lockScreen = LiveActivityPresentationModel.presentation(for: .lockScreen, state: state)
        let expectedBody = "Review the product brief\n• Send the build notes to Maya\n# Heading stays literal"

        for presentation in [expanded, lockScreen] {
            XCTAssertEqual(presentation.body, expectedBody)
            XCTAssertEqual(presentation.lineLimit, 3)
            XCTAssertEqual(presentation.accessibilityLabel, "Island Notes, \(expectedBody)")
        }
        XCTAssertEqual(expanded.brandMark, .notebookText)
        XCTAssertNil(lockScreen.brandMark)
    }

    func testEveryRegionUsesTheWorkbenchDeepLink() {
        for region in LiveActivityRegion.allCases {
            XCTAssertEqual(
                LiveActivityPresentationModel.presentation(for: region, state: state).destination,
                URL(string: "islandnotes://workbench")
            )
        }
    }

    func testActivityKitStateContainsOnlyCommittedBodyVersionAndNoteIdentity() {
        let stateFields = Set(Mirror(reflecting: state).children.compactMap(\.label))
        let attributeFields = Set(
            Mirror(
                reflecting: IslandNoteActivityAttributes(
                    noteID: UUID(uuidString: "D82B5CC2-2E3E-4DCC-8E47-69208949813D")!
                )
            ).children.compactMap(\.label)
        )

        XCTAssertEqual(stateFields, ["body", "version"])
        XCTAssertEqual(attributeFields, ["noteID"])
    }
}
