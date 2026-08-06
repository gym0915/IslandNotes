import SwiftData
import XCTest
@testable import IslandNotes

@MainActor
final class NoteWorkspaceTests: XCTestCase {
    func testFirstBootstrapCreatesOneBlankCurrentNoteAndOneWorkbenchPointer() throws {
        let harness = try WorkspaceHarness.make()

        try harness.workspace.bootstrap()

        let current = try XCTUnwrap(harness.workspace.currentNote)
        XCTAssertEqual(current.body, "")
        XCTAssertTrue(harness.workspace.library.isEmpty)
        XCTAssertEqual(try harness.notes().map(\.id), [current.id])
        XCTAssertEqual(try harness.workbenches().map(\.currentNoteID), [current.id])
    }

    func testBootstrapRepairsInvalidPrimaryPointerAndRemovesRedundantWorkbenchRows() throws {
        let harness = try WorkspaceHarness.make(now: Date(timeIntervalSince1970: 9_000))
        let preservedID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!
        let preserved = NoteRecord(
            id: preservedID,
            body: "Preserve every committed field",
            contentVersion: 8,
            createdAt: Date(timeIntervalSince1970: 1_000),
            modifiedAt: Date(timeIntervalSince1970: 2_000)
        )
        harness.context.insert(preserved)
        harness.context.insert(WorkbenchRecord(currentNoteID: UUID()))
        harness.context.insert(
            WorkbenchRecord(singletonKey: "redundant", currentNoteID: preservedID)
        )
        try harness.context.save()

        try harness.workspace.bootstrap()

        let current = try XCTUnwrap(harness.workspace.currentNote)
        let preservedAfterRepair = try XCTUnwrap(
            harness.notes().first(where: { $0.id == preservedID })
        )
        XCTAssertNotEqual(current.id, preservedID)
        XCTAssertEqual(current.body, "")
        XCTAssertEqual(try harness.workbenches().map(\.currentNoteID), [current.id])
        XCTAssertEqual(harness.workspace.library.map(\.id), [preservedID])
        XCTAssertEqual(preservedAfterRepair.body, "Preserve every committed field")
        XCTAssertEqual(preservedAfterRepair.contentVersion, 8)
        XCTAssertEqual(preservedAfterRepair.createdAt, Date(timeIntervalSince1970: 1_000))
        XCTAssertEqual(preservedAfterRepair.modifiedAt, Date(timeIntervalSince1970: 2_000))
        XCTAssertEqual(preservedAfterRepair.archivedAt, preservedAfterRepair.modifiedAt)
    }

    func testBootstrapPutsEveryEligibleNoncurrentNoteInLibraryAndRemovesOrphanBlankSlots() throws {
        let harness = try WorkspaceHarness.make()
        let timestamp = Date(timeIntervalSince1970: 500)
        let current = NoteRecord(body: "Current", createdAt: timestamp, modifiedAt: timestamp)
        let orphanContent = NoteRecord(
            body: "Recover into Library",
            createdAt: timestamp,
            modifiedAt: timestamp.addingTimeInterval(10)
        )
        let orphanBlank = NoteRecord(createdAt: timestamp, modifiedAt: timestamp)
        harness.context.insert(current)
        harness.context.insert(orphanContent)
        harness.context.insert(orphanBlank)
        harness.context.insert(WorkbenchRecord(currentNoteID: current.id))
        try harness.context.save()

        try harness.workspace.bootstrap()

        XCTAssertEqual(harness.workspace.currentNote?.id, current.id)
        XCTAssertEqual(harness.workspace.library.map(\.id), [orphanContent.id])
        XCTAssertEqual(harness.workspace.library.map(\.archivedAt), [orphanContent.modifiedAt])
        XCTAssertEqual(try harness.notes().filter { $0.archivedAt == nil }.map(\.id), [current.id])
        XCTAssertEqual(Set(try harness.notes().map(\.id)), Set([current.id, orphanContent.id]))
    }

    func testBootstrapOrdersEqualLibraryTimesByStableID() throws {
        let harness = try WorkspaceHarness.make()
        let timestamp = Date(timeIntervalSince1970: 500)
        let current = NoteRecord(body: "Current", createdAt: timestamp, modifiedAt: timestamp)
        let firstID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
        let secondID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
        let second = NoteRecord(
            id: secondID,
            body: "Second",
            createdAt: timestamp,
            modifiedAt: timestamp,
            archivedAt: timestamp
        )
        let first = NoteRecord(
            id: firstID,
            body: "First",
            createdAt: timestamp,
            modifiedAt: timestamp,
            archivedAt: timestamp
        )
        harness.context.insert(current)
        harness.context.insert(second)
        harness.context.insert(first)
        harness.context.insert(WorkbenchRecord(currentNoteID: current.id))
        try harness.context.save()

        try harness.workspace.bootstrap()

        XCTAssertEqual(harness.workspace.library.map(\.id), [firstID, secondID])
    }

    func testCommitUpdatesOnlyCommittedContentFieldsAndKeepsTheCurrentPointer() throws {
        var instant = Date(timeIntervalSince1970: 1_000)
        let harness = try WorkspaceHarness.make(clock: { instant })
        try harness.workspace.bootstrap()
        let original = try XCTUnwrap(harness.workspace.currentNote)

        instant = Date(timeIntervalSince1970: 2_000)
        XCTAssertTrue(try harness.workspace.commitCurrentNote("Committed verbatim\n- item"))

        let committed = try XCTUnwrap(harness.workspace.currentNote)
        XCTAssertEqual(committed.id, original.id)
        XCTAssertEqual(committed.body, "Committed verbatim\n- item")
        XCTAssertEqual(committed.contentVersion, original.contentVersion + 1)
        XCTAssertEqual(committed.createdAt, original.createdAt)
        XCTAssertEqual(committed.modifiedAt, instant)
        XCTAssertNil(committed.archivedAt)
        XCTAssertEqual(try harness.workbenches().map(\.currentNoteID), [original.id])
    }

    func testMoveArchivesTheCurrentNoteAndCreatesExactlyOneBlankCurrentNoteAtomically() throws {
        var instant = Date(timeIntervalSince1970: 1_000)
        let harness = try WorkspaceHarness.make(clock: { instant })
        try harness.workspace.bootstrap()
        try harness.workspace.commitCurrentNote("Move me")
        let outgoing = try XCTUnwrap(harness.workspace.currentNote)

        instant = Date(timeIntervalSince1970: 3_000)
        XCTAssertTrue(try harness.workspace.moveCurrentNoteToLibrary())

        let current = try XCTUnwrap(harness.workspace.currentNote)
        XCTAssertNotEqual(current.id, outgoing.id)
        XCTAssertEqual(current.body, "")
        XCTAssertEqual(current.createdAt, instant)
        XCTAssertEqual(current.modifiedAt, instant)
        XCTAssertEqual(harness.workspace.library.map(\.id), [outgoing.id])
        XCTAssertEqual(harness.workspace.library.map(\.archivedAt), [instant])
        XCTAssertEqual(try harness.notes().filter { $0.archivedAt == nil }.map(\.id), [current.id])
        XCTAssertEqual(try harness.workbenches().map(\.currentNoteID), [current.id])
    }

    func testReplacementLosslesslySwapsANonblankCurrentNoteWithALibraryNote() throws {
        var instant = Date(timeIntervalSince1970: 1_000)
        let harness = try WorkspaceHarness.make(clock: { instant })
        try harness.workspace.bootstrap()
        try harness.workspace.commitCurrentNote("Library candidate")
        let libraryID = try XCTUnwrap(harness.workspace.currentNote?.id)
        instant = Date(timeIntervalSince1970: 2_000)
        try harness.workspace.moveCurrentNoteToLibrary()
        try harness.workspace.commitCurrentNote("Outgoing current")
        let outgoingID = try XCTUnwrap(harness.workspace.currentNote?.id)

        instant = Date(timeIntervalSince1970: 3_000)
        XCTAssertTrue(try harness.workspace.replaceCurrentNote(withLibraryNoteID: libraryID))

        XCTAssertEqual(harness.workspace.currentNote?.id, libraryID)
        XCTAssertEqual(harness.workspace.currentNote?.body, "Library candidate")
        XCTAssertNil(harness.workspace.currentNote?.archivedAt)
        XCTAssertEqual(harness.workspace.library.map(\.id), [outgoingID])
        XCTAssertEqual(harness.workspace.library.map(\.body), ["Outgoing current"])
        XCTAssertEqual(harness.workspace.library.map(\.archivedAt), [instant])
        XCTAssertEqual(try harness.notes().count, 2)
        XCTAssertEqual(try harness.workbenches().map(\.currentNoteID), [libraryID])
    }

    func testReplacementDeletesTheOutgoingBlankSlotInsteadOfCreatingABlankLibraryEntry() throws {
        let harness = try WorkspaceHarness.make()
        try harness.workspace.bootstrap()
        try harness.workspace.commitCurrentNote("Library candidate")
        let libraryID = try XCTUnwrap(harness.workspace.currentNote?.id)
        try harness.workspace.moveCurrentNoteToLibrary()
        let blankID = try XCTUnwrap(harness.workspace.currentNote?.id)

        XCTAssertTrue(try harness.workspace.replaceCurrentNote(withLibraryNoteID: libraryID))

        XCTAssertEqual(harness.workspace.currentNote?.id, libraryID)
        XCTAssertTrue(harness.workspace.library.isEmpty)
        XCTAssertEqual(try harness.notes().map(\.id), [libraryID])
        XCTAssertFalse(try harness.notes().contains(where: { $0.id == blankID }))
    }

    func testDeleteRemovesTheCurrentRecordAndCreatesExactlyOneBlankReplacement() throws {
        var instant = Date(timeIntervalSince1970: 1_000)
        let harness = try WorkspaceHarness.make(clock: { instant })
        try harness.workspace.bootstrap()
        try harness.workspace.commitCurrentNote("Delete me")
        let deletedID = try XCTUnwrap(harness.workspace.currentNote?.id)

        instant = Date(timeIntervalSince1970: 4_000)
        XCTAssertTrue(try harness.workspace.deleteCurrentNote())

        let current = try XCTUnwrap(harness.workspace.currentNote)
        XCTAssertNotEqual(current.id, deletedID)
        XCTAssertEqual(current.body, "")
        XCTAssertEqual(current.createdAt, instant)
        XCTAssertEqual(current.modifiedAt, instant)
        XCTAssertTrue(harness.workspace.library.isEmpty)
        XCTAssertEqual(try harness.notes().map(\.id), [current.id])
        XCTAssertEqual(try harness.workbenches().map(\.currentNoteID), [current.id])
    }

    func testFailedMoveRollsBackManagedRecordsAndKeepsPublishedSnapshotsUnchanged() throws {
        let storeCopy = try LegacyStoreFixture.copy()
        let harness = try WorkspaceHarness.make(
            storeURL: storeCopy.storeURL,
            allowsSave: false
        )
        try harness.workspace.bootstrap()
        let currentBefore = harness.workspace.currentNote
        let libraryBefore = harness.workspace.library
        let notesBefore = try harness.noteSnapshots()
        let pointersBefore = try harness.workbenches().map(\.currentNoteID)
        var saveError: NSError?

        do {
            try harness.workspace.moveCurrentNoteToLibrary()
        } catch {
            saveError = error as NSError
        }

        XCTAssertEqual(saveError?.domain, NSCocoaErrorDomain)
        XCTAssertEqual(saveError?.code, NSFileWriteNoPermissionError)
        XCTAssertEqual(harness.workspace.currentNote, currentBefore)
        XCTAssertEqual(harness.workspace.library, libraryBefore)
        XCTAssertEqual(try harness.noteSnapshots(), notesBefore)
        XCTAssertEqual(try harness.workbenches().map(\.currentNoteID), pointersBefore)
        XCTAssertFalse(harness.context.hasChanges)
    }
}

@MainActor
private final class WorkspaceHarness {
    let container: ModelContainer
    let context: ModelContext
    let workspace: NoteWorkspace

    private init(container: ModelContainer, context: ModelContext, workspace: NoteWorkspace) {
        self.container = container
        self.context = context
        self.workspace = workspace
    }

    static func make(now: Date = Date(timeIntervalSince1970: 1_000)) throws -> WorkspaceHarness {
        try make(clock: { now })
    }

    static func make(clock: @escaping () -> Date) throws -> WorkspaceHarness {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: NoteRecord.self,
            WorkbenchRecord.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        let workspace = NoteWorkspace(modelContext: context, now: clock)
        return WorkspaceHarness(container: container, context: context, workspace: workspace)
    }

    static func make(storeURL: URL, allowsSave: Bool) throws -> WorkspaceHarness {
        let configuration = ModelConfiguration(url: storeURL, allowsSave: allowsSave)
        let container = try ModelContainer(
            for: NoteRecord.self,
            WorkbenchRecord.self,
            configurations: configuration
        )
        let context = ModelContext(container)
        let workspace = NoteWorkspace(
            modelContext: context,
            now: { Date(timeIntervalSince1970: 9_000) }
        )
        return WorkspaceHarness(container: container, context: context, workspace: workspace)
    }

    func notes() throws -> [NoteRecord] {
        try context.fetch(FetchDescriptor<NoteRecord>())
    }

    func workbenches() throws -> [WorkbenchRecord] {
        try context.fetch(FetchDescriptor<WorkbenchRecord>())
    }

    func noteSnapshots() throws -> [NoteSnapshot] {
        try notes()
            .map(NoteSnapshot.init)
            .sorted { $0.id.uuidString < $1.id.uuidString }
    }
}
