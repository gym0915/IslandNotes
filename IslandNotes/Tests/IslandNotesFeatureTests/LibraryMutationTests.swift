import XCTest
@testable import IslandNotes

@MainActor
final class LibraryMutationTests: XCTestCase {
    func testUnicodeWhitespaceIsPreservedButKeepsContentActionsDisabled() async throws {
        let harness = try FeatureHarness.make()
        let whitespace = " \n\t\u{00A0}\u{2003}\u{3000}"
        try await harness.feature.bootstrap()

        try harness.commitCurrentNote(whitespace)

        XCTAssertEqual(harness.feature.currentNote?.body, whitespace)
        XCTAssertEqual(try harness.notes().first?.body, whitespace)
        XCTAssertFalse(harness.feature.canArchive)
        XCTAssertFalse(harness.feature.canPin)
        XCTAssertFalse(harness.feature.canDelete)
        XCTAssertTrue(harness.feature.canOpenLibrary)
    }

    func testArchivingReplacesCurrentWithBlankAndOrdersLibraryNewestFirst() async throws {
        var instant = Date(timeIntervalSince1970: 1_000)
        let harness = try FeatureHarness.make(clock: { instant })
        try await harness.feature.bootstrap()

        try harness.commitCurrentNote("第一条")
        let firstID = try XCTUnwrap(harness.feature.currentNote?.id)
        try await harness.feature.archiveCurrentNote()

        XCTAssertEqual(harness.feature.currentNote?.body, "")
        XCTAssertEqual(harness.feature.library.map(\.body), ["第一条"])
        XCTAssertEqual(harness.feature.library.first?.id, firstID)
        XCTAssertEqual(harness.feature.pinState, .unpinned)

        instant = Date(timeIntervalSince1970: 2_000)
        try harness.commitCurrentNote("第二条")
        try await harness.feature.archiveCurrentNote()

        XCTAssertEqual(harness.feature.currentNote?.body, "")
        XCTAssertEqual(harness.feature.library.map(\.body), ["第二条", "第一条"])
        XCTAssertEqual(try harness.notes().count, 3)
        XCTAssertEqual(try harness.workbenches().count, 1)
        XCTAssertEqual(
            try harness.workbenches().first?.currentNoteID,
            harness.feature.currentNote?.id
        )
    }

    func testSelectingLibraryNoteAtomicallySwapsWithNonblankCurrentNote() async throws {
        var instant = Date(timeIntervalSince1970: 1_000)
        let harness = try FeatureHarness.make(clock: { instant })
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("旧便签")
        let oldID = try XCTUnwrap(harness.feature.currentNote?.id)
        try await harness.feature.archiveCurrentNote()

        instant = Date(timeIntervalSince1970: 2_000)
        try harness.commitCurrentNote("当前内容")
        let currentID = try XCTUnwrap(harness.feature.currentNote?.id)

        try await harness.feature.selectLibraryNote(id: oldID)

        XCTAssertEqual(harness.feature.currentNote?.id, oldID)
        XCTAssertEqual(harness.feature.currentNote?.body, "旧便签")
        XCTAssertNil(harness.feature.currentNote?.archivedAt)
        XCTAssertEqual(harness.feature.library.map(\.id), [currentID])
        XCTAssertEqual(harness.feature.library.map(\.body), ["当前内容"])
        XCTAssertEqual(harness.feature.pinState, .unpinned)
        XCTAssertEqual(try harness.notes().count, 2)
    }

    func testSelectingLibraryNoteRemovesBlankCurrentSlotInsteadOfArchivingIt() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("要取回的便签")
        let archivedID = try XCTUnwrap(harness.feature.currentNote?.id)
        try await harness.feature.archiveCurrentNote()
        let blankID = try XCTUnwrap(harness.feature.currentNote?.id)

        try await harness.feature.selectLibraryNote(id: archivedID)

        XCTAssertEqual(harness.feature.currentNote?.id, archivedID)
        XCTAssertEqual(harness.feature.currentNote?.body, "要取回的便签")
        XCTAssertTrue(harness.feature.library.isEmpty)
        XCTAssertEqual(try harness.notes().map(\.id), [archivedID])
        XCTAssertFalse(try harness.notes().contains(where: { $0.id == blankID }))
    }

    func testSelectingMissingLibraryNoteHasNoSideEffects() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        let originalID = try XCTUnwrap(harness.feature.currentNote?.id)

        try await harness.feature.selectLibraryNote(id: UUID())

        XCTAssertEqual(harness.feature.currentNote?.id, originalID)
        XCTAssertEqual(try harness.notes().count, 1)
        XCTAssertTrue(harness.feature.library.isEmpty)
    }

    func testDeleteRequiresConfirmationAndCancelHasNoSideEffects() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("不能误删")
        let originalID = try XCTUnwrap(harness.feature.currentNote?.id)

        harness.feature.requestDelete()

        let confirmation = try XCTUnwrap(harness.feature.deleteConfirmation)
        guard case let .pending(message) = confirmation else {
            return XCTFail("Expected a pending delete confirmation")
        }
        XCTAssertEqual(
            message,
            "This note will be permanently deleted. This action cannot be undone."
        )
        XCTAssertEqual(harness.feature.currentNote?.id, originalID)
        XCTAssertEqual(try harness.notes().count, 1)

        harness.feature.cancelDelete()

        XCTAssertNil(harness.feature.deleteConfirmation)
        XCTAssertEqual(harness.feature.currentNote?.id, originalID)
        XCTAssertEqual(try harness.notes().first?.body, "不能误删")
    }

    func testConfirmedDeleteCreatesBlankCurrentNote() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("确认删除")
        let deletedID = try XCTUnwrap(harness.feature.currentNote?.id)
        harness.feature.requestDelete()

        try await harness.feature.confirmDeleteCurrentNote()

        let replacement = try XCTUnwrap(harness.feature.currentNote)
        XCTAssertNotEqual(replacement.id, deletedID)
        XCTAssertEqual(replacement.body, "")
        XCTAssertNil(harness.feature.deleteConfirmation)
        XCTAssertEqual(harness.feature.pinState, .unpinned)
        XCTAssertTrue(harness.feature.library.isEmpty)
        XCTAssertEqual(try harness.notes().map(\.id), [replacement.id])
        XCTAssertEqual(try harness.workbenches().first?.currentNoteID, replacement.id)
    }

    func testBlankCurrentNoteCannotRequestDeletion() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()

        harness.feature.requestDelete()

        XCTAssertFalse(harness.feature.canDelete)
        XCTAssertNil(harness.feature.deleteConfirmation)
        XCTAssertEqual(try harness.notes().count, 1)
    }
}
