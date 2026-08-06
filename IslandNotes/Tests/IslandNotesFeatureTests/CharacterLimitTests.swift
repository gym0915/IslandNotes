import XCTest
@testable import IslandNotes

@MainActor
final class CharacterLimitTests: XCTestCase {
    func test239Accepts240And241TruncatesAtCharacterBoundary() {
        let first239 = String(repeating: "字", count: 239)

        let atLimit = TextLimiter.limit(
            proposedText: first239 + "A",
            markedTextActive: false
        )
        let overLimit = TextLimiter.limit(
            proposedText: first239 + "AB",
            markedTextActive: false
        )

        XCTAssertEqual(atLimit.acceptedText.count, 240)
        XCTAssertFalse(atLimit.wasTruncated)
        XCTAssertTrue(atLimit.isAtLimit)
        XCTAssertEqual(overLimit.acceptedText, first239 + "A")
        XCTAssertTrue(overLimit.wasTruncated)
        XCTAssertTrue(overLimit.isAtLimit)
    }

    func testOverLimitPasteKeepsComplexGraphemesWhole() {
        let family = "👨🏽‍👩🏻‍👧🏾‍👦🏼"
        let proposal = String(repeating: family, count: 241)

        let result = TextLimiter.limit(
            proposedText: proposal,
            markedTextActive: false
        )

        XCTAssertEqual(result.acceptedText.count, 240)
        XCTAssertEqual(result.acceptedText, String(repeating: family, count: 240))
        XCTAssertTrue(result.wasTruncated)
    }

    func testMarkedTextIsLimitedOnlyAfterCommit() {
        let composing = String(repeating: "界", count: 241)

        let intermediate = TextLimiter.limit(
            proposedText: composing,
            markedTextActive: true
        )
        let committed = TextLimiter.limit(
            proposedText: composing,
            markedTextActive: false
        )

        XCTAssertEqual(intermediate.acceptedText, composing)
        XCTAssertFalse(intermediate.wasTruncated)
        XCTAssertEqual(committed.acceptedText.count, 240)
        XCTAssertTrue(committed.wasTruncated)
    }

    func testFullValueStillAllowsDeletionAndShorterReplacement() {
        let full = String(repeating: "A", count: 240)

        let deleted = TextLimiter.limit(
            proposedText: String(full.dropLast()),
            markedTextActive: false
        )
        let replacement = TextLimiter.limit(
            proposedText: String(repeating: "B", count: 240),
            markedTextActive: false
        )

        XCTAssertEqual(deleted.acceptedText.count, 239)
        XCTAssertFalse(deleted.wasTruncated)
        XCTAssertEqual(replacement.acceptedText, String(repeating: "B", count: 240))
        XCTAssertFalse(replacement.wasTruncated)
    }

    func testFeatureDefersMarkedTextAndExposesAccurateProgressAfterReveal() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        let composing = String(repeating: "文", count: 241)
        harness.feature.beginEditing()

        _ = harness.feature.stageEditorText(
            proposedText: composing,
            markedTextActive: true
        )

        XCTAssertEqual(harness.feature.editingText, composing)
        XCTAssertEqual(harness.feature.currentNote?.body, "")
        XCTAssertFalse(harness.feature.isCharacterCountVisible)

        harness.feature.stageEditorText(
            proposedText: composing,
            markedTextActive: false
        )
        try harness.feature.completeEditing()
        harness.feature.revealCharacterCount()

        XCTAssertEqual(harness.feature.currentNote?.body.count, 240)
        XCTAssertTrue(harness.feature.didReachCharacterLimit)
        XCTAssertTrue(harness.feature.isCharacterCountVisible)
        XCTAssertEqual(harness.feature.characterProgress.used, 240)
        XCTAssertEqual(harness.feature.characterProgress.remaining, 0)
    }

    func testDoneFinalizesOutstandingMarkedTextAtCharacterBoundary() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        let composing = String(repeating: "界", count: 241)
        harness.feature.beginEditing()
        harness.feature.stageEditorText(
            proposedText: composing,
            markedTextActive: true
        )

        try harness.feature.completeEditing()

        XCTAssertEqual(harness.feature.currentNote?.body, String(repeating: "界", count: 240))
        XCTAssertFalse(harness.feature.isEditing)
    }

    func testFeatureProgressUsesCommittedSourceInDisplayAndDraftWhileEditing() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("12345")

        XCTAssertFalse(harness.feature.isEditing)
        XCTAssertEqual(harness.feature.characterProgress, CharacterProgress(used: 5, remaining: 235))

        harness.feature.beginEditing()
        harness.feature.stageEditorText(
            proposedText: "👨‍👩‍👧‍👦\n字",
            markedTextActive: false
        )

        XCTAssertEqual(harness.feature.currentNote?.body, "12345")
        XCTAssertEqual(harness.feature.characterProgress, CharacterProgress(used: 3, remaining: 237))
    }

    func testCharacterCountIncludesListPrefixSpacesPunctuationAndNewlines() {
        let source = "- 项目，A!\n下一行"

        let result = TextLimiter.limit(
            proposedText: source,
            markedTextActive: false
        )

        XCTAssertEqual(result.acceptedText, source)
        XCTAssertEqual(result.acceptedText.count, 11)
        XCTAssertFalse(result.wasTruncated)
    }

    func testRepeatedCharacterDetailTapResetsTheAutoHideWindow() async throws {
        let scheduler = ManualCharacterDetailScheduler()
        let harness = try FeatureHarness.make(
            characterDetailScheduler: CharacterDetailScheduler(schedule: scheduler.schedule)
        )
        try await harness.feature.bootstrap()

        harness.feature.revealCharacterCount()
        let firstTimer = try XCTUnwrap(scheduler.latestID)
        XCTAssertTrue(harness.feature.isCharacterCountVisible)

        harness.feature.revealCharacterCount()
        let secondTimer = try XCTUnwrap(scheduler.latestID)
        XCTAssertNotEqual(firstTimer, secondTimer)
        XCTAssertTrue(scheduler.isCancelled(firstTimer))

        scheduler.fire(firstTimer)
        XCTAssertTrue(harness.feature.isCharacterCountVisible)

        scheduler.fire(secondTimer)
        XCTAssertFalse(harness.feature.isCharacterCountVisible)
    }
}

@MainActor
private final class ManualCharacterDetailScheduler {
    private var nextID = 0
    private var actions: [Int: @MainActor () -> Void] = [:]
    private var cancelled: Set<Int> = []
    private(set) var latestID: Int?

    func schedule(_ action: @escaping @MainActor () -> Void) -> CharacterDetailCancellation {
        nextID += 1
        let id = nextID
        latestID = id
        actions[id] = action
        return CharacterDetailCancellation { [weak self] in
            self?.cancelled.insert(id)
        }
    }

    func isCancelled(_ id: Int) -> Bool {
        cancelled.contains(id)
    }

    func fire(_ id: Int) {
        guard !cancelled.contains(id) else { return }
        actions.removeValue(forKey: id)?()
    }
}
