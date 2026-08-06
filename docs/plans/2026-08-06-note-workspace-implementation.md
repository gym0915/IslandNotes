# NoteWorkspace Extraction Implementation Plan

> **For Codex:** REQUIRED SUB-SKILL: Use `superpowers:test-driven-development` to implement this plan task-by-task.

**Goal:** Extract committed-note persistence and invariants into `NoteWorkspace` without changing the public behavior of `IslandNotesFeature` or the existing SwiftData schema.

**Architecture:** A main-actor observable workspace directly owns one SwiftData context and publishes immutable note snapshots only after successful atomic saves. The feature delegates data work to it and retains editing, Live Activity, confirmation, and feedback coordination.

**Tech Stack:** Swift 6, Observation, SwiftData, XCTest, `xcodebuild`.

---

### Task 1: Specify bootstrap and repair at the workspace seam

**Files:**
- Create: `IslandNotes/Tests/IslandNotesFeatureTests/NoteWorkspaceTests.swift`
- Create: `IslandNotes/Sources/IslandNotes/Features/NoteWorkspace.swift`

1. Write direct in-memory tests for first launch, valid-state loading, invalid-pointer repair, and redundant-Workbench repair.
2. Run `NoteWorkspaceTests` and verify the missing type/API causes RED.
3. Add `NoteSnapshot` and the minimal workspace bootstrap/refresh implementation.
4. Run `NoteWorkspaceTests` and the app build until green.

### Task 2: Specify atomic committed-note transactions

**Files:**
- Modify: `IslandNotes/Tests/IslandNotesFeatureTests/NoteWorkspaceTests.swift`
- Modify: `IslandNotes/Sources/IslandNotes/Features/NoteWorkspace.swift`

1. Add failing direct tests for commit field changes, move, nonblank and blank replacement, delete, deterministic library order, and missing-ID no-op behavior.
2. Implement the smallest domain-named transaction methods, using one save and rollback per mutation.
3. Add a fixture-backed read-only failure test and verify snapshots and persisted fields remain unchanged.
4. Run only `NoteWorkspaceTests` after each red-green cycle.

### Task 3: Delegate Feature behavior to the workspace

**Files:**
- Modify: `IslandNotes/Sources/IslandNotes/Features/IslandNotesFeature.swift`
- Modify: `IslandNotes/Sources/IslandNotes/UI/AppRootView.swift`
- Modify: `IslandNotes/Sources/IslandNotes/UI/PreviewFixtures.swift`
- Modify: `IslandNotes/Tests/IslandNotesFeatureTests/TestSupport/FeatureHarness.swift`

1. Change the harness to compose a real workspace and verify existing Feature tests fail to compile before production delegation is complete.
2. Inject the workspace into the feature, forward current/library snapshots, and replace direct SwiftData operations with workspace calls.
3. Preserve the Live end barrier before move/replacement/delete and preserve existing feedback and editing resets.
4. Update app and preview composition without changing public view behavior.
5. Run the Feature, persistence, library, lifecycle, reconciliation, and legacy-recovery test classes.

### Task 4: Verify, review, and commit

**Files:**
- All task files above.

1. Run an app build/typecheck.
2. Run the complete `IslandNotesFeatureTests` target once.
3. Use the `code-review` skill on the ticket diff and fix all actionable findings.
4. Rerun affected focused tests and the final full suite if review changes production behavior.
5. Stage only ticket files and commit them on the current branch.
