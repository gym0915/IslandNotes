import XCTest
@testable import IslandNotes

@MainActor
final class PersistenceInvariantTests: XCTestCase {
    func testArchiveCommitsOneNewCurrentNoteAndTheLibraryMoveTogether() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("Current before archive")
        let archivedID = try XCTUnwrap(harness.feature.currentNote?.id)

        try await harness.feature.archiveCurrentNote()

        let current = try XCTUnwrap(harness.feature.currentNote)
        let notes = try harness.notes()
        XCTAssertNotEqual(current.id, archivedID)
        XCTAssertEqual(current.body, "")
        XCTAssertEqual(notes.filter { $0.archivedAt == nil }.map(\.id), [current.id])
        XCTAssertEqual(notes.filter { $0.archivedAt != nil }.map(\.id), [archivedID])
        XCTAssertEqual(try harness.workbenches().map(\.currentNoteID), [current.id])
        XCTAssertEqual(harness.feature.library.map(\.id), [archivedID])
    }

    func testLibrarySwapCommitsOneCurrentNoteAndArchivesThePreviousCurrentTogether() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("Library candidate")
        let libraryID = try XCTUnwrap(harness.feature.currentNote?.id)
        try await harness.feature.archiveCurrentNote()
        try harness.commitCurrentNote("Current before swap")
        let previousCurrentID = try XCTUnwrap(harness.feature.currentNote?.id)

        try await harness.feature.selectLibraryNote(id: libraryID)

        let notes = try harness.notes()
        XCTAssertEqual(harness.feature.currentNote?.id, libraryID)
        XCTAssertEqual(notes.filter { $0.archivedAt == nil }.map(\.id), [libraryID])
        XCTAssertEqual(notes.filter { $0.archivedAt != nil }.map(\.id), [previousCurrentID])
        XCTAssertEqual(try harness.workbenches().map(\.currentNoteID), [libraryID])
        XCTAssertEqual(harness.feature.library.map(\.id), [previousCurrentID])
    }

    func testDeleteCommitsRemovalAndExactlyOneBlankReplacementTogether() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("Current before delete")
        let deletedID = try XCTUnwrap(harness.feature.currentNote?.id)
        harness.feature.requestDelete()

        try await harness.feature.confirmDeleteCurrentNote()

        let current = try XCTUnwrap(harness.feature.currentNote)
        let notes = try harness.notes()
        XCTAssertNotEqual(current.id, deletedID)
        XCTAssertEqual(notes.map(\.id), [current.id])
        XCTAssertEqual(notes.map(\.body), [""])
        XCTAssertEqual(notes.filter { $0.archivedAt == nil }.count, 1)
        XCTAssertEqual(try harness.workbenches().map(\.currentNoteID), [current.id])
        XCTAssertTrue(harness.feature.library.isEmpty)
    }

    func testArchiveDoesNotBeginItsTransactionUntilTheActivityEndBarrierClears() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("Archive must wait")
        let current = try XCTUnwrap(harness.feature.currentNote)
        try await assertEndBarrierBlocks(harness: harness, current: current) {
            try await harness.feature.archiveCurrentNote()
        }
    }

    func testLibrarySwapDoesNotBeginItsTransactionUntilTheActivityEndBarrierClears() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("Library candidate")
        let libraryID = try XCTUnwrap(harness.feature.currentNote?.id)
        try await harness.feature.archiveCurrentNote()
        try harness.commitCurrentNote("Swap must wait")
        let current = try XCTUnwrap(harness.feature.currentNote)
        try await assertEndBarrierBlocks(harness: harness, current: current) {
            try await harness.feature.selectLibraryNote(id: libraryID)
        }
        XCTAssertEqual(harness.feature.library.map(\.id), [libraryID])
    }

    func testDeleteDoesNotBeginItsTransactionUntilTheActivityEndBarrierClears() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("Delete must wait")
        let current = try XCTUnwrap(harness.feature.currentNote)
        harness.feature.requestDelete()
        try await assertEndBarrierBlocks(harness: harness, current: current) {
            try await harness.feature.confirmDeleteCurrentNote()
        }
        XCTAssertNotNil(harness.feature.deleteConfirmation)
    }

    func testArchiveSaveFailureRollsBackEveryPersistedAndObservableChange() async throws {
        let storeCopy = try LegacyStoreFixture.copy()
        let harness = try storeCopy.makeHarness(allowsSave: false)
        try await harness.feature.bootstrap()

        try await assertSaveFailureRollsBack(harness: harness, storeCopy: storeCopy) {
            try await harness.feature.archiveCurrentNote()
        }
    }

    func testLibrarySwapSaveFailureRollsBackEveryPersistedAndObservableChange() async throws {
        let storeCopy = try LegacyStoreFixture.copy()
        let harness = try storeCopy.makeHarness(allowsSave: false)
        try await harness.feature.bootstrap()
        let libraryID = try XCTUnwrap(harness.feature.library.first?.id)

        try await assertSaveFailureRollsBack(harness: harness, storeCopy: storeCopy) {
            try await harness.feature.selectLibraryNote(id: libraryID)
        }
    }

    func testDeleteSaveFailureRollsBackEveryPersistedAndObservableChange() async throws {
        let storeCopy = try LegacyStoreFixture.copy()
        let harness = try storeCopy.makeHarness(allowsSave: false)
        try await harness.feature.bootstrap()
        harness.feature.requestDelete()

        try await assertSaveFailureRollsBack(harness: harness, storeCopy: storeCopy) {
            try await harness.feature.confirmDeleteCurrentNote()
        }
        XCTAssertNotNil(harness.feature.deleteConfirmation)
    }

    private func seedStuckActivity(
        for note: NoteSnapshot,
        in harness: FeatureHarness
    ) {
        harness.controller.seedActivities([
            ActivitySession(
                activityID: "stuck-current",
                noteID: note.id,
                body: note.body,
                version: note.contentVersion,
                isActive: true
            )
        ])
        harness.controller.endOutcome = .keepThenThrow
    }

    private func assertEndBarrierBlocks(
        harness: FeatureHarness,
        current: NoteSnapshot,
        mutation: () async throws -> Void
    ) async throws {
        let before = try persistedState(of: harness)
        seedStuckActivity(for: current, in: harness)

        try await mutation()

        XCTAssertEqual(try persistedState(of: harness), before)
        XCTAssertEqual(harness.feature.currentNote, current)
        XCTAssertEqual(harness.controller.activeActivities.map(\.noteID), [current.id])
        XCTAssertEqual(harness.feature.pinState, .pinned)
    }

    private func assertSaveFailureRollsBack(
        harness: FeatureHarness,
        storeCopy: LegacyStoreCopy,
        mutation: () async throws -> Void
    ) async throws {
        let persistedBefore = try persistedState(of: harness)
        let currentBefore = harness.feature.currentNote
        let libraryBefore = harness.feature.library
        var saveError: NSError?

        do {
            try await mutation()
        } catch {
            saveError = error as NSError
        }

        XCTAssertEqual(saveError?.domain, NSCocoaErrorDomain)
        XCTAssertEqual(saveError?.code, NSFileWriteNoPermissionError)
        XCTAssertEqual(harness.feature.currentNote, currentBefore)
        XCTAssertEqual(harness.feature.library, libraryBefore)
        XCTAssertTrue(harness.controller.activeActivities.isEmpty)
        XCTAssertNotNil(harness.feature.feedbackMessage)

        let reopened = try storeCopy.makeHarness(allowsSave: false)
        try await reopened.feature.bootstrap()
        XCTAssertEqual(try persistedState(of: reopened), persistedBefore)
        XCTAssertEqual(reopened.feature.currentNote, currentBefore)
        XCTAssertEqual(reopened.feature.library, libraryBefore)
    }

    private func persistedState(
        of harness: FeatureHarness
    ) throws -> PersistedWorkspaceState {
        PersistedWorkspaceState(
            notes: try harness.notes()
                .map(PersistedNote.init)
                .sorted { $0.id.uuidString < $1.id.uuidString },
            currentNoteIDs: try harness.workbenches()
                .map(\.currentNoteID)
                .sorted { $0.uuidString < $1.uuidString }
        )
    }
}

private struct PersistedWorkspaceState: Equatable {
    let notes: [PersistedNote]
    let currentNoteIDs: [UUID]
}

private struct PersistedNote: Equatable {
    let id: UUID
    let body: String
    let contentVersion: Int
    let createdAt: Date
    let modifiedAt: Date
    let archivedAt: Date?

    init(record: NoteRecord) {
        id = record.id
        body = record.body
        contentVersion = record.contentVersion
        createdAt = record.createdAt
        modifiedAt = record.modifiedAt
        archivedAt = record.archivedAt
    }
}
