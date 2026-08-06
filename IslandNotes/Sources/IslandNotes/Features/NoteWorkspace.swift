import Foundation
import Observation
import SwiftData

struct NoteSnapshot: Equatable, Identifiable, Sendable {
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

private struct WorkspaceCheckpoint {
    let notes: [NoteSnapshot]
    let workbenches: [WorkbenchCheckpoint]

    init(notes: [NoteRecord], workbenches: [WorkbenchRecord]) {
        self.notes = notes.map(NoteSnapshot.init)
        self.workbenches = workbenches.map(WorkbenchCheckpoint.init)
    }
}

private struct WorkbenchCheckpoint {
    let singletonKey: String
    let currentNoteID: UUID

    init(record: WorkbenchRecord) {
        singletonKey = record.singletonKey
        currentNoteID = record.currentNoteID
    }
}

@MainActor
@Observable
final class NoteWorkspace {
    private let modelContext: ModelContext
    private let now: () -> Date

    private(set) var currentNote: NoteSnapshot?
    private(set) var library: [NoteSnapshot] = []

    init(
        modelContext: ModelContext,
        now: @escaping () -> Date = Date.init
    ) {
        self.modelContext = modelContext
        self.now = now
    }

    func bootstrap() throws {
        let workbenches = try modelContext.fetch(FetchDescriptor<WorkbenchRecord>())
        let notes = try modelContext.fetch(FetchDescriptor<NoteRecord>())
        let checkpoint = WorkspaceCheckpoint(notes: notes, workbenches: workbenches)
        let primaryWorkbench = workbenches.first {
            $0.singletonKey == WorkbenchRecord.primaryKey
        }

        if let primaryWorkbench,
           let currentRecord = notes.first(where: { $0.id == primaryWorkbench.currentNoteID }) {
            var requiresSave = false
            for workbench in workbenches where workbench !== primaryWorkbench {
                modelContext.delete(workbench)
                requiresSave = true
            }

            let repair = repairNotes(notes, currentNoteID: currentRecord.id)
            requiresSave = requiresSave || repair.changed
            if requiresSave {
                try saveOrRollback(to: checkpoint)
            }
            refreshSnapshots(notes: repair.notes, currentNoteID: currentRecord.id)
            return
        }

        let timestamp = now()
        let note = NoteRecord(createdAt: timestamp, modifiedAt: timestamp)
        if let primaryWorkbench {
            primaryWorkbench.currentNoteID = note.id
        } else {
            modelContext.insert(WorkbenchRecord(currentNoteID: note.id))
        }
        workbenches
            .filter { $0 !== primaryWorkbench }
            .forEach(modelContext.delete)
        let repair = repairNotes(notes, currentNoteID: note.id)
        modelContext.insert(note)
        try saveOrRollback(to: checkpoint)
        refreshSnapshots(notes: repair.notes + [note], currentNoteID: note.id)
    }

    @discardableResult
    func commitCurrentNote(_ body: String) throws -> Bool {
        guard let currentNote else { return false }
        let notes = try modelContext.fetch(FetchDescriptor<NoteRecord>())
        guard let record = notes.first(where: { $0.id == currentNote.id }) else {
            return false
        }
        let checkpoint = WorkspaceCheckpoint(
            notes: notes,
            workbenches: try modelContext.fetch(FetchDescriptor<WorkbenchRecord>())
        )

        record.body = body
        record.contentVersion += 1
        record.modifiedAt = now()
        try saveOrRollback(to: checkpoint)
        refreshSnapshots(notes: notes, currentNoteID: record.id)
        return true
    }

    @discardableResult
    func moveCurrentNoteToLibrary() throws -> Bool {
        guard let currentNote, NoteContent.isActionable(currentNote.body) else {
            return false
        }
        let notes = try modelContext.fetch(FetchDescriptor<NoteRecord>())
        let workbenches = try modelContext.fetch(FetchDescriptor<WorkbenchRecord>())
        guard let record = notes.first(where: { $0.id == currentNote.id }),
              let workbench = workbenches.first(where: {
                  $0.singletonKey == WorkbenchRecord.primaryKey
              }) else {
            return false
        }
        let checkpoint = WorkspaceCheckpoint(notes: notes, workbenches: workbenches)

        let timestamp = now()
        let blank = NoteRecord(createdAt: timestamp, modifiedAt: timestamp)
        record.archivedAt = timestamp
        workbench.currentNoteID = blank.id
        modelContext.insert(blank)
        try saveOrRollback(to: checkpoint)
        refreshSnapshots(notes: notes + [blank], currentNoteID: blank.id)
        return true
    }

    @discardableResult
    func replaceCurrentNote(withLibraryNoteID id: UUID) throws -> Bool {
        guard library.contains(where: { $0.id == id }), let currentNote else {
            return false
        }
        let notes = try modelContext.fetch(FetchDescriptor<NoteRecord>())
        let workbenches = try modelContext.fetch(FetchDescriptor<WorkbenchRecord>())
        guard let selected = notes.first(where: { $0.id == id && $0.archivedAt != nil }),
              let currentRecord = notes.first(where: { $0.id == currentNote.id }),
              let workbench = workbenches.first(where: {
                  $0.singletonKey == WorkbenchRecord.primaryKey
              }) else {
            return false
        }
        let checkpoint = WorkspaceCheckpoint(notes: notes, workbenches: workbenches)

        selected.archivedAt = nil
        workbench.currentNoteID = selected.id

        let remainingNotes: [NoteRecord]
        if NoteContent.isActionable(currentRecord.body) {
            currentRecord.archivedAt = now()
            remainingNotes = notes
        } else {
            modelContext.delete(currentRecord)
            remainingNotes = notes.filter { $0.id != currentRecord.id }
        }

        try saveOrRollback(to: checkpoint)
        refreshSnapshots(notes: remainingNotes, currentNoteID: selected.id)
        return true
    }

    @discardableResult
    func deleteCurrentNote() throws -> Bool {
        guard let currentNote, NoteContent.isActionable(currentNote.body) else {
            return false
        }
        let notes = try modelContext.fetch(FetchDescriptor<NoteRecord>())
        let workbenches = try modelContext.fetch(FetchDescriptor<WorkbenchRecord>())
        guard let record = notes.first(where: { $0.id == currentNote.id }),
              let workbench = workbenches.first(where: {
                  $0.singletonKey == WorkbenchRecord.primaryKey
              }) else {
            return false
        }
        let checkpoint = WorkspaceCheckpoint(notes: notes, workbenches: workbenches)

        let timestamp = now()
        let blank = NoteRecord(createdAt: timestamp, modifiedAt: timestamp)
        modelContext.delete(record)
        modelContext.insert(blank)
        workbench.currentNoteID = blank.id
        try saveOrRollback(to: checkpoint)
        refreshSnapshots(
            notes: notes.filter { $0.id != record.id } + [blank],
            currentNoteID: blank.id
        )
        return true
    }

#if DEBUG
    func loadPreview(records: [NoteRecord], currentNoteID: UUID) {
        refreshSnapshots(notes: records, currentNoteID: currentNoteID)
    }
#endif

    private func saveOrRollback(to checkpoint: WorkspaceCheckpoint) throws {
        do {
            try modelContext.save()
        } catch let saveError {
            modelContext.rollback()
            try restore(checkpoint)
            modelContext.rollback()
            modelContext.processPendingChanges()
            throw saveError
        }
    }

    private func restore(_ checkpoint: WorkspaceCheckpoint) throws {
        let notes = try modelContext.fetch(FetchDescriptor<NoteRecord>())
        let checkpointNotes = Dictionary(uniqueKeysWithValues: checkpoint.notes.map { ($0.id, $0) })

        for record in notes {
            guard let saved = checkpointNotes[record.id] else {
                modelContext.delete(record)
                continue
            }
            record.body = saved.body
            record.contentVersion = saved.contentVersion
            record.createdAt = saved.createdAt
            record.modifiedAt = saved.modifiedAt
            record.archivedAt = saved.archivedAt
        }

        let restoredIDs = Set(notes.map(\.id))
        for saved in checkpoint.notes where !restoredIDs.contains(saved.id) {
            modelContext.insert(
                NoteRecord(
                    id: saved.id,
                    body: saved.body,
                    contentVersion: saved.contentVersion,
                    createdAt: saved.createdAt,
                    modifiedAt: saved.modifiedAt,
                    archivedAt: saved.archivedAt
                )
            )
        }

        let workbenches = try modelContext.fetch(FetchDescriptor<WorkbenchRecord>())
        let checkpointWorkbenches = Dictionary(
            uniqueKeysWithValues: checkpoint.workbenches.map { ($0.singletonKey, $0) }
        )
        for record in workbenches {
            guard let saved = checkpointWorkbenches[record.singletonKey] else {
                modelContext.delete(record)
                continue
            }
            record.currentNoteID = saved.currentNoteID
        }

        let restoredKeys = Set(workbenches.map(\.singletonKey))
        for saved in checkpoint.workbenches where !restoredKeys.contains(saved.singletonKey) {
            modelContext.insert(
                WorkbenchRecord(
                    singletonKey: saved.singletonKey,
                    currentNoteID: saved.currentNoteID
                )
            )
        }
        modelContext.processPendingChanges()
    }

    private func repairNotes(
        _ notes: [NoteRecord],
        currentNoteID: UUID
    ) -> (notes: [NoteRecord], changed: Bool) {
        var repaired: [NoteRecord] = []
        var changed = false

        for record in notes {
            if record.id == currentNoteID {
                if record.archivedAt != nil {
                    record.archivedAt = nil
                    changed = true
                }
                repaired.append(record)
            } else if record.archivedAt != nil {
                repaired.append(record)
            } else if NoteContent.isActionable(record.body) {
                record.archivedAt = record.modifiedAt
                repaired.append(record)
                changed = true
            } else {
                modelContext.delete(record)
                changed = true
            }
        }

        return (repaired, changed)
    }

    private func refreshSnapshots(notes: [NoteRecord], currentNoteID: UUID) {
        currentNote = notes.first(where: { $0.id == currentNoteID }).map(NoteSnapshot.init)
        library = notes
            .filter { $0.archivedAt != nil && $0.id != currentNoteID }
            .sorted {
                if $0.archivedAt == $1.archivedAt {
                    return $0.id.uuidString < $1.id.uuidString
                }
                return ($0.archivedAt ?? .distantPast) > ($1.archivedAt ?? .distantPast)
            }
            .map(NoteSnapshot.init)
    }
}
