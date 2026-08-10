import SwiftUI
import XCTest
@testable import IslandNotes

@MainActor
final class WorkbenchPresentationTests: XCTestCase {
    func testMarkedTextBlocksDoneAndRemovingEditorClearsCompositionState() {
        var composition = WorkbenchEditorCompositionState(hasMarkedText: true)

        XCTAssertFalse(composition.canSubmit(featureCanComplete: true))

        composition.textDidChange(markedTextActive: false)

        XCTAssertTrue(composition.canSubmit(featureCanComplete: true))

        composition.textDidChange(markedTextActive: true)

        composition.editingDidChange(false)

        XCTAssertFalse(composition.hasMarkedText)
        XCTAssertTrue(composition.canSubmit(featureCanComplete: true))
    }

    func testMarkedDraftRemainsInMemoryUntilCompositionEndsAndDoneBecomesAvailable() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        harness.feature.beginEditing()
        var composition = WorkbenchEditorCompositionState()

        composition.textDidChange(markedTextActive: true)
        harness.feature.stageEditorText(
            proposedText: "unfinished preedit",
            markedTextActive: true
        )

        XCTAssertFalse(
            composition.canSubmit(
                featureCanComplete: harness.feature.canCompleteEditing
            )
        )
        XCTAssertEqual(harness.feature.editingText, "unfinished preedit")
        XCTAssertEqual(harness.feature.currentNote?.body, "")
        XCTAssertTrue(harness.feature.isEditing)

        composition.textDidChange(markedTextActive: false)
        harness.feature.stageEditorText(
            proposedText: "完成组合 👨‍👩‍👧‍👦",
            markedTextActive: false
        )

        XCTAssertTrue(
            composition.canSubmit(
                featureCanComplete: harness.feature.canCompleteEditing
            )
        )
        try harness.feature.completeEditing()
        XCTAssertEqual(harness.feature.currentNote?.body, "完成组合 👨‍👩‍👧‍👦")
    }

    func testActionDockAvailabilityDistinguishesBlankContentFromValidBusyNote() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()

        XCTAssertEqual(harness.feature.contentActionAvailability, .needsContent)
        XCTAssertEqual(
            harness.feature.contentActionAvailability.accessibilityHint,
            "The current note needs non-whitespace text"
        )

        try harness.commitCurrentNote("Valid note starting Live")
        harness.controller.pauseRequests()
        let start = Task { await harness.feature.startPinning() }
        await waitUntil { harness.controller.hasPausedRequest }

        XCTAssertEqual(harness.feature.contentActionAvailability, .busy)
        XCTAssertEqual(
            harness.feature.contentActionAvailability.accessibilityHint,
            "Another note action is in progress"
        )

        harness.controller.resumeRequests()
        await start.value
    }

    func testWorkbenchActionAvailabilityDistinguishesContentAndBusyHints() {
        XCTAssertTrue(WorkbenchActionAvailability.enabled.isEnabled)
        XCTAssertEqual(WorkbenchActionAvailability.enabled.accessibilityHint, "")
        XCTAssertFalse(WorkbenchActionAvailability.needsContent.isEnabled)
        XCTAssertEqual(
            WorkbenchActionAvailability.needsContent.accessibilityHint,
            "The current note needs non-whitespace text"
        )
        XCTAssertFalse(WorkbenchActionAvailability.busy.isEnabled)
        XCTAssertEqual(
            WorkbenchActionAvailability.busy.accessibilityHint,
            "Another note action is in progress"
        )
        XCTAssertEqual(
            WorkbenchActionAvailability.busy.feedbackMessage,
            "Another note action is in progress."
        )
    }

    func testWorkbenchActionDockModelMapsEveryLivePresentationState() {
        let ready = WorkbenchActionDockModel.make(
            contentAvailability: .enabled,
            liveAvailability: .enabled,
            pinState: .unpinned,
            transition: nil
        )
        XCTAssertEqual(ready.live.state, .ready)
        XCTAssertEqual(ready.live.label, "Go Live")
        XCTAssertTrue(ready.live.isEnabled)

        let starting = WorkbenchActionDockModel.make(
            contentAvailability: .busy,
            liveAvailability: .busy,
            pinState: .unpinned,
            transition: .starting
        )
        XCTAssertEqual(starting.live.state, .starting)
        XCTAssertEqual(starting.live.accessibilityValue, "Starting")
        XCTAssertFalse(starting.live.isEnabled)

        let live = WorkbenchActionDockModel.make(
            contentAvailability: .enabled,
            liveAvailability: .enabled,
            pinState: .pinned,
            transition: nil
        )
        XCTAssertEqual(live.live.state, .live)
        XCTAssertEqual(live.live.label, "Live")
        XCTAssertEqual(live.live.accessibilityValue, "Live")

        let stopping = WorkbenchActionDockModel.make(
            contentAvailability: .busy,
            liveAvailability: .busy,
            pinState: .pinned,
            transition: .stopping
        )
        XCTAssertEqual(stopping.live.state, .stopping)
        XCTAssertEqual(stopping.live.accessibilityValue, "Stopping")
        XCTAssertFalse(stopping.live.isEnabled)

        let unavailable = WorkbenchActionDockModel.make(
            contentAvailability: .needsContent,
            liveAvailability: .needsContent,
            pinState: .unpinned,
            transition: nil
        )
        XCTAssertEqual(unavailable.live.state, .unavailable)
        XCTAssertEqual(
            unavailable.live.accessibilityHint,
            "The current note needs non-whitespace text"
        )
        XCTAssertFalse(unavailable.live.isEnabled)
    }

    func testDockActionsKeepBusyStateWithoutChangingTheirSemanticOrder() {
        let model = WorkbenchActionDockModel.make(
            contentAvailability: .busy,
            liveAvailability: .busy,
            pinState: .unpinned,
            transition: .starting
        )

        XCTAssertEqual(model.orderedAccessibilityLabels, [
            "Move to Note Library",
            "Go Live",
            "Delete Note",
        ])
        XCTAssertTrue(model.move.isBusy)
        XCTAssertTrue(model.delete.isBusy)
        XCTAssertFalse(model.move.isEnabled)
        XCTAssertFalse(model.delete.isEnabled)
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

    private func waitUntil(
        attempts: Int = 100,
        condition: @escaping @MainActor () -> Bool
    ) async {
        for _ in 0 ..< attempts {
            if condition() { return }
            await Task.yield()
        }
        XCTFail("Timed out waiting for asynchronous test state")
    }
}
