import SwiftUI
import XCTest
@testable import IslandNotes

@MainActor
final class WorkbenchPresentationTests: XCTestCase {
    func testWorkbenchActionsMapToStableSemanticKindsAndRoles() {
        XCTAssertEqual(WorkbenchActionSemantic.move.kind, .neutral)
        XCTAssertNil(WorkbenchActionSemantic.move.role)
        XCTAssertEqual(WorkbenchActionSemantic.goLive.kind, .neutral)
        XCTAssertNil(WorkbenchActionSemantic.goLive.role)
        XCTAssertEqual(WorkbenchActionSemantic.live.kind, .live)
        XCTAssertNil(WorkbenchActionSemantic.live.role)
        XCTAssertEqual(WorkbenchActionSemantic.delete.kind, .destructive)
        XCTAssertEqual(WorkbenchActionSemantic.delete.role, .destructive)
    }

    func testRecoverableFeedbackAnnouncementOnlyEmitsForNewMessages() {
        var state = RecoverableFeedbackAnnouncementState()

        XCTAssertEqual(state.nextAnnouncement(for: "Couldn't move the note."), "Couldn't move the note.")
        XCTAssertNil(state.nextAnnouncement(for: "Couldn't move the note."))
        XCTAssertEqual(state.nextAnnouncement(for: "Couldn't delete the note."), "Couldn't delete the note.")
    }

    func testLiveControllerSelectionRequiresExplicitUITestFlag() {
        XCTAssertEqual(LiveActivityControllerSelection.mode(arguments: []), .system)
        XCTAssertEqual(
            LiveActivityControllerSelection.mode(arguments: ["--uitesting-fake-live-activity"]),
            .deterministicUITest
        )
    }

    func testDeterministicUITestLiveControllerRunsRequestUpdateEndLifecycle() async throws {
        let controller = DeterministicUITestLiveActivityController()
        let noteID = UUID()

        try await controller.request(noteID: noteID, body: "Initial", version: 1)
        let requestedActivities = await controller.activities()
        let requested = try XCTUnwrap(requestedActivities.first)
        XCTAssertEqual(requested.noteID, noteID)
        XCTAssertEqual(requested.body, "Initial")

        try await controller.update(activityID: requested.activityID, body: "Updated", version: 2)
        let updatedActivities = await controller.activities()
        XCTAssertEqual(updatedActivities.first?.body, "Updated")

        try await controller.end(activityID: requested.activityID)
        let endedActivities = await controller.activities()
        XCTAssertTrue(endedActivities.isEmpty)
    }
}
