import XCTest
@testable import IslandNotes

@MainActor
final class LiveActivityLifecycleTests: XCTestCase {
    func testStartingAndRepeatingPinUsesOneCurrentActivity() async throws {
        let harness = try InMemoryFeatureHarness.make()
        try await harness.feature.bootstrap()
        try await harness.feature.editCurrentNote(
            proposedText: "把这句话挂起来",
            markedTextActive: false
        )
        let currentID = try XCTUnwrap(harness.feature.currentNote?.id)

        await harness.feature.startPinning()

        let activity = try XCTUnwrap(harness.controller.activeActivities.first)
        XCTAssertEqual(harness.controller.activeActivities.count, 1)
        XCTAssertEqual(activity.noteID, currentID)
        XCTAssertEqual(activity.body, "把这句话挂起来")
        XCTAssertTrue(activity.isActive)
        XCTAssertEqual(harness.feature.pinState, .pinned)
        XCTAssertNil(harness.feature.feedbackMessage)

        await harness.feature.startPinning()

        XCTAssertEqual(harness.controller.activeActivities.count, 1)
        XCTAssertEqual(harness.controller.activeActivities.first?.activityID, activity.activityID)
        XCTAssertEqual(harness.feature.currentNote?.body, "把这句话挂起来")
    }

    func testBlankNoteCannotStartActivity() async throws {
        let harness = try InMemoryFeatureHarness.make()
        try await harness.feature.bootstrap()

        await harness.feature.startPinning()

        XCTAssertTrue(harness.controller.activeActivities.isEmpty)
        XCTAssertEqual(harness.feature.pinState, .unpinned)
        XCTAssertNil(harness.feature.feedbackMessage)
    }

    func testRequestFailureKeepsContentAndUnpinnedState() async throws {
        let harness = try InMemoryFeatureHarness.make()
        try await harness.feature.bootstrap()
        try await harness.feature.editCurrentNote(
            proposedText: "请求失败也不能丢",
            markedTextActive: false
        )
        harness.controller.requestFailure = FakeLiveActivityError.requestFailed

        await harness.feature.startPinning()

        XCTAssertTrue(harness.controller.activeActivities.isEmpty)
        XCTAssertEqual(harness.feature.pinState, .unpinned)
        XCTAssertEqual(harness.feature.currentNote?.body, "请求失败也不能丢")
        XCTAssertEqual(harness.feature.feedbackMessage, "挂起未完成，请重试")
    }

    func testFourKilobyteRequestValidationKeepsExtremeUnicodeLocallyAndUnpinned() async throws {
        let harness = try InMemoryFeatureHarness.make()
        try await harness.feature.bootstrap()
        let oversized = String(repeating: "👨‍👩‍👧‍👦", count: 240)
        try await harness.feature.editCurrentNote(
            proposedText: oversized,
            markedTextActive: false
        )

        await harness.feature.startPinning()

        XCTAssertEqual(harness.feature.currentNote?.body, oversized)
        XCTAssertEqual(try harness.notes().first?.body, oversized)
        XCTAssertTrue(harness.controller.activeActivities.isEmpty)
        XCTAssertEqual(harness.feature.pinState, .unpinned)
        XCTAssertEqual(harness.feature.feedbackMessage, "挂起未完成，请重试")
    }

    func testCancelUsesReenumeratedSystemStateEvenWhenEndThrows() async throws {
        let harness = try InMemoryFeatureHarness.make()
        try await harness.feature.bootstrap()
        try await harness.feature.editCurrentNote(
            proposedText: "结束后仍保留内容",
            markedTextActive: false
        )
        await harness.feature.startPinning()
        harness.controller.endOutcome = .removeThenThrow

        await harness.feature.cancelPinning()

        XCTAssertTrue(harness.controller.activeActivities.isEmpty)
        XCTAssertEqual(harness.feature.pinState, .unpinned)
        XCTAssertNil(harness.feature.feedbackMessage)
        XCTAssertEqual(harness.feature.currentNote?.body, "结束后仍保留内容")
    }

    func testCancelKeepsPinnedStateWhenActivityIsStillActive() async throws {
        let harness = try InMemoryFeatureHarness.make()
        try await harness.feature.bootstrap()
        try await harness.feature.editCurrentNote(
            proposedText: "系统仍显示",
            markedTextActive: false
        )
        await harness.feature.startPinning()
        harness.controller.endOutcome = .keepThenThrow

        await harness.feature.cancelPinning()

        XCTAssertEqual(harness.controller.activeActivities.count, 1)
        XCTAssertEqual(harness.feature.pinState, .pinned)
        XCTAssertEqual(harness.feature.feedbackMessage, "取消挂起尚未完成")
    }

    func testActiveSessionMustActuallyEndBeforeArchive() async throws {
        let harness = try InMemoryFeatureHarness.make()
        try await harness.feature.bootstrap()
        try await harness.feature.editCurrentNote(
            proposedText: "活动未结束时不能入库",
            markedTextActive: false
        )
        let originalID = try XCTUnwrap(harness.feature.currentNote?.id)
        await harness.feature.startPinning()
        harness.controller.endOutcome = .keepThenThrow

        try await harness.feature.archiveCurrentNote()

        XCTAssertEqual(harness.feature.currentNote?.id, originalID)
        XCTAssertEqual(harness.feature.currentNote?.body, "活动未结束时不能入库")
        XCTAssertTrue(harness.feature.library.isEmpty)
        XCTAssertEqual(try harness.notes().count, 1)
        XCTAssertEqual(harness.controller.activeActivities.count, 1)
        XCTAssertEqual(harness.feature.pinState, .pinned)
        XCTAssertEqual(harness.feature.feedbackMessage, "取消挂起尚未完成")
    }

    func testEndThrowAfterActualRemovalStillAllowsArchive() async throws {
        let harness = try InMemoryFeatureHarness.make()
        try await harness.feature.bootstrap()
        try await harness.feature.editCurrentNote(
            proposedText: "活动消失后可以入库",
            markedTextActive: false
        )
        await harness.feature.startPinning()
        harness.controller.endOutcome = .removeThenThrow

        try await harness.feature.archiveCurrentNote()

        XCTAssertTrue(harness.controller.activeActivities.isEmpty)
        XCTAssertEqual(harness.feature.pinState, .unpinned)
        XCTAssertEqual(harness.feature.currentNote?.body, "")
        XCTAssertEqual(harness.feature.library.map(\.body), ["活动消失后可以入库"])
        XCTAssertNil(harness.feature.feedbackMessage)
    }

    func testActiveSessionBlocksConfirmedDeleteAndLibrarySwap() async throws {
        let harness = try InMemoryFeatureHarness.make()
        try await harness.feature.bootstrap()
        try await harness.feature.editCurrentNote(
            proposedText: "库中旧便签",
            markedTextActive: false
        )
        let libraryID = try XCTUnwrap(harness.feature.currentNote?.id)
        try await harness.feature.archiveCurrentNote()
        try await harness.feature.editCurrentNote(
            proposedText: "当前挂起内容",
            markedTextActive: false
        )
        let currentID = try XCTUnwrap(harness.feature.currentNote?.id)
        await harness.feature.startPinning()
        harness.controller.endOutcome = .keepThenThrow

        harness.feature.requestDelete()
        try await harness.feature.confirmDeleteCurrentNote()
        try await harness.feature.selectLibraryNote(id: libraryID)

        XCTAssertEqual(harness.feature.currentNote?.id, currentID)
        XCTAssertEqual(harness.feature.currentNote?.body, "当前挂起内容")
        XCTAssertEqual(harness.feature.library.map(\.id), [libraryID])
        XCTAssertEqual(try harness.notes().count, 2)
        XCTAssertEqual(harness.controller.activeActivities.count, 1)
        XCTAssertEqual(harness.feature.pinState, .pinned)
    }

    func testPinnedEditingSavesBeforeUpdatingSameActivity() async throws {
        let harness = try InMemoryFeatureHarness.make()
        try await harness.feature.bootstrap()
        try await harness.feature.editCurrentNote(
            proposedText: "初始内容",
            markedTextActive: false
        )
        await harness.feature.startPinning()
        let originalActivity = try XCTUnwrap(harness.controller.activeActivities.first)

        try await harness.feature.editCurrentNote(
            proposedText: "已经先保存的新内容",
            markedTextActive: false
        )

        XCTAssertEqual(harness.feature.currentNote?.body, "已经先保存的新内容")
        XCTAssertEqual(try harness.notes().first?.body, "已经先保存的新内容")
        XCTAssertEqual(harness.controller.activeActivities.first?.body, "初始内容")

        await harness.feature.flushPendingActivityUpdate()

        let updated = try XCTUnwrap(harness.controller.activeActivities.first)
        XCTAssertEqual(updated.activityID, originalActivity.activityID)
        XCTAssertEqual(updated.body, "已经先保存的新内容")
        XCTAssertGreaterThan(updated.version, originalActivity.version)
        XCTAssertEqual(harness.feature.pinState, .pinned)
        XCTAssertNil(harness.feature.feedbackMessage)
    }

    func testContinuousPinnedEditsFlushOnlyTheLatestSavedValue() async throws {
        let harness = try InMemoryFeatureHarness.make()
        try await harness.feature.bootstrap()
        try await harness.feature.editCurrentNote(
            proposedText: "起点",
            markedTextActive: false
        )
        await harness.feature.startPinning()

        try await harness.feature.editCurrentNote(
            proposedText: "中间值",
            markedTextActive: false
        )
        try await harness.feature.editCurrentNote(
            proposedText: "最终值",
            markedTextActive: false
        )
        await harness.feature.flushPendingActivityUpdate()

        XCTAssertEqual(harness.controller.activeActivities.count, 1)
        XCTAssertEqual(harness.controller.activeActivities.first?.body, "最终值")
        XCTAssertEqual(harness.feature.currentNote?.body, "最终值")
    }

    func testActivityUpdateFailureKeepsLatestLocalContentAndCanRetry() async throws {
        let harness = try InMemoryFeatureHarness.make()
        try await harness.feature.bootstrap()
        try await harness.feature.editCurrentNote(
            proposedText: "岛上旧内容",
            markedTextActive: false
        )
        await harness.feature.startPinning()
        harness.controller.updateFailure = FakeLiveActivityError.updateFailed

        try await harness.feature.editCurrentNote(
            proposedText: "本地新内容",
            markedTextActive: false
        )
        await harness.feature.flushPendingActivityUpdate()

        XCTAssertEqual(harness.feature.currentNote?.body, "本地新内容")
        XCTAssertEqual(try harness.notes().first?.body, "本地新内容")
        XCTAssertEqual(harness.controller.activeActivities.first?.body, "岛上旧内容")
        XCTAssertEqual(harness.feature.pinState, .pinned)
        XCTAssertEqual(harness.feature.feedbackMessage, "系统展示可能尚未同步")

        harness.controller.updateFailure = nil
        await harness.feature.flushPendingActivityUpdate()

        XCTAssertEqual(harness.controller.activeActivities.first?.body, "本地新内容")
        XCTAssertNil(harness.feature.feedbackMessage)
    }

    func testFourKilobyteUpdateValidationKeepsLatestLocalContentAndExistingActivity() async throws {
        let harness = try InMemoryFeatureHarness.make()
        try await harness.feature.bootstrap()
        try await harness.feature.editCurrentNote(
            proposedText: "岛上仍显示的旧内容",
            markedTextActive: false
        )
        await harness.feature.startPinning()
        let originalActivity = try XCTUnwrap(harness.controller.activeActivities.first)
        let oversized = String(repeating: "👨‍👩‍👧‍👦", count: 240)

        try await harness.feature.editCurrentNote(
            proposedText: oversized,
            markedTextActive: false
        )
        await harness.feature.flushPendingActivityUpdate()

        XCTAssertEqual(harness.feature.currentNote?.body, oversized)
        XCTAssertEqual(try harness.notes().first?.body, oversized)
        XCTAssertEqual(harness.controller.activeActivities.first?.activityID, originalActivity.activityID)
        XCTAssertEqual(harness.controller.activeActivities.first?.body, originalActivity.body)
        XCTAssertEqual(harness.feature.pinState, .pinned)
        XCTAssertEqual(harness.feature.feedbackMessage, "系统展示可能尚未同步")
    }
}
