import XCTest
@testable import IslandNotes

@MainActor
final class ReconciliationTests: XCTestCase {
    func testReconcileDerivesPinnedStateFromOneCurrentActivity() async throws {
        let harness = try InMemoryFeatureHarness.make()
        try await harness.feature.bootstrap()
        try await harness.feature.editCurrentNote(
            proposedText: "恢复中的当前便签",
            markedTextActive: false
        )
        let current = try XCTUnwrap(harness.feature.currentNote)
        harness.controller.seedActivities([
            ActivitySession(
                activityID: "current-1",
                noteID: current.id,
                body: current.body,
                version: current.contentVersion,
                isActive: true
            )
        ])

        await harness.feature.reconcileActivities()

        XCTAssertEqual(harness.feature.pinState, .pinned)
        XCTAssertNil(harness.feature.feedbackMessage)
        XCTAssertEqual(harness.controller.activeActivities.map(\.activityID), ["current-1"])
    }

    func testReconcileEndsOrphanWithoutChangingCurrentContent() async throws {
        let harness = try InMemoryFeatureHarness.make()
        try await harness.feature.bootstrap()
        let currentID = try XCTUnwrap(harness.feature.currentNote?.id)
        harness.controller.seedActivities([
            ActivitySession(
                activityID: "orphan",
                noteID: UUID(),
                body: "不应恢复",
                version: 9,
                isActive: true
            )
        ])

        await harness.feature.reconcileActivities()

        XCTAssertTrue(harness.controller.activeActivities.isEmpty)
        XCTAssertEqual(harness.feature.pinState, .unpinned)
        XCTAssertEqual(harness.feature.currentNote?.id, currentID)
        XCTAssertEqual(harness.feature.currentNote?.body, "")
    }

    func testReconcileMultipleActivitiesKeepsOneDeterministicCurrentActivity() async throws {
        let harness = try InMemoryFeatureHarness.make()
        try await harness.feature.bootstrap()
        try await harness.feature.editCurrentNote(
            proposedText: "唯一当前",
            markedTextActive: false
        )
        let current = try XCTUnwrap(harness.feature.currentNote)
        harness.controller.seedActivities([
            ActivitySession(activityID: "z-current", noteID: current.id, body: "旧", version: 1, isActive: true),
            ActivitySession(activityID: "a-current", noteID: current.id, body: current.body, version: current.contentVersion, isActive: true),
            ActivitySession(activityID: "orphan", noteID: UUID(), body: "孤立", version: 1, isActive: true)
        ])

        await harness.feature.reconcileActivities()

        XCTAssertEqual(harness.controller.activeActivities.count, 1)
        XCTAssertEqual(harness.controller.activeActivities.first?.activityID, "a-current")
        XCTAssertEqual(harness.controller.activeActivities.first?.noteID, current.id)
        XCTAssertEqual(harness.feature.pinState, .pinned)
    }

    func testCleanupFailureBlocksNewRequestAndDoesNotReportPinned() async throws {
        let harness = try InMemoryFeatureHarness.make()
        try await harness.feature.bootstrap()
        try await harness.feature.editCurrentNote(
            proposedText: "不能覆盖系统异常",
            markedTextActive: false
        )
        let orphan = ActivitySession(
            activityID: "stuck-orphan",
            noteID: UUID(),
            body: "仍存在",
            version: 1,
            isActive: true
        )
        harness.controller.seedActivities([orphan])
        harness.controller.endOutcome = .keepThenThrow

        await harness.feature.reconcileActivities()
        await harness.feature.startPinning()

        XCTAssertEqual(harness.controller.activeActivities, [orphan])
        XCTAssertEqual(harness.feature.pinState, .unpinned)
        XCTAssertEqual(harness.feature.feedbackMessage, "系统展示正在整理，请重试")
    }
}
