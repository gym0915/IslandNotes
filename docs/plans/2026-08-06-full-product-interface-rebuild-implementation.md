# Full Product Interface Rebuild Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rebuild every Island Notes App and Live Activity surface to match the approved high-fidelity prototype while preserving all persistence and Live lifecycle guarantees.

**Architecture:** Keep `IslandNotesFeature`, `NoteWorkspace`, `LiveActivitySession`, and `AppRouter` as the behavior seams. Add a narrow persistent `AppearanceSettings` module, expand the centralized design system, and rebuild each SwiftUI surface from reusable stateless components. Implement one vertical slice at a time with tests, previews, simulator inspection, and a commit after every green slice.

**Tech Stack:** Swift 6, SwiftUI, Observation, SwiftData, ActivityKit, WidgetKit, XCTest/XCUITest, Lucide SVG assets, Xcode 26 simulator tooling.

---

## Working rules

- Use `@superpowers:test-driven-development` for every behavior or bug-fix slice.
- Use `@build-ios-apps:swiftui-ui-patterns` for state ownership, sheet composition, settings controls, reusable components, and previews.
- Use `@build-ios-apps:ios-debugger-agent` to build, launch, inspect, and exercise the App on Simulator.
- Use `@build-ios-apps:ios-simulator-browser` for browser-visible simulator proof when the helper is available.
- Use `@superpowers:verification-before-completion` before any completion claim.
- Run `@code-review` across the complete fixed-point diff before the final commit.
- Preserve the English-only interface contract and the exclusions in `docs/adr/0014-explicit-scope-exclusions-for-the-redesign.md`.
- Do not replace existing persistence, editing, library, or Live lifecycle modules while rebuilding presentation.
- The reference simulator for this workspace is `EDD74643-CA6F-4ABB-B151-06F1B03A5769` (`iPhone 16 Pro`, iOS 26.2).

## Task 1: Establish the appearance preference module

**Files:**

- Create: `IslandNotes/Sources/IslandNotes/Features/AppearanceSettings.swift`
- Create: `IslandNotes/Tests/IslandNotesFeatureTests/AppearanceSettingsTests.swift`
- Modify: `IslandNotes/Sources/IslandNotes/IslandNotesApp.swift`
- Modify: `IslandNotes/Sources/IslandNotes/UI/AppRootView.swift`

**Step 1: Write failing persistence and fallback tests**

Test the default, every stored mode, invalid stored data, mutation persistence, and conversion to an optional SwiftUI `ColorScheme`.

```swift
@MainActor
func testDefaultsToAutomaticAndPersistsASelection() {
    let defaults = UserDefaults(suiteName: #function)!
    defaults.removePersistentDomain(forName: #function)
    let settings = AppearanceSettings(defaults: defaults)

    XCTAssertEqual(settings.mode, .automatic)
    settings.select(.dark)
    XCTAssertEqual(AppearanceSettings(defaults: defaults).mode, .dark)
}

func testColorSchemeMapping() {
    XCTAssertNil(AppearanceMode.automatic.colorScheme)
    XCTAssertEqual(AppearanceMode.light.colorScheme, .light)
    XCTAssertEqual(AppearanceMode.dark.colorScheme, .dark)
}
```

**Step 2: Run the test and confirm it fails**

```bash
xcodebuild -quiet -project IslandNotes/IslandNotes.xcodeproj -scheme IslandNotes \
  -destination 'platform=iOS Simulator,id=EDD74643-CA6F-4ABB-B151-06F1B03A5769' \
  -only-testing:IslandNotesFeatureTests/AppearanceSettingsTests test
```

Expected: compile failure because `AppearanceSettings` and `AppearanceMode` do not exist.

**Step 3: Implement the narrow module**

Use an observable reference owned at the App root. Inject `UserDefaults` for deterministic tests.

```swift
enum AppearanceMode: String, CaseIterable, Identifiable, Sendable {
    case automatic, light, dark
    var id: Self { self }
    var title: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

@MainActor @Observable
final class AppearanceSettings {
    private static let key = "appearance-mode"
    private let defaults: UserDefaults
    private(set) var mode: AppearanceMode

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        mode = defaults.string(forKey: Self.key)
            .flatMap(AppearanceMode.init(rawValue:)) ?? .automatic
    }

    func select(_ mode: AppearanceMode) {
        self.mode = mode
        defaults.set(mode.rawValue, forKey: Self.key)
    }
}
```

Own one instance in `IslandNotesApp`, pass it into `AppRootView`, and apply `.preferredColorScheme(appearance.mode.colorScheme)` at the root of the App-owned view hierarchy. Do not apply this preference inside the Widget target.

**Step 4: Run focused tests and build**

Run the Task 1 test command, then:

```bash
xcodebuild -quiet -project IslandNotes/IslandNotes.xcodeproj -scheme IslandNotes \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```

Expected: all focused tests and the build pass.

**Step 5: Commit**

```bash
git add IslandNotes/Sources/IslandNotes/Features/AppearanceSettings.swift \
  IslandNotes/Sources/IslandNotes/IslandNotesApp.swift \
  IslandNotes/Sources/IslandNotes/UI/AppRootView.swift \
  IslandNotes/Tests/IslandNotesFeatureTests/AppearanceSettingsTests.swift
git commit -m "feat: persist app appearance mode"
```

## Task 2: Expand the normative design system and icon library

**Files:**

- Modify: `IslandNotes/Sources/IslandNotes/UI/DesignSystem/IslandDesign.swift`
- Modify: `IslandNotes/Sources/IslandNotes/UI/DesignSystem/AppIcon.swift`
- Create: `IslandNotes/Sources/IslandNotes/UI/DesignSystem/IslandButtonStyle.swift`
- Create: `IslandNotes/Sources/IslandNotes/UI/DesignSystem/IslandSurface.swift`
- Create: `IslandNotes/Sources/IslandNotes/UI/DesignSystem/IslandIconButton.swift`
- Add required SVG sets under: `IslandNotes/Sources/IslandNotes/Resources/Assets.xcassets/`
- Create: `IslandNotes/Tests/IslandNotesFeatureTests/DesignSystemTests.swift`

**Step 1: Write failing semantic-state tests**

Do not assert raw SwiftUI colors or private layout internals. Test stable mappings such as icon asset names, action roles, and mode-specific semantic state.

```swift
func testEveryProductIconHasAnAssetName() {
    XCTAssertEqual(AppIcon.replace.assetName, "lucide-replace")
    XCTAssertEqual(AppIcon.appearance.assetName, "lucide-monitor")
    XCTAssertEqual(AppIcon.feedback.assetName, "lucide-message-circle")
}

func testLiveAndDestructiveActionsExposeDistinctSemanticRoles() {
    XCTAssertEqual(IslandActionKind.live.accessibilityValue, "Live")
    XCTAssertEqual(IslandActionKind.destructive.accessibilityValue, "Destructive")
}
```

**Step 2: Run focused tests and confirm failure**

Use the standard simulator destination and `-only-testing:IslandNotesFeatureTests/DesignSystemTests`.

**Step 3: Implement tokens and reusable primitives**

Preserve the 4/8/16/24/32 spacing scale, 14/22/34/pill radii, 44-point targets, 160–210ms motion, prototype Light/Dark semantic colors, and Lucide template rendering. Add only icons present in the approved product surfaces: replace, appearance, light, dark, automatic, feedback, website, about, check, note mark, and confirmation controls.

Create reusable styles with narrow inputs:

```swift
enum IslandActionKind { case primary, neutral, live, destructive }

struct IslandButtonStyle: ButtonStyle {
    let kind: IslandActionKind
    func makeBody(configuration: Configuration) -> some View { /* token-only styling */ }
}

struct IslandIconButton: View {
    let icon: AppIcon
    let label: String
    let action: () -> Void
    var body: some View { /* 44pt circular control */ }
}
```

**Step 4: Add isolated Light/Dark previews and build**

Add previews for every action state and surface elevation. Run DesignSystemTests and the generic simulator build.

**Step 5: Commit**

Commit only design-system Swift files, Lucide assets, their license updates if required, and DesignSystemTests.

```bash
git commit -m "feat: establish prototype design components"
```

## Task 3: Rebuild the Workbench surface and action dock

**Files:**

- Modify: `IslandNotes/Sources/IslandNotes/UI/WorkbenchView.swift`
- Modify: `IslandNotes/Sources/IslandNotes/UI/ActionDock.swift`
- Modify: `IslandNotes/Sources/IslandNotes/UI/CharacterProgressView.swift`
- Modify: `IslandNotes/Sources/IslandNotes/UI/MarkedTextEditor.swift`
- Create: `IslandNotes/Sources/IslandNotes/UI/Components/RenderedNoteView.swift`
- Create: `IslandNotes/Sources/IslandNotes/UI/Components/HintMessageView.swift`
- Modify: `IslandNotes/Tests/IslandNotesUITests/IslandNotesUITests.swift`

**Step 1: Add UI assertions for the approved hierarchy**

Extend existing tests to assert observable semantics, not private subview identifiers:

- Product title and Live/Not Live status are present.
- Display surface is initially present and the editor is absent.
- Tapping the surface opens the source editor and Done.
- Blank note disables all three actions.
- Nonblank committed note enables Move, Go Live, and Delete.
- Save failure retains the editor and displays the hint component.
- The progress control has a 44-point target and exposes used/remaining values.

**Step 2: Run the focused UI tests and confirm the new assertions fail**

```bash
xcodebuild -quiet -project IslandNotes/IslandNotes.xcodeproj -scheme IslandNotes \
  -destination 'platform=iOS Simulator,id=EDD74643-CA6F-4ABB-B151-06F1B03A5769' \
  -only-testing:IslandNotesUITests/IslandNotesUITests test
```

**Step 3: Recompose Workbench from focused subviews**

Keep `@Bindable feature` at Workbench. Keep More Menu expansion local. Extract the rendered source presentation so Workbench and previews share it. Style display/editor, capacity ring, Done, feedback, and the three-action dock exclusively through `IslandDesign` and reusable components. Preserve every existing accessibility identifier required by user-flow tests.

**Step 4: Verify display/edit/Done, 240 limit, and failure flows**

Run IslandNotesUITests plus CharacterLimitTests and IslandNotesFeatureTests. Build immediately after this slice.

**Step 5: Commit**

```bash
git commit -m "feat: rebuild the Workbench interface"
```

## Task 4: Rebuild More Menu and shared sheet chrome

**Files:**

- Modify: `IslandNotes/Sources/IslandNotes/UI/AppShell/MoreMenu.swift`
- Modify: `IslandNotes/Sources/IslandNotes/UI/AppShell/AppSheetContainer.swift`
- Modify: `IslandNotes/Sources/IslandNotes/UI/AppRootView.swift`
- Modify: `IslandNotes/Tests/IslandNotesUITests/IslandNotesUITests.swift`
- Modify: `IslandNotes/Tests/IslandNotesFeatureTests/AppRouterTests.swift`

**Step 1: Extend tests for the menu and one-sheet invariant**

Assert two and only two top-level destinations, outside-tap dismissal, prototype labels, circular close control, and preservation of the living edit draft across each sheet.

**Step 2: Confirm the new tests fail where the current shell differs from the prototype**

Run AppRouterTests and the menu/sheet UI tests only.

**Step 3: Implement the prototype shell**

Keep `.sheet(item:)` and the `AppSheet` enum. Apply the prototype scrim, rounded sheet surface, drag indicator, centered title, and circular close component. Do not add navigation pushes or duplicate sheet booleans.

**Step 4: Run focused tests and a generic build**

Expected: AppRouter tests, menu/sheet UI tests, and build pass.

**Step 5: Commit**

```bash
git commit -m "feat: rebuild app menu and sheets"
```

## Task 5: Implement prototype Note Library cards and timestamps

**Files:**

- Create: `IslandNotes/Sources/IslandNotes/Domain/LibraryTimestampFormatter.swift`
- Modify: `IslandNotes/Sources/IslandNotes/UI/NoteLibraryView.swift`
- Create: `IslandNotes/Sources/IslandNotes/UI/Components/LibraryNoteCard.swift`
- Create: `IslandNotes/Tests/IslandNotesFeatureTests/LibraryTimestampFormatterTests.swift`
- Modify: `IslandNotes/Tests/IslandNotesUITests/IslandNotesUITests.swift`

**Step 1: Write failing deterministic timestamp tests**

Cover Today, Yesterday, weekday, same-year dated, prior-year dated, fixed English locale, and 12-hour output. Inject calendar, locale, timezone, and `now`.

```swift
let formatter = LibraryTimestampFormatter(
    calendar: calendar,
    locale: Locale(identifier: "en_US_POSIX"),
    timeZone: TimeZone(secondsFromGMT: 0)!,
    now: { reference }
)
XCTAssertEqual(formatter.string(from: today), "Today, 9:41 AM")
```

**Step 2: Write failing UI tests for explicit replacement**

Assert row content itself does nothing, each card exposes `Replace current note`, replacement dismisses the sheet after success, an outgoing nonblank note returns to the top of the library, and a living draft is discarded by replacement.

**Step 3: Implement formatter and card**

Use a custom `ScrollView`/`LazyVStack` if needed to match the prototype card geometry. The card body is noninteractive. The trailing replacement control is the only button and has the exact accessibility label `Replace current note`.

**Step 4: Run formatter, library mutation, persistence, and UI tests**

Include LibraryMutationTests and PersistenceInvariantTests to prove the visual rewrite did not weaken the transaction.

**Step 5: Commit**

```bash
git commit -m "feat: rebuild the Note Library"
```

## Task 6: Build functional appearance Settings

**Files:**

- Modify: `IslandNotes/Sources/IslandNotes/UI/SettingsView.swift`
- Modify: `IslandNotes/Sources/IslandNotes/UI/AppRootView.swift`
- Create: `IslandNotes/Sources/IslandNotes/UI/Components/SettingsRow.swift`
- Modify: `IslandNotes/Sources/IslandNotes/UI/PreviewFixtures.swift`
- Modify: `IslandNotes/Tests/IslandNotesUITests/IslandNotesUITests.swift`

**Step 1: Add failing Settings UI tests**

Test Automatic, Light, and Dark selection; selected-state semantics; App-wide override while a sheet is open; persistence after termination and relaunch; and the presence but no action of Feedback, Website, and About. Privacy must remain absent.

Use a dedicated UI-test defaults suite or launch arguments so tests do not leak preference state between cases.

**Step 2: Confirm failure against the current transitional Settings view**

Run only the new Settings UI test methods.

**Step 3: Implement the approved Settings composition**

Pass `AppearanceSettings` explicitly from AppRoot to Settings. Use native buttons/picker semantics inside prototype-styled grouped surfaces. A selection writes immediately through `AppearanceSettings`. Support rows have pressed feedback and accessibility labels but no destination, message, or side effect.

**Step 4: Verify appearance persistence and core UI flows**

Run AppearanceSettingsTests and all IslandNotesUITests. Build the scheme.

**Step 5: Commit**

```bash
git commit -m "feat: add prototype appearance settings"
```

## Task 7: Replace the system delete alert with the App-owned confirmation

**Files:**

- Create: `IslandNotes/Sources/IslandNotes/UI/Components/DeleteConfirmationView.swift`
- Modify: `IslandNotes/Sources/IslandNotes/UI/WorkbenchView.swift`
- Modify: `IslandNotes/Sources/IslandNotes/UI/PreviewFixtures.swift`
- Modify: `IslandNotes/Tests/IslandNotesUITests/IslandNotesUITests.swift`
- Modify: `IslandNotes/Tests/IslandNotesFeatureTests/LibraryMutationTests.swift`

**Step 1: Change UI tests from system-alert queries to observable overlay semantics**

Assert the title, irreversible explanation, Cancel, destructive Delete Note, scrim dismissal policy, focus order, and successful return to a blank Workbench. Add a save/end failure assertion that keeps valid content and surfaces a hint.

**Step 2: Confirm the new UI tests fail**

The current system alert should not satisfy the custom confirmation identifier and hierarchy.

**Step 3: Implement the bottom confirmation card**

Render from `feature.deleteConfirmation != nil` in a Workbench overlay. Use semantic destructive styling, a blocking scrim, and Reduce Motion-aware transition. Keep all confirmation state and async deletion behavior in `IslandNotesFeature`.

**Step 4: Run delete lifecycle and UI tests**

Run LibraryMutationTests, PersistenceInvariantTests, LiveActivityLifecycleTests, and the custom delete UI tests.

**Step 5: Commit**

```bash
git commit -m "feat: add prototype delete confirmation"
```

## Task 8: Rebuild Dynamic Island and Lock Screen presentation

**Files:**

- Modify: `IslandNotes/Sources/IslandNotesWidget/IslandNotesWidgetBundle.swift`
- Modify: `IslandNotes/Sources/IslandNotesShared/RenderedNoteContent.swift`
- Create: `IslandNotes/Sources/IslandNotesWidget/LiveActivityDesign.swift`
- Create: `IslandNotes/Sources/IslandNotesWidget/LiveActivityNoteView.swift`
- Modify: `IslandNotes/Tests/IslandNotesFeatureTests/RenderedNoteContentTests.swift`
- Modify: `IslandNotes/Tests/IslandNotesFeatureTests/LiveActivityPresentationModelTests.swift`

**Step 1: Add failing shared-presentation tests**

Lock exact English presentation labels, brand-mark semantics, exact `- ` bullet conversion, literal handling of other Markdown-like source, and the absence of draft/app-appearance inputs from ActivityKit content state.

**Step 2: Confirm focused tests fail for obsolete Chinese and pin presentation assumptions**

Run RenderedNoteContentTests and LiveActivityPresentationModelTests.

**Step 3: Implement the approved system surfaces**

- Compact leading and Minimal: approved brand note mark only.
- Compact trailing: leave the system surface empty if the prototype does not assign content.
- Expanded: brand/status header plus committed rendered note, with local line limit.
- Lock Screen: prototype card hierarchy and its own line limit.
- All copy and accessibility strings: English.
- No App appearance override in the Widget.

**Step 4: Build and render Widget previews**

Build the full scheme. Render Compact, Minimal, Expanded, and Lock Screen previews with plain text, bullets, multiline text, Emoji, and truncation content.

**Step 5: Commit**

```bash
git commit -m "feat: rebuild Live Activity presentation"
```

## Task 9: Complete the prototype preview matrix

**Files:**

- Modify: `IslandNotes/Sources/IslandNotes/UI/PreviewFixtures.swift`
- Create: `docs/verification/2026-08-06-interface-rebuild/README.md`
- Add simulator comparison captures under: `docs/verification/2026-08-06-interface-rebuild/`

**Step 1: Inventory every prototype state before changing previews**

Create a matrix for Workbench empty/display/edit/limit/Live/error, menu, library empty/populated, Settings automatic/light/dark, delete confirmation, Dynamic Type, and Reduce Motion in both Light and Dark where the prototype defines both.

**Step 2: Add deterministic previews**

All previews use in-memory SwiftData, fake Live controllers, injected appearance settings, fixed timestamps, and stable content. No preview may touch a real store or ActivityKit service.

**Step 3: Build and launch with the iOS debugger workflow**

Use the booted iPhone 16 Pro, build and run `IslandNotes`, inspect the UI tree, and exercise the primary flow. If XcodeBuildMCP tools are not callable, use the equivalent `xcodebuild`, `simctl install`, `simctl launch`, and screenshot workflow and record the fallback.

**Step 4: Mirror and capture visual proof**

Start the scoped simulator mirror for `EDD74643-CA6F-4ABB-B151-06F1B03A5769`, verify a real frame, and capture Light/Dark frames. Compare geometry, type hierarchy, spacing, radii, button states, sheets, and overlays against `docs/prototypes/island-notes-ios-prototype.png`. Fix discrepancies before continuing.

**Step 5: Commit**

```bash
git commit -m "test: complete interface preview matrix"
```

## Task 10: Run accessibility, compatibility, and regression verification

**Files:**

- Modify as failures require: files touched in Tasks 1–9 only
- Modify: `docs/verification/real-device-live-activity-checklist.md`
- Modify: `docs/verification/2026-08-06-interface-rebuild/README.md`

**Step 1: Run focused accessibility UI tests**

Cover default and maximum Dynamic Type, 44-point controls, English labels/values/hints, library replacement focus order, confirmation focus order, keyboard reachability, and Reduce Motion.

**Step 2: Run the complete automated suite once**

```bash
xcodebuild -quiet -project IslandNotes/IslandNotes.xcodeproj -scheme IslandNotes \
  -destination 'platform=iOS Simulator,id=EDD74643-CA6F-4ABB-B151-06F1B03A5769' \
  -resultBundlePath /tmp/IslandNotes-Interface-Rebuild.xcresult test
xcrun xcresulttool get test-results summary \
  --path /tmp/IslandNotes-Interface-Rebuild.xcresult
```

Expected: zero failures and zero unexpected skips.

**Step 3: Build the complete scheme for the generic simulator**

```bash
xcodebuild -quiet -project IslandNotes/IslandNotes.xcodeproj -scheme IslandNotes \
  -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```

Expected: exit code 0.

**Step 4: Check minimum-runtime availability**

Use `xcrun simctl list devices available`. If an iOS 17 Dynamic Island simulator is installed, build, launch, and exercise display/edit/Done/library/settings/delete. If unavailable, record the missing runtime rather than claiming coverage.

**Step 5: Run review and remediate findings**

Run `@code-review` from the design-document commit through the implementation head. Resolve every correctness, accessibility, design-system, and test-quality finding, then rerun affected focused tests.

**Step 6: Verify repository state and commit**

```bash
git diff --check
git status --short
git commit -m "feat: complete product interface rebuild"
```

The final handoff must report exact test counts, build result, simulator visual evidence, current commit, and every real-device-only ActivityKit item still requiring manual proof.
