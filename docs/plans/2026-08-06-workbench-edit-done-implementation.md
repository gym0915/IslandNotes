# Workbench Display, Edit, and Done Commit Implementation Plan

> **For Codex:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Apply `tdd` at the agreed Feature harness, TextLimiter/renderer, and Workbench UI seams. Apply `verification-before-completion` before committing.

**Goal:** Deliver the Workbench display → source edit → explicit `Done` commit → rendered display loop while preserving draft, persistence, Live Activity, character-limit, and preview invariants.

**Architecture:** Keep editing-session state in `IslandNotesFeature`, committed data transactions in `NoteWorkspace`, and source rendering/character limiting in pure value modules. `WorkbenchView` switches between a stateless rendered note surface and `MarkedTextEditor`, sending public intents to the Feature; the existing fake Live controller and in-memory SwiftData harness prove cross-module behavior.

**Tech Stack:** Swift 6, SwiftUI, Observation, SwiftData, UIKit text input bridge, ActivityKit adapter seam, XCTest/XCUITest, Xcode 26.

---

### Task 1: Lock the editing state-machine behavior at the Feature seam

**Files:**
- Modify: `IslandNotes/Tests/IslandNotesFeatureTests/IslandNotesFeatureTests.swift`
- Modify: `IslandNotes/Tests/IslandNotesFeatureTests/TestSupport/FeatureHarness.swift`
- Modify: `IslandNotes/Sources/IslandNotes/Features/IslandNotesFeature.swift`

**Step 1: Write the failing tests**

Add vertical behavior tests proving bootstrap starts in display, begin edit copies committed source, staging changes only the in-memory draft, successful `Done` increments the committed version and exits editing, and a new harness bootstrapped from the same persisted store restores only the committed value.

**Step 2: Run the focused tests and verify red**

Run:

```bash
xcodebuild -project IslandNotes/IslandNotes.xcodeproj -scheme IslandNotes -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:IslandNotesFeatureTests/IslandNotesFeatureTests test
```

Expected: FAIL because the public display/edit state and begin-edit intent do not exist and staging currently persists through the view flow.

**Step 3: Implement the minimal state machine**

Add an explicit editing state projection, `beginEditing`, draft-only staging, and a `Done` commit that clears editing state only after `NoteWorkspace.commitCurrentNote` succeeds. Keep compatibility helpers only where existing tests require them, and make actions use committed content rather than the draft.

**Step 4: Run the focused tests and verify green**

Run the command from Step 2. Expected: PASS.

### Task 2: Preserve draft on save failure and update only the existing Live Activity after Done

**Files:**
- Modify: `IslandNotes/Tests/IslandNotesFeatureTests/IslandNotesFeatureTests.swift`
- Modify: `IslandNotes/Tests/IslandNotesFeatureTests/LiveActivityLifecycleTests.swift`
- Modify: `IslandNotes/Tests/IslandNotesFeatureTests/TestSupport/FeatureHarness.swift`
- Modify: `IslandNotes/Sources/IslandNotes/Features/IslandNotesFeature.swift`

**Step 1: Write the failing tests**

Use the read-only store seam to prove failed `Done` keeps edit state and exact draft. Use `FakeLiveActivityController` to prove staging emits no request/update, then successful `Done` queues and flushes one update against the same Activity ID and new content version.

**Step 2: Run only the new tests and verify red**

Run the two affected test classes with `-only-testing`. Expected: FAIL on draft retention/edit state or premature Live update.

**Step 3: Implement the minimal sequencing**

Keep the editing session active across the throwing workspace call; only after success transition to display and enqueue a Live update. Do not rebuild the Feature for sheet or scene transitions.

**Step 4: Run the focused tests and verify green**

Run the two affected test classes. Expected: PASS.

### Task 3: Lock source rendering and Character-limit semantics

**Files:**
- Create: `IslandNotes/Sources/IslandNotes/Domain/RenderedNoteContent.swift`
- Create: `IslandNotes/Tests/IslandNotesFeatureTests/RenderedNoteContentTests.swift`
- Modify: `IslandNotes/Tests/IslandNotesFeatureTests/CharacterLimitTests.swift`
- Modify: `IslandNotes/Sources/IslandNotes/Features/TextLimiter.swift`
- Modify: `IslandNotes/Sources/IslandNotes/Features/IslandNotesFeature.swift`
- Modify if required: `IslandNotes/IslandNotes.xcodeproj/project.pbxproj`

**Step 1: Write one failing renderer test**

Assert a worked literal containing plain lines, `- ` lines, blank lines, headings, asterisk syntax, no-space hyphens, and indented hyphens produces the expected ordered plain/bullet projection.

**Step 2: Run the renderer test and verify red**

Expected: FAIL because the renderer type is absent.

**Step 3: Implement the renderer and verify green**

Split source while preserving empty lines; classify only exact leading `- `; remove only that prefix from bullet display text. Run the renderer test. Expected: PASS.

**Step 4: Extend Character-limit tests one behavior at a time**

Cover mixed CJK/newline/punctuation, composed Emoji, over-limit paste, active marked text followed by committed composition, deletion/replacement at capacity, and Feature progress selecting committed versus draft text.

**Step 5: Run CharacterLimitTests after every slice**

Expected final result: PASS with Swift `String.count` semantics and no split graphemes.

### Task 4: Make character detail a resettable two-second interaction

**Files:**
- Modify: `IslandNotes/Tests/IslandNotesFeatureTests/CharacterLimitTests.swift`
- Modify: `IslandNotes/Sources/IslandNotes/Features/IslandNotesFeature.swift`
- Modify: `IslandNotes/Sources/IslandNotes/UI/CharacterProgressView.swift`

**Step 1: Write a failing clock-controlled Feature test**

Inject a cancellable sleep seam or deterministic duration hook. Assert reveal shows detail, it hides after two seconds, and a repeat reveal before expiry resets the countdown.

**Step 2: Verify red, implement minimal timer ownership, verify green**

The Feature owns the transient presentation task so view recreation does not orphan it. Cancellation and replacement must be explicit. Run `CharacterLimitTests`; expected: PASS.

### Task 5: Build the Workbench display/edit/Done UI and UI seams

**Files:**
- Modify: `IslandNotes/Sources/IslandNotes/UI/WorkbenchView.swift`
- Modify: `IslandNotes/Sources/IslandNotes/UI/MarkedTextEditor.swift`
- Modify: `IslandNotes/Sources/IslandNotes/UI/CharacterProgressView.swift`
- Modify: `IslandNotes/Tests/IslandNotesUITests/IslandNotesUITests.swift`

**Step 1: Write the failing primary-flow UI test**

Assert committed content initially appears in the rendered note surface and the editor is absent; tap the note, assert exact source text and `Done`; edit, tap `Done`, and assert the rendered bullet/plain output and editor disappearance. Add stable identifiers for rendered note, source editor, Done, bullet rows, and character detail.

**Step 2: Run the UI test and verify red**

Run only the new UI test on iPhone 16 Pro. Expected: FAIL because the current Workbench is a permanent autosaving editor.

**Step 3: Implement the minimal UI state switch**

Extract small rendered/source subviews inside the Workbench UI module, preserve the existing design tokens, make the display paper tappable, provide a native `Done` action, and keep feedback/accessibility semantics visible.

**Step 4: Run the focused UI test and build**

Run the new UI test, then:

```bash
xcodebuild -project IslandNotes/IslandNotes.xcodeproj -scheme IslandNotes -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```

Expected: both exit 0.

### Task 6: Complete deterministic Workbench previews and error UI coverage

**Files:**
- Modify: `IslandNotes/Sources/IslandNotes/UI/PreviewFixtures.swift`
- Modify: `IslandNotes/Tests/IslandNotesUITests/IslandNotesUITests.swift`

**Step 1: Add preview fixture inputs**

Support display/edit state and exact draft independently of committed body. Add named previews for empty Light/Dark, rendered bullets, editing source, 240-character editing, and save error retaining its draft.

**Step 2: Add focused UI assertions for empty, capacity, and save-error launch seams where existing launch configuration supports them**

Assert user-visible output and identifiers, not private view hierarchy.

**Step 3: Run the focused UI test file and compile previews with the app target**

Expected: PASS/build exit 0.

### Task 7: Full verification and review

**Files:**
- Review all changed production, test, and plan files.

**Step 1: Run formatting/static checks available in the repository**

Run `git diff --check` and Xcode build. Expected: no errors.

**Step 2: Run the full test suite once**

Run:

```bash
xcodebuild -project IslandNotes/IslandNotes.xcodeproj -scheme IslandNotes -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

Expected: all unit, feature, and UI tests pass. If the named simulator differs locally, resolve the installed current iPhone 16 Pro destination and record the exact destination used.

**Step 3: Review against standards and spec**

Use `code-review` with the implementation base commit, repository standards/context sources, the design document, and the user acceptance criteria. Fix all confirmed issues and rerun affected tests plus the full build/test gate.

**Step 4: Commit only this ticket's files**

Preserve unrelated dirty-tree changes. Stage the explicit path list, inspect the staged diff, and commit with a focused message.
