import XCTest
@testable import IslandNotes

@MainActor
final class LegacyStoreRecoveryTests: XCTestCase {
    func testBootstrapPreservesEveryFieldFromTheLegacyStore() async throws {
        let storeCopy = try LegacyStoreFixture.copy()
        let harness = try storeCopy.makeHarness()

        try await harness.feature.bootstrap()

        let current = try XCTUnwrap(harness.feature.currentNote)
        XCTAssertEqual(current.id, LegacyStoreFixture.currentNoteID)
        XCTAssertEqual(current.body, "Existing current note\n- keep every byte")
        XCTAssertEqual(current.contentVersion, 7)
        XCTAssertEqual(current.createdAt, Date(timeIntervalSince1970: 1_000))
        XCTAssertEqual(current.modifiedAt, Date(timeIntervalSince1970: 2_000))
        XCTAssertNil(current.archivedAt)

        XCTAssertEqual(harness.feature.library.map(\.id), LegacyStoreFixture.libraryNoteIDs)
        let newestLibraryNote = try XCTUnwrap(harness.feature.library.first)
        XCTAssertEqual(newestLibraryNote.body, "Most recently archived")
        XCTAssertEqual(newestLibraryNote.contentVersion, 4)
        XCTAssertEqual(newestLibraryNote.createdAt, Date(timeIntervalSince1970: 3_000))
        XCTAssertEqual(newestLibraryNote.modifiedAt, Date(timeIntervalSince1970: 4_000))
        XCTAssertEqual(newestLibraryNote.archivedAt, Date(timeIntervalSince1970: 6_000))
        let olderLibraryNote = try XCTUnwrap(harness.feature.library.last)
        XCTAssertEqual(olderLibraryNote.body, "Older archived note")
        XCTAssertEqual(olderLibraryNote.contentVersion, 2)
        XCTAssertEqual(olderLibraryNote.createdAt, Date(timeIntervalSince1970: 1_500))
        XCTAssertEqual(olderLibraryNote.modifiedAt, Date(timeIntervalSince1970: 2_500))
        XCTAssertEqual(olderLibraryNote.archivedAt, Date(timeIntervalSince1970: 5_000))
        XCTAssertEqual(try harness.notes().count, 3)
        XCTAssertEqual(try harness.workbenches().map(\.currentNoteID), [current.id])
        XCTAssertEqual(harness.feature.pinState, .unpinned)
        XCTAssertTrue(harness.controller.activeActivities.isEmpty)
    }

    func testMutatedLegacyStoreRecoversAfterClosingAndReopeningTheSameCopy() async throws {
        let storeCopy = try LegacyStoreFixture.copy()
        let replacementID: UUID
        do {
            let first = try storeCopy.makeHarness()
            try await first.feature.bootstrap()
            try await first.feature.archiveCurrentNote()
            replacementID = try XCTUnwrap(first.feature.currentNote?.id)
        }

        let reopened = try storeCopy.makeHarness()
        try await reopened.feature.bootstrap()

        XCTAssertEqual(reopened.feature.currentNote?.id, replacementID)
        XCTAssertEqual(reopened.feature.currentNote?.body, "")
        XCTAssertEqual(
            reopened.feature.library.map(\.id),
            [LegacyStoreFixture.currentNoteID] + LegacyStoreFixture.libraryNoteIDs
        )
        XCTAssertEqual(try reopened.notes().count, 4)
        XCTAssertEqual(try reopened.workbenches().map(\.currentNoteID), [replacementID])
    }
}
