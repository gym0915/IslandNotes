import XCTest
@testable import IslandNotes

@MainActor
final class IslandNotesFeatureTests: XCTestCase {
    func testFirstLaunchCreatesOneBlankCurrentNote() async throws {
        let harness = try FeatureHarness.make()

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
        XCTAssertFalse(harness.feature.isEditing)
        XCTAssertNil(harness.feature.editingDraft)
    }

    func testBeginningAndStagingAnEditChangesOnlyTheInMemoryDraft() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("Committed source\n- first")
        let committedVersion = try XCTUnwrap(harness.feature.currentNote?.contentVersion)

        harness.feature.beginEditing()
        let result = harness.feature.stageEditorText(
            proposedText: "Draft source\n- second",
            markedTextActive: false
        )

        XCTAssertTrue(harness.feature.isEditing)
        XCTAssertEqual(harness.feature.editingDraft, "Draft source\n- second")
        XCTAssertEqual(result.acceptedText, "Draft source\n- second")
        XCTAssertEqual(harness.feature.currentNote?.body, "Committed source\n- first")
        XCTAssertEqual(harness.feature.currentNote?.contentVersion, committedVersion)
        XCTAssertEqual(try harness.notes().first?.body, "Committed source\n- first")
        XCTAssertEqual(try harness.notes().first?.contentVersion, committedVersion)
    }

    func testDoneCommitsDraftUpdatesVersionAndReturnsToDisplay() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        let originalVersion = try XCTUnwrap(harness.feature.currentNote?.contentVersion)

        harness.feature.beginEditing()
        harness.feature.stageEditorText(
            proposedText: "Committed with Done",
            markedTextActive: false
        )
        try harness.feature.completeEditing()

        XCTAssertFalse(harness.feature.isEditing)
        XCTAssertNil(harness.feature.editingDraft)
        XCTAssertEqual(harness.feature.currentNote?.body, "Committed with Done")
        XCTAssertEqual(harness.feature.currentNote?.contentVersion, originalVersion + 1)
        XCTAssertEqual(try harness.notes().first?.body, "Committed with Done")
        XCTAssertEqual(try harness.notes().first?.contentVersion, originalVersion + 1)
    }

    func testFailedDoneKeepsExactDraftAndEditingState() async throws {
        let storeCopy = try LegacyStoreFixture.copy()
        let harness = try storeCopy.makeHarness(allowsSave: false)
        try await harness.feature.bootstrap()
        let committed = try XCTUnwrap(harness.feature.currentNote)
        let draft = "Unsaved draft\n- still here 👨‍👩‍👧‍👦"
        harness.feature.beginEditing()
        harness.feature.stageEditorText(
            proposedText: draft,
            markedTextActive: false
        )
        var saveError: NSError?

        do {
            try harness.feature.completeEditing()
        } catch {
            saveError = error as NSError
        }

        XCTAssertEqual(saveError?.domain, NSCocoaErrorDomain)
        XCTAssertEqual(saveError?.code, NSFileWriteNoPermissionError)
        XCTAssertTrue(harness.feature.isEditing)
        XCTAssertEqual(harness.feature.editingDraft, draft)
        XCTAssertEqual(harness.feature.currentNote, committed)
        XCTAssertEqual(try harness.notes().first(where: { $0.id == committed.id })?.body, committed.body)
        XCTAssertEqual(harness.feature.feedbackMessage, "Your note hasn't been saved.")
    }

    func testForegroundReconciliationDoesNotDiscardOrCommitAnEditingDraft() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("Committed before background")
        harness.feature.beginEditing()
        harness.feature.stageEditorText(
            proposedText: "Draft survives foreground reconciliation",
            markedTextActive: false
        )

        await harness.feature.reconcileActivities()

        XCTAssertTrue(harness.feature.isEditing)
        XCTAssertEqual(harness.feature.editingDraft, "Draft survives foreground reconciliation")
        XCTAssertEqual(harness.feature.currentNote?.body, "Committed before background")
        XCTAssertEqual(try harness.notes().first?.body, "Committed before background")
    }

    func testRecreatingFeatureDropsDraftAndRestoresOnlyCommittedSource() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        try harness.commitCurrentNote("Persisted source")
        harness.feature.beginEditing()
        harness.feature.stageEditorText(
            proposedText: "Uncommitted draft",
            markedTextActive: false
        )

        let recreatedFeature = IslandNotesFeature(
            modelContext: harness.context,
            liveActivityController: harness.controller
        )
        try await recreatedFeature.bootstrap()

        XCTAssertFalse(recreatedFeature.isEditing)
        XCTAssertNil(recreatedFeature.editingDraft)
        XCTAssertEqual(recreatedFeature.currentNote?.body, "Persisted source")
        XCTAssertEqual(harness.feature.editingDraft, "Uncommitted draft")
    }

    func testCommittedTextRestoresVerbatimAfterFeatureRecreation() async throws {
        let harness = try FeatureHarness.make()
        try await harness.feature.bootstrap()
        let originalID = try XCTUnwrap(harness.feature.currentNote?.id)
        let body = "明天 09:30 交方案\nRemember the café ☕️"

        try harness.commitCurrentNote(body)

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
        let harness = try FeatureHarness.make()

        try await harness.feature.bootstrap()
        let originalID = try XCTUnwrap(harness.feature.currentNote?.id)
        try await harness.feature.bootstrap()

        XCTAssertEqual(harness.feature.currentNote?.id, originalID)
        XCTAssertEqual(try harness.notes().count, 1)
        XCTAssertEqual(try harness.workbenches().count, 1)
    }

    func testCorruptCurrentPointerCreatesBlankSlotWithoutOverwritingContent() async throws {
        let harness = try FeatureHarness.make()
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
