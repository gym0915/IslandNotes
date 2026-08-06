import XCTest
@testable import IslandNotes

@MainActor
final class LiveActivityLifecycleTests: XCTestCase {
    func testStartingAndRepeatingPinUsesOneCurrentActivity() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("把这句话挂起来")
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
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()

        await harness.feature.startPinning()

        XCTAssertTrue(harness.controller.activeActivities.isEmpty)
        XCTAssertEqual(harness.feature.pinState, .unpinned)
        XCTAssertNil(harness.feature.feedbackMessage)
    }

    func testRequestFailureKeepsContentAndUnpinnedState() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("请求失败也不能丢")
        harness.controller.requestFailure = FakeLiveActivityError.requestFailed

        await harness.feature.startPinning()

        XCTAssertTrue(harness.controller.activeActivities.isEmpty)
        XCTAssertEqual(harness.feature.pinState, .unpinned)
        XCTAssertEqual(harness.feature.currentNote?.body, "请求失败也不能丢")
        XCTAssertNotNil(harness.feature.feedbackMessage)
    }

    func testFourKilobyteRequestValidationKeepsExtremeUnicodeLocallyAndUnpinned() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        let oversized = String(repeating: "👨‍👩‍👧‍👦", count: 240)
        try harness.commitCurrentNote(oversized)

        await harness.feature.startPinning()

        XCTAssertEqual(harness.feature.currentNote?.body, oversized)
        XCTAssertEqual(try harness.notes().first?.body, oversized)
        XCTAssertTrue(harness.controller.activeActivities.isEmpty)
        XCTAssertEqual(harness.feature.pinState, .unpinned)
        XCTAssertNotNil(harness.feature.feedbackMessage)
    }

    func testRequestAcceptsExactlyFourKilobytesAndRejectsTheNextUserReachableByte() async throws {
        let combiningPrefix = "a" + String(repeating: "\u{0301}", count: 2_011)
        let exactlyAtLimit = combiningPrefix + "b"
        let oneByteOver = combiningPrefix + "bc"
        XCTAssertEqual(exactlyAtLimit.count, 2)
        XCTAssertEqual(oneByteOver.count, 3)
        XCTAssertEqual(exactlyAtLimit.utf8.count, 4_024)
        XCTAssertEqual(oneByteOver.utf8.count, 4_025)

        let accepted = try FeatureHarness.make()
        try await accepted.feature.bootstrap()
        try accepted.commitCurrentNote(exactlyAtLimit)
        await accepted.feature.startPinning()

        XCTAssertEqual(try accepted.notes().first?.body, exactlyAtLimit)
        XCTAssertEqual(accepted.controller.activeActivities.map(\.body), [exactlyAtLimit])
        XCTAssertEqual(accepted.feature.pinState, .pinned)

        let rejected = try FeatureHarness.make()
        try await rejected.feature.bootstrap()
        try rejected.commitCurrentNote(oneByteOver)
        await rejected.feature.startPinning()

        XCTAssertEqual(try rejected.notes().first?.body, oneByteOver)
        XCTAssertTrue(rejected.controller.activeActivities.isEmpty)
        XCTAssertEqual(rejected.feature.pinState, .unpinned)
        XCTAssertNotNil(rejected.feature.feedbackMessage)
    }

    func testCancelUsesReenumeratedSystemStateEvenWhenEndThrows() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("结束后仍保留内容")
        await harness.feature.startPinning()
        harness.controller.endOutcome = .removeThenThrow

        await harness.feature.cancelPinning()

        XCTAssertTrue(harness.controller.activeActivities.isEmpty)
        XCTAssertEqual(harness.feature.pinState, .unpinned)
        XCTAssertNil(harness.feature.feedbackMessage)
        XCTAssertEqual(harness.feature.currentNote?.body, "结束后仍保留内容")
    }

    func testCancelKeepsPinnedStateWhenActivityIsStillActive() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("系统仍显示")
        await harness.feature.startPinning()
        harness.controller.endOutcome = .keepThenThrow

        await harness.feature.cancelPinning()

        XCTAssertEqual(harness.controller.activeActivities.count, 1)
        XCTAssertEqual(harness.feature.pinState, .pinned)
        XCTAssertNotNil(harness.feature.feedbackMessage)
    }

    func testActiveSessionMustActuallyEndBeforeArchive() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("活动未结束时不能入库")
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
        XCTAssertNotNil(harness.feature.feedbackMessage)
    }

    func testEndThrowAfterActualRemovalStillAllowsArchive() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("活动消失后可以入库")
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
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("库中旧便签")
        let libraryID = try XCTUnwrap(harness.feature.currentNote?.id)
        try await harness.feature.archiveCurrentNote()
        try harness.commitCurrentNote("当前挂起内容")
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

    func testPinnedCommitPersistsBeforeUpdatingTheSameActivity() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("初始内容")
        await harness.feature.startPinning()
        let originalActivity = try XCTUnwrap(harness.controller.activeActivities.first)

        try harness.commitCurrentNote("已经先保存的新内容")

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

    func testContinuousPinnedCommitsFlushOnlyTheLatestSavedValue() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("起点")
        await harness.feature.startPinning()

        try harness.commitCurrentNote("中间值")
        try harness.commitCurrentNote("最终值")
        await harness.feature.flushPendingActivityUpdate()

        XCTAssertEqual(harness.controller.activeActivities.count, 1)
        XCTAssertEqual(harness.controller.activeActivities.first?.body, "最终值")
        XCTAssertEqual(harness.feature.currentNote?.body, "最终值")
    }

    func testActivityUpdateFailureKeepsLatestLocalContentAndCanRetry() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("岛上旧内容")
        await harness.feature.startPinning()
        harness.controller.updateFailure = FakeLiveActivityError.updateFailed

        try harness.commitCurrentNote("本地新内容")
        await harness.feature.flushPendingActivityUpdate()

        XCTAssertEqual(harness.feature.currentNote?.body, "本地新内容")
        XCTAssertEqual(try harness.notes().first?.body, "本地新内容")
        XCTAssertEqual(harness.controller.activeActivities.first?.body, "岛上旧内容")
        XCTAssertEqual(harness.feature.pinState, .pinned)
        XCTAssertNotNil(harness.feature.feedbackMessage)

        harness.controller.updateFailure = nil
        await harness.feature.flushPendingActivityUpdate()

        XCTAssertEqual(harness.controller.activeActivities.first?.body, "本地新内容")
        XCTAssertNil(harness.feature.feedbackMessage)
    }

    func testUpdateAcceptsExactlyFourKilobytesAndRejectsTheNextUserReachableByte() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("岛上仍显示的旧内容")
        await harness.feature.startPinning()
        let originalActivity = try XCTUnwrap(harness.controller.activeActivities.first)
        let combiningPrefix = "a" + String(repeating: "\u{0301}", count: 2_011)
        let exactlyAtLimit = combiningPrefix + "b"
        let oneByteOver = combiningPrefix + "bc"
        XCTAssertEqual(exactlyAtLimit.utf8.count, 4_024)
        XCTAssertEqual(oneByteOver.utf8.count, 4_025)

        try harness.commitCurrentNote(exactlyAtLimit)
        await harness.feature.flushPendingActivityUpdate()

        let acceptedActivity = try XCTUnwrap(harness.controller.activeActivities.first)
        XCTAssertEqual(acceptedActivity.activityID, originalActivity.activityID)
        XCTAssertEqual(acceptedActivity.body, exactlyAtLimit)
        XCTAssertGreaterThan(acceptedActivity.version, originalActivity.version)
        XCTAssertNil(harness.feature.feedbackMessage)

        try harness.commitCurrentNote(oneByteOver)
        await harness.feature.flushPendingActivityUpdate()

        XCTAssertEqual(harness.feature.currentNote?.body, oneByteOver)
        XCTAssertEqual(try harness.notes().first?.body, oneByteOver)
        XCTAssertEqual(harness.controller.activeActivities.first?.activityID, originalActivity.activityID)
        XCTAssertEqual(harness.controller.activeActivities.first?.body, exactlyAtLimit)
        XCTAssertEqual(harness.feature.pinState, .pinned)
        XCTAssertNotNil(harness.feature.feedbackMessage)
    }
}
