import XCTest
@testable import IslandNotes

@MainActor
final class LiveActivityLifecycleTests: XCTestCase {
    func testDoneDuringPendingLiveStartPreservesDraftUntilTransitionCompletes() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("Committed before Live")
        harness.feature.beginEditing()
        harness.feature.stageEditorText(
            proposedText: "Draft while Live starts",
            markedTextActive: false
        )
        harness.controller.pauseRequests()

        let start = Task { await harness.feature.startPinning() }
        await waitUntil { harness.controller.hasPausedRequest }
        XCTAssertFalse(harness.feature.canPin)
        XCTAssertFalse(harness.feature.canBeginEditing)
        XCTAssertFalse(harness.feature.canCompleteEditing)
        XCTAssertFalse(harness.feature.canSelectLibraryNote)
        XCTAssertEqual(harness.feature.noteMutationAvailability, .busy)

        try harness.feature.completeEditing()

        XCTAssertEqual(harness.feature.currentNote?.body, "Committed before Live")
        XCTAssertEqual(harness.feature.editingDraft, "Draft while Live starts")
        XCTAssertEqual(harness.feature.feedbackMessage, "Another note action is in progress.")

        harness.controller.resumeRequests()
        await start.value

        XCTAssertEqual(harness.controller.activeActivities.first?.body, "Committed before Live")
        XCTAssertNil(harness.feature.feedbackMessage)
        XCTAssertTrue(harness.feature.canCompleteEditing)
        XCTAssertTrue(harness.feature.canSelectLibraryNote)
        XCTAssertEqual(harness.feature.noteMutationAvailability, .enabled)

        try harness.feature.completeEditing()
        await harness.feature.flushPendingActivityUpdate()

        XCTAssertEqual(harness.feature.currentNote?.body, "Draft while Live starts")
        XCTAssertEqual(harness.controller.activeActivities.first?.body, "Draft while Live starts")
        XCTAssertNil(harness.feature.editingDraft)
    }

    func testLibraryReplacementDuringPendingLiveStartIsRejectedWithoutChangingCurrentNote() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("Library candidate")
        let libraryID = try XCTUnwrap(harness.feature.currentNote?.id)
        try await harness.feature.archiveCurrentNote()
        try harness.commitCurrentNote("Current before Live")
        let currentID = try XCTUnwrap(harness.feature.currentNote?.id)
        harness.controller.pauseRequests()

        let start = Task { await harness.feature.startPinning() }
        await waitUntil { harness.controller.hasPausedRequest }
        XCTAssertFalse(harness.feature.canPin)
        XCTAssertFalse(harness.feature.canBeginEditing)
        XCTAssertFalse(harness.feature.canSelectLibraryNote)

        try await harness.feature.selectLibraryNote(id: libraryID)

        XCTAssertEqual(harness.feature.currentNote?.id, currentID)
        XCTAssertEqual(harness.feature.currentNote?.body, "Current before Live")
        XCTAssertEqual(harness.feature.library.map(\.id), [libraryID])
        XCTAssertEqual(harness.feature.feedbackMessage, "Another note action is in progress.")

        harness.controller.resumeRequests()
        await start.value

        XCTAssertEqual(harness.controller.activeActivities.first?.noteID, currentID)
        XCTAssertEqual(harness.controller.activeActivities.first?.body, "Current before Live")
        XCTAssertNil(harness.feature.feedbackMessage)

        try await harness.feature.selectLibraryNote(id: libraryID)

        XCTAssertEqual(harness.feature.currentNote?.id, libraryID)
        XCTAssertEqual(harness.feature.currentNote?.body, "Library candidate")
        XCTAssertTrue(harness.controller.activeActivities.isEmpty)
    }

    func testPendingLibraryReplacementBlocksLiveStartUntilCurrentNoteChanges() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("Library candidate")
        let libraryID = try XCTUnwrap(harness.feature.currentNote?.id)
        try await harness.feature.archiveCurrentNote()
        try harness.commitCurrentNote("Current before replacement")
        harness.controller.pauseNextActivities()

        let replacement = Task {
            try await harness.feature.selectLibraryNote(id: libraryID)
        }
        await waitUntil { harness.controller.hasPausedActivitiesCall }

        XCTAssertFalse(harness.feature.canPin)

        let start = Task { await harness.feature.startPinning() }
        await drainReadyTasks()

        XCTAssertTrue(harness.controller.activeActivities.isEmpty)
        XCTAssertEqual(harness.feature.pinState, .unpinned)
        XCTAssertEqual(harness.feature.currentNote?.body, "Current before replacement")

        harness.controller.resumeActivities()
        try await replacement.value
        await start.value

        XCTAssertEqual(harness.feature.currentNote?.id, libraryID)
        XCTAssertEqual(harness.feature.currentNote?.body, "Library candidate")
        XCTAssertTrue(harness.controller.activeActivities.isEmpty)
    }

    func testRapidLiveStartsIssueOnlyOneSystemRequest() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("Only one Live request")
        harness.controller.pauseRequests()

        let firstStart = Task { await harness.feature.startPinning() }
        await waitUntil { harness.controller.requestCallCount == 1 }
        XCTAssertFalse(harness.feature.canPin)
        XCTAssertFalse(harness.feature.canArchive)
        XCTAssertFalse(harness.feature.canDelete)

        let secondStart = Task { await harness.feature.startPinning() }
        await drainReadyTasks()

        XCTAssertEqual(harness.controller.requestCallCount, 1)

        harness.controller.resumeRequests()
        await firstStart.value
        await secondStart.value

        XCTAssertEqual(harness.controller.requestCallCount, 1)
        XCTAssertEqual(harness.controller.activeActivities.count, 1)
        XCTAssertEqual(harness.feature.pinState, .pinned)
    }

    func testRapidLiveStopsIssueOnlyOneSystemEndAndRemainStoppable() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("Stop one Live activity")
        await harness.feature.startPinning()
        harness.controller.pauseEnds()

        let firstStop = Task { await harness.feature.cancelPinning() }
        await waitUntil { harness.controller.endCallCount == 1 }
        XCTAssertFalse(harness.feature.canTogglePin)

        let secondStop = Task { await harness.feature.cancelPinning() }
        await drainReadyTasks()
        XCTAssertEqual(harness.controller.endCallCount, 1)

        harness.controller.resumeEnds()
        await firstStop.value
        await secondStop.value

        XCTAssertEqual(harness.controller.endCallCount, 1)
        XCTAssertEqual(harness.feature.pinState, .unpinned)
        XCTAssertTrue(harness.feature.canTogglePin)
    }

    func testRapidMovesEnterOneBarrierAndPerformOneMutation() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("Move exactly once")
        let activitiesBaseline = harness.controller.activitiesCallCount
        harness.controller.pauseNextActivities()

        let firstMove = Task { try await harness.feature.archiveCurrentNote() }
        await waitUntil { harness.controller.hasPausedActivitiesCall }
        XCTAssertFalse(harness.feature.canArchive)

        let secondMove = Task { try await harness.feature.archiveCurrentNote() }
        await drainReadyTasks()

        XCTAssertEqual(harness.controller.activitiesCallCount, activitiesBaseline + 1)

        harness.controller.resumeActivities()
        try await firstMove.value
        try await secondMove.value

        XCTAssertEqual(harness.feature.library.map(\.body), ["Move exactly once"])
        XCTAssertEqual(harness.feature.currentNote?.body, "")
        XCTAssertEqual(try harness.notes().count, 2)
    }

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

        harness.feature.beginEditing()
        harness.feature.stageEditorText(
            proposedText: "尚未提交的草稿",
            markedTextActive: false
        )

        XCTAssertEqual(harness.feature.currentNote?.body, "初始内容")
        XCTAssertEqual(try harness.notes().first?.body, "初始内容")
        XCTAssertEqual(harness.controller.activeActivities.first?.body, "初始内容")

        harness.feature.stageEditorText(
            proposedText: "已经先保存的新内容",
            markedTextActive: false
        )
        try harness.feature.completeEditing()

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

    private func drainReadyTasks() async {
        for _ in 0 ..< 10 {
            await Task.yield()
        }
    }
}
