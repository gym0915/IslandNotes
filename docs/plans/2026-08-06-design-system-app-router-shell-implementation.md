# Design System, AppRouter, and App Shell Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:test-driven-development to implement this plan task-by-task.

**Goal:** Establish Island Notes' centralized visual tokens, exclusive App-level sheet routing, More Menu, and reusable redesigned app shell.

**Architecture:** A real observable `AppRouter` owns one optional App-level destination and drives a single native SwiftUI sheet. The Workbench keeps menu expansion as local view state, while stateless shell/menu/sheet components consume centralized design tokens and typed Lucide vector assets.

**Tech Stack:** Swift 6, SwiftUI, Observation, SwiftData, XCTest/XCUITest, Xcode asset catalogs

---

### Task 1: AppRouter public behavior

**Files:**
- Create: `IslandNotes/Sources/IslandNotes/Navigation/AppRouter.swift`
- Create: `IslandNotes/Tests/IslandNotesFeatureTests/AppRouterTests.swift`

**Step 1: Write the failing router test**

Add one public-behavior test for presenting Note Library.

**Step 2: Run the focused test to verify RED**

Run `xcodebuild -project IslandNotes/IslandNotes.xcodeproj -scheme IslandNotes -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -only-testing:IslandNotesFeatureTests/AppRouterTests test` and expect a compile failure because `AppRouter` does not exist.

**Step 3: Write the minimal router**

Add `AppSheet`, observable optional sheet state, and the library presentation action.

**Step 4: Run the focused test to verify GREEN**

Run the same focused command and expect the test to pass.

**Step 5: Repeat vertical router slices**

Add one failing test and minimal implementation at a time for Settings replacement exclusivity, dismissal, valid Workbench deep links, and invalid URL no-op behavior. Run the focused router file after every slice.

### Task 2: Design tokens and Lucide icon assets

**Files:**
- Create: `IslandNotes/Sources/IslandNotes/UI/DesignSystem/IslandDesign.swift`
- Create: `IslandNotes/Sources/IslandNotes/UI/DesignSystem/AppIcon.swift`
- Create: `IslandNotes/Sources/IslandNotes/Resources/Assets.xcassets/Contents.json`
- Create: `IslandNotes/Sources/IslandNotes/Resources/Assets.xcassets/Lucide*.imageset/Contents.json`
- Create: `IslandNotes/Sources/IslandNotes/Resources/Assets.xcassets/Lucide*.imageset/*.svg`
- Create: `IslandNotes/Sources/IslandNotes/Resources/Lucide-LICENSE.txt`

**Step 1: Add centralized token types**

Define semantic colors, typography, spacing, radii, elevation, material, sizing, and motion without business-state ownership.

**Step 2: Add the typed icon interface and vector assets**

Map the exact menu, library, settings, and close cases to Lucide SVG imagesets using template rendering.

**Step 3: Typecheck the app**

Run an iPhone 16 Pro simulator build and expect success.

### Task 3: Shared menu and sheet shell

**Files:**
- Create: `IslandNotes/Sources/IslandNotes/UI/AppShell/MoreMenu.swift`
- Create: `IslandNotes/Sources/IslandNotes/UI/AppShell/AppSheetContainer.swift`
- Create: `IslandNotes/Sources/IslandNotes/UI/SettingsView.swift`
- Modify: `IslandNotes/Sources/IslandNotes/UI/NoteLibraryView.swift`

**Step 1: Implement stateless More Menu**

Render exactly Note Library and Settings actions using design tokens and typed icons.

**Step 2: Implement the reusable sheet container**

Provide drag indicator support, centered title, circular close action, adaptive content scrolling, and semantic surface styling.

**Step 3: Fit Library and Settings transitional content into the shell**

Keep existing Library data behavior and add English Settings placeholder content without page ViewModels.

**Step 4: Typecheck the app**

Run the simulator build and expect success.

### Task 4: Workbench and root navigation integration

**Files:**
- Modify: `IslandNotes/Sources/IslandNotes/UI/AppRootView.swift`
- Modify: `IslandNotes/Sources/IslandNotes/UI/WorkbenchView.swift`
- Modify: `IslandNotes/Sources/IslandNotes/UI/ActionDock.swift`
- Modify: `IslandNotes/Sources/IslandNotes/UI/CharacterProgressView.swift`
- Modify: `IslandNotes/Sources/IslandNotes/UI/MarkedTextEditor.swift`
- Modify: `IslandNotes/Sources/IslandNotes/Features/IslandNotesFeature.swift`
- Modify: `IslandNotes/Configuration/IslandNotes-Info.plist`

**Step 1: Connect the real router to one `.sheet(item:)`**

Route Library and Settings through the shared container and clear routing state on native dismissal.

**Step 2: Replace direct Library navigation with local More Menu state**

Add outside-tap dismissal and route menu actions through closures without putting menu state in `AppRouter`.

**Step 3: Convert touched user-visible strings to English**

Set `CFBundleDisplayName` to `Island Notes` and update current shell/action/accessibility/feedback copy.

**Step 4: Typecheck and run existing focused behavior tests**

Build, then run router and deep-link test files; expect success.

### Task 5: Previews and UI automation

**Files:**
- Modify: `IslandNotes/Sources/IslandNotes/UI/PreviewFixtures.swift`
- Modify: `IslandNotes/Tests/IslandNotesUITests/IslandNotesUITests.swift`
- Modify: `IslandNotes/Tests/IslandNotesUITests/DeepLinkUITests.swift`

**Step 1: Add representative previews**

Cover Light/Dark shells, More Menu, Note Library sheet, and Settings sheet with deterministic fixtures.

**Step 2: Write user-visible UI tests**

Verify product naming, exact menu items, outside-tap dismissal, opening/closing both sheet containers, English accessibility labels, and 44-point controls.

**Step 3: Run focused UI tests**

Run the updated UI test classes on iPhone 16 Pro and expect success.

### Task 6: Full verification and review

**Files:**
- Modify only files required to address verified findings.

**Step 1: Run the full suite once**

Run `xcodebuild -project IslandNotes/IslandNotes.xcodeproj -scheme IslandNotes -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test` and expect all tests to pass.

**Step 2: Review against standards and this ticket**

Use the `code-review` skill with the pre-implementation commit as the fixed point, keeping Standards and Spec findings separate.

**Step 3: Fix material findings and re-run affected/full checks**

Apply only in-scope fixes and produce fresh passing evidence.

**Step 4: Commit the implementation**

Stage only this ticket's files and commit them on the current branch.
