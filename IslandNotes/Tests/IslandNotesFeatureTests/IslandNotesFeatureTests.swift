import XCTest
@testable import IslandNotes

@MainActor
final class IslandNotesFeatureTests: XCTestCase {
    func testStagedEditorChangesDoNotLetAnOlderSaveOverwriteNewerTyping() async throws {
        let harness = try InMemoryFeatureHarness.make()
        try await harness.feature.bootstrap()

        let older = harness.feature.stageEditorText(
            proposedText: "Old note",
            markedTextActive: false
        )
        let latest = harness.feature.stageEditorText(
            proposedText: "Old note from library",
            markedTextActive: false
        )

        try harness.feature.persistStagedEditorText(older.acceptedText)
        XCTAssertEqual(harness.feature.editingText, latest.acceptedText)
        XCTAssertEqual(try harness.notes().first?.body, "")

        try harness.feature.persistStagedEditorText(latest.acceptedText)
        XCTAssertEqual(try harness.notes().first?.body, "Old note from library")
    }

    func testFirstLaunchCreatesOneBlankCurrentNote() async throws {
        let harness = try InMemoryFeatureHarness.make()

        try await harness.feature.bootstrap()

        let current = try XCTUnwrap(harness.feature.currentNote)
        let notes = try harness.notes()
        let workbenches = try harness.workbenches()

        XCTAssertEqual(current.body, "")
        XCTAssertTrue(harness.feature.library.isEmpty)
        XCTAssertEqual(harness.feature.pinState, .unpinned)
        XCTAssertFalse(harness.feature.canArchive)
        XCTAssertFalse(harness.feature.canPin)
        XCTAssertFalse(harness.feature.canDelete)
        XCTAssertTrue(harness.feature.canOpenLibrary)

        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.id, current.id)
        XCTAssertEqual(workbenches.count, 1)
        XCTAssertEqual(workbenches.first?.currentNoteID, current.id)
        XCTAssertTrue(harness.controller.activeActivities.isEmpty)
    }

    func testEditingAutoSavesVerbatimTextAndRestoresAfterFeatureRecreation() async throws {
        let harness = try InMemoryFeatureHarness.make()
        try await harness.feature.bootstrap()
        let originalID = try XCTUnwrap(harness.feature.currentNote?.id)
        let body = "明天 09:30 交方案\nRemember the café ☕️"

        try await harness.feature.editCurrentNote(
            proposedText: body,
            markedTextActive: false
        )

        XCTAssertEqual(harness.feature.currentNote?.body, body)
        XCTAssertEqual(try harness.notes().first(where: { $0.id == originalID })?.body, body)

        let recreatedFeature = IslandNotesFeature(
            modelContext: harness.context,
            liveActivityController: harness.controller
        )
        try await recreatedFeature.bootstrap()

        XCTAssertEqual(recreatedFeature.currentNote?.id, originalID)
        XCTAssertEqual(recreatedFeature.currentNote?.body, body)
    }

    func testBootstrapIsIdempotent() async throws {
        let harness = try InMemoryFeatureHarness.make()

        try await harness.feature.bootstrap()
        let originalID = try XCTUnwrap(harness.feature.currentNote?.id)
        try await harness.feature.bootstrap()

        XCTAssertEqual(harness.feature.currentNote?.id, originalID)
        XCTAssertEqual(try harness.notes().count, 1)
        XCTAssertEqual(try harness.workbenches().count, 1)
    }

    func testCorruptCurrentPointerCreatesBlankSlotWithoutOverwritingContent() async throws {
        let harness = try InMemoryFeatureHarness.make()
        let timestamp = Date(timeIntervalSince1970: 500)
        let preserved = NoteRecord(
            body: "这段内容必须保留",
            createdAt: timestamp,
            modifiedAt: timestamp
        )
        let brokenWorkbench = WorkbenchRecord(currentNoteID: UUID())
        harness.context.insert(preserved)
        harness.context.insert(brokenWorkbench)
        try harness.context.save()

        try await harness.feature.bootstrap()

        let current = try XCTUnwrap(harness.feature.currentNote)
        let notes = try harness.notes()
        let workbenches = try harness.workbenches()
        XCTAssertEqual(current.body, "")
        XCTAssertNotEqual(current.id, preserved.id)
        XCTAssertEqual(notes.count, 2)
        XCTAssertEqual(notes.first(where: { $0.id == preserved.id })?.body, "这段内容必须保留")
        XCTAssertEqual(workbenches.count, 1)
        XCTAssertEqual(workbenches.first?.currentNoteID, current.id)
    }
}
