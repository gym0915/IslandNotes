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
}
