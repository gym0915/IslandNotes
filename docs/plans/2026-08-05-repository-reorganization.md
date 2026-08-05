# Repository Reorganization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Reorganize the repository into a named `IslandNotes/` iOS project directory and a categorized `docs/` knowledge base without losing source, tests, prototypes, or evidence.

**Architecture:** Preserve all existing Xcode targets and module responsibilities while changing only their filesystem locations. Keep documentation as a separate sibling tree, add navigation indexes, and rewrite local references so the repository remains portable.

**Tech Stack:** Git, Markdown, Xcode project files, Swift 6, SwiftUI, XCTest

---

### Task 1: Establish the project container

**Files:**
- Move: `IslandNotes.xcodeproj/` → `IslandNotes/IslandNotes.xcodeproj/`
- Move: `Configuration/` → `IslandNotes/Configuration/`
- Move: production source roots → `IslandNotes/Sources/`
- Move: test roots → `IslandNotes/Tests/`
- Create: `IslandNotes/README.md`
- Create: `IslandNotes/.gitignore`

**Steps:**

1. Create `Sources/` and `Tests/` below the existing `IslandNotes/` directory.
2. Move every existing source and test file without copying or deleting content.
3. Move the Xcode project and configuration into the project container.
4. Add project-specific build guidance and ignore rules.
5. Inspect the resulting file list and compare source/test file counts with the baseline.

### Task 2: Categorize documentation and prototypes

**Files:**
- Move: top-level product documents → `docs/product/`
- Move: decision tickets and records → `docs/decisions/`
- Move: ActivityKit research → `docs/research/`
- Move: `prototypes/` and `原始资料/Web-Prototype/` → `docs/prototypes/`
- Move: `审计/` → `docs/audits/`
- Move: obsolete plans → `docs/plans/archive/`
- Create: `docs/README.md`

**Steps:**

1. Create the approved documentation categories.
2. Move and rename documents using the approved stable names.
3. Separate current plans from archived plans.
4. Preserve prototype assets and audit screenshots as evidence.
5. Add a documentation index that identifies the current sources of truth.

### Task 3: Repair project and document references

**Files:**
- Modify: `IslandNotes/IslandNotes.xcodeproj/project.pbxproj`
- Modify: Markdown files containing local links or commands

**Steps:**

1. Change the five synchronized Xcode group paths to their new `Sources/` and `Tests/` locations.
2. Rewrite Markdown links to their new relative targets.
3. Rewrite prototype commands to start from their new directory.
4. Remove stale absolute paths into `/Users/steve/project/app 灵动岛提醒`.
5. Run a local Markdown link checker and correct every missing local target.

### Task 4: Verify the reorganized repository

**Files:**
- Verify: all files below `IslandNotes/` and `docs/`

**Steps:**

1. Run `git status --short` and confirm every change is in the approved scope.
2. Run `xcodebuild -list -project IslandNotes/IslandNotes.xcodeproj` and expect all four schemes/targets to resolve.
3. Build the `IslandNotes` scheme for an available iOS Simulator and expect `BUILD SUCCEEDED`.
4. Run the feature and UI test suites and expect zero failures.
5. Confirm the repository root contains only `.git/`, `IslandNotes/`, and `docs/`.

### Task 5: Publish to GitHub

**Files:**
- Stage: the complete approved reorganization

**Steps:**

1. Review the staged diff and ensure no source, test, prototype, or evidence file was lost.
2. Commit with a concise repository-organization message.
3. Push `codex/reorganize-repository` to `origin`.
4. Open a draft pull request targeting `main` with the validation evidence.

