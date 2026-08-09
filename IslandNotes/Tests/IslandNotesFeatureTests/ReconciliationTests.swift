import XCTest
@testable import IslandNotes

@MainActor
final class ReconciliationTests: XCTestCase {
    func testBootstrapRefreshesStaleKeeperWithPersistedCurrentContent() async throws {
        let harness = try FeatureHarness.make()
        try harness.workspace.bootstrap()
        try harness.workspace.commitCurrentNote("启动时已提交的最新内容")
        let current = try XCTUnwrap(harness.workspace.currentNote)
        harness.controller.seedActivities([
            ActivitySession(
                activityID: "keeper",
                noteID: current.id,
                body: "进程结束前尚未更新的内容",
                version: current.contentVersion - 1,
                isActive: true
            )
        ])

        try await harness.feature.bootstrap()

        XCTAssertEqual(harness.controller.activeActivities.count, 1)
        XCTAssertEqual(harness.controller.activeActivities.first?.activityID, "keeper")
        XCTAssertEqual(harness.controller.activeActivities.first?.body, current.body)
        XCTAssertEqual(harness.controller.activeActivities.first?.version, current.contentVersion)
        XCTAssertEqual(harness.feature.pinState, .pinned)
    }

    func testReconcileDerivesPinnedStateFromOneCurrentActivity() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("恢复中的当前便签")
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

    func testReconcilePreservesSaveFailureFeedbackItDoesNotOwn() async throws {
        let storeCopy = try LegacyStoreFixture.copy()
        let harness = try storeCopy.makeHarness(allowsSave: false)
        try await harness.feature.bootstrap()
        let current = try XCTUnwrap(harness.feature.currentNote)
        harness.controller.seedActivities([
            ActivitySession(
                activityID: "current",
                noteID: current.id,
                body: current.body,
                version: current.contentVersion,
                isActive: true
            )
        ])
        harness.feature.beginEditing()
        harness.feature.stageEditorText(
            proposedText: "无法写入的草稿",
            markedTextActive: false
        )
        XCTAssertThrowsError(try harness.feature.completeEditing())
        XCTAssertEqual(harness.feature.feedbackMessage, "Your note hasn't been saved.")

        await harness.feature.reconcileActivities()

        XCTAssertEqual(harness.feature.feedbackMessage, "Your note hasn't been saved.")
        XCTAssertEqual(harness.feature.pinState, .pinned)
        XCTAssertTrue(harness.feature.isEditing)
        XCTAssertEqual(harness.feature.editingDraft, "无法写入的草稿")
    }

    func testFailedPendingLiveRetryDoesNotReplaceSaveFailureFeedback() async throws {
        let storeCopy = try LegacyStoreFixture.copy()
        let harness = try storeCopy.makeHarness(allowsSave: false)
        try harness.workspace.bootstrap()
        let current = try XCTUnwrap(harness.workspace.currentNote)
        harness.controller.seedActivities([
            ActivitySession(
                activityID: "stale-current",
                noteID: current.id,
                body: "岛上的旧内容",
                version: current.contentVersion - 1,
                isActive: true
            )
        ])
        harness.controller.updateFailure = FakeLiveActivityError.updateFailed
        try await harness.feature.bootstrap()
        XCTAssertEqual(harness.feature.feedbackMessage, "Live may not be up to date.")

        harness.feature.beginEditing()
        harness.feature.stageEditorText(
            proposedText: "无法保存但必须保留的草稿",
            markedTextActive: false
        )
        XCTAssertThrowsError(try harness.feature.completeEditing())
        XCTAssertEqual(harness.feature.feedbackMessage, "Your note hasn't been saved.")

        await harness.feature.reconcileActivities()

        XCTAssertGreaterThanOrEqual(harness.controller.updateCallCount, 2)
        XCTAssertEqual(harness.controller.activeActivities.first?.body, "岛上的旧内容")
        XCTAssertEqual(harness.feature.feedbackMessage, "Your note hasn't been saved.")
        XCTAssertTrue(harness.feature.isEditing)
        XCTAssertEqual(harness.feature.editingDraft, "无法保存但必须保留的草稿")
    }

    func testReconcileRetriesPendingLiveUpdateAgainstTheSameKeeper() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("岛上旧内容")
        await harness.feature.startPinning()
        let activityID = try XCTUnwrap(harness.controller.activeActivities.first?.activityID)
        harness.controller.updateFailure = FakeLiveActivityError.updateFailed
        try harness.commitCurrentNote("本地已提交的新内容")
        await harness.feature.flushPendingActivityUpdate()
        XCTAssertEqual(harness.controller.updateCallCount, 1)
        XCTAssertEqual(harness.controller.activeActivities.first?.body, "岛上旧内容")

        harness.controller.updateFailure = nil
        await harness.feature.reconcileActivities()

        XCTAssertEqual(harness.controller.updateCallCount, 2)
        XCTAssertEqual(harness.controller.activeActivities.first?.activityID, activityID)
        XCTAssertEqual(harness.controller.activeActivities.first?.body, "本地已提交的新内容")
        XCTAssertNil(harness.feature.feedbackMessage)
        XCTAssertEqual(harness.feature.pinState, .pinned)
    }

    func testReconcileClearsPendingLiveErrorWhenKeeperAlreadyCaughtUp() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("岛上旧内容")
        await harness.feature.startPinning()
        let activityID = try XCTUnwrap(harness.controller.activeActivities.first?.activityID)
        harness.controller.updateFailure = FakeLiveActivityError.updateFailed
        try harness.commitCurrentNote("系统后续已追平")
        await harness.feature.flushPendingActivityUpdate()
        let current = try XCTUnwrap(harness.feature.currentNote)
        XCTAssertEqual(harness.feature.feedbackMessage, "Live may not be up to date.")
        harness.controller.updateFailure = nil
        harness.controller.seedActivities([
            ActivitySession(
                activityID: activityID,
                noteID: current.id,
                body: current.body,
                version: current.contentVersion,
                isActive: true
            )
        ])

        await harness.feature.reconcileActivities()

        XCTAssertEqual(harness.controller.activeActivities.first?.activityID, activityID)
        XCTAssertEqual(harness.controller.activeActivities.first?.body, "系统后续已追平")
        XCTAssertNil(harness.feature.feedbackMessage)
        XCTAssertEqual(harness.feature.pinState, .pinned)
    }

    func testReconcileEndsOrphanWithoutChangingCurrentContent() async throws {
        let harness = try FeatureHarness.make()
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
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("唯一当前")
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
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("不能覆盖系统异常")
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
        XCTAssertNotNil(harness.feature.feedbackMessage)
    }
}
