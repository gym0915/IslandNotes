# Refactor Regression Baseline Implementation Plan

> **For Codex:** REQUIRED SUB-SKILL: Use `tdd` to implement this plan task-by-task.

**Goal:** Lock the valid public behavior of Island Notes before responsibilities move, and add a repeatable fixture that proves existing SwiftData content survives an upgrade load.

**Architecture:** Keep `IslandNotesFeature` as the top-level behavioral seam. Tests assemble a real in-memory or fixture-backed `ModelContainer`, the existing fake ActivityKit boundary, public feature actions, and deterministic time; assertions cover feature snapshots, persisted records, and fake system results without pinning private module structure or obsolete UI contracts.

**Tech Stack:** Swift 6, XCTest, SwiftData, ActivityKit contract fakes, `xcodebuild`.

---

### Task 1: Record the regression baseline

**Files:**
- Create: `docs/verification/refactor-regression-baseline.md`

1. Run the existing `IslandNotesFeatureTests` target unchanged.
2. Record the suites, test count, command, and fixed-point commit.
3. Classify existing coverage for Feature, payload, Library, reconciliation, deep links, and controller contracts.

### Task 2: Add the legacy SwiftData fixture

**Files:**
- Create: `IslandNotes/Tests/IslandNotesFeatureTests/Fixtures/LegacyStoreV1/`
- Create: `IslandNotes/Tests/IslandNotesFeatureTests/TestSupport/LegacyStoreFixture.swift`
- Create: `IslandNotes/Tests/IslandNotesFeatureTests/LegacyStoreRecoveryTests.swift`

1. Add a deterministic, checked-in store created by the pre-refactor schema.
2. Add a loader that copies the fixture into a unique temporary directory before opening it.
3. Through `bootstrap()`, assert that current ID/body/version/timestamps, the Workbench pointer, and library rows are preserved.
4. Reopen the copied store and assert the recovered state is repeatable.

### Task 3: Characterize missing invariants at public seams

**Files:**
- Modify: `IslandNotes/Sources/IslandNotes/Features/IslandNotesFeature.swift`
- Modify or create tests under `IslandNotes/Tests/IslandNotesFeatureTests/` only.

1. Expose `completeEditing()` as the stable public `Done` action without changing existing UI behavior.
2. Add a unique-current-note characterization using public Feature actions and persisted records.
3. Add archive, swap, and delete transaction characterizations that assert coherent observable and persisted end states, including forced save failures through a read-only `ModelConfiguration`.
4. Add end-barrier characterizations for archive, swap, and delete when ActivityKit still reports an active session.
5. Add request/update 4 KB boundary characterizations that verify persisted content and fake activity state.
6. Avoid assertions on localized copy, automatic saving, row-tap replacement, and old UI structure.

### Task 4: Verify and review

**Files:**
- All task files above.

1. Run each new test class while iterating.
2. Run an app build/typecheck.
3. Run the full `IslandNotes` test scheme once.
4. Review the task diff on Standards and Spec axes, fix findings, and rerun affected checks.
5. Commit only files belonging to this ticket on the current branch.
