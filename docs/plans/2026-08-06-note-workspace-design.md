# NoteWorkspace Extraction Design

**Status:** Approved by ticket 02

## Goal

Move SwiftData bootstrap/repair and committed-note transactions behind a focused
`NoteWorkspace` while preserving `IslandNotesFeature` as the public behavior seam and
loading the existing store schema in place.

## Chosen boundary

`NoteWorkspace` is a `@MainActor` deep module backed directly by one `ModelContext`.
It owns stable current-note and library snapshots plus bootstrap, committed-body,
move-to-library, replacement, and deletion transactions. Each mutation changes managed
records, performs one save, rolls back on failure, and only publishes new snapshots after
the save succeeds.

`IslandNotesFeature` composes the workspace with the existing Live Activity controller.
It keeps editing state, character-limit feedback, deletion confirmation, ActivityKit
lifecycle state, and cross-module ordering. In particular, move, replacement, and delete
still clear the Live Activity end barrier before calling the workspace.

## Alternatives rejected

- A `RepositoryProtocol` plus SwiftData adapter would add a second abstraction despite
  there being only one persistence implementation and would encourage mock-based tests.
- Static transaction helpers would move code without giving one module ownership of the
  current-note invariant or stable observable state.
- Rewriting the SwiftData schema would risk migration and is outside this ticket. The
  existing `NoteRecord` and `WorkbenchRecord` models remain unchanged.

## Compatibility and repair

A valid existing Workbench pointer is authoritative and is loaded without rewriting any
already-consistent record. Missing or invalid pointers are repaired in one save by creating
a blank current note and either updating the existing primary Workbench row or inserting it
when absent. Eligible orphan content is preserved as a Library entry using its existing
modification time for deterministic recovery; orphan blank slots are removed so they never
enter the Library. Redundant Workbench rows are removed while the primary pointer is retained.

## Tests

Direct in-memory `NoteWorkspaceTests` cover bootstrap/repair, committed fields, library
ordering, move, replacement, delete, and save rollback. Existing Feature-harness tests
remain unchanged and prove the original public behavior, ActivityKit barrier ordering,
and legacy-store recovery at the highest composition seam.
