# Full Interface Rebuild — Simulator Visual Evidence

Captured on 2026-08-10 from the `codex/full-interface-rebuild` worktree after
the Live Activity presentation commit `b28bc39`. The visual reference is
[`island-notes-ios-prototype.png`](../../prototypes/island-notes-ios-prototype.png).

## Environment

- Xcode 26.3 (`17C529`), iOS Simulator 26.2 (`23C54`)
- iPhone 16 Pro, simulator ID `EDD74643-CA6F-4ABB-B151-06F1B03A5769`
- Portrait, 1206 × 2622 screenshots
- Status bar forced to 09:41, full battery, Wi-Fi 3 bars, cellular 4 bars
- Light system appearance at launch; Dark selected through the product's
  Settings UI to verify the real appearance path and immediate propagation
- In-memory SwiftData and the deterministic fake Live controller supplied by
  existing UI-test launch arguments

The screenshot-only `VisualEvidenceUITests` file lived in an isolated
`/tmp/islandnotes-visual-evidence-gial6k` copy. It was never added to the
production or test targets in this worktree.

## Evidence matrix

| Evidence | What it verifies against the prototype |
| --- | --- |
| [01 Light Workbench — empty](01-light-workbench-empty.png) | Centered identity/status, large rounded note surface, placeholder, character ring, bottom action dock |
| [02 Light More menu](02-light-more-menu.png) | Compact two-row overlay anchored to the top-right action |
| [03 Light Library — empty](03-light-library-empty.png) | Shared rounded sheet, centered title/close action, deliberate empty state |
| [04 Light Workbench — editing](04-light-workbench-editing.png) | Source text stays literal while editing, keyboard and explicit Done action are visible |
| [05 Light Workbench — rendered](05-light-workbench-rendered.png) | Only exact `- ` source lines render as bullets after Done |
| [06 Light Workbench — Live](06-light-workbench-live.png) | App header and primary action change to the green Live state |
| [07 Light delete confirmation](07-light-delete-confirmation.png) | Custom scrim and bottom confirmation surface with destructive/neutral actions |
| [08 Light Library — populated](08-light-library-populated.png) | Recent section, archived note card, metadata, and replace action |
| [09 Light Settings](09-light-settings.png) | Appearance and Support groups, shared sheet chrome, Automatic selection |
| [10 Dark Settings](10-dark-settings.png) | Immediate Dark selection and adaptive grouped surfaces |
| [11 Dark More menu](11-dark-more-menu.png) | Overlay contrast, spacing, separators, and icons in Dark mode |
| [12 Dark Library — populated](12-dark-library-populated.png) | Populated sheet/card hierarchy and metadata contrast in Dark mode |
| [13 Dark Workbench — rendered](13-dark-workbench-rendered.png) | Rendered bullet semantics, action dock, ring, and dark card hierarchy |
| [14 Dark Workbench — 240 characters](14-dark-workbench-editing-240.png) | Swift Character limit clamps a 241-character input to 240 and shows the orange full ring |
| [15 Dark delete confirmation](15-dark-delete-confirmation.png) | Dark scrim, glass-like confirmation surface, and destructive hierarchy |
| [16 Light save failure](16-light-save-error-preserves-draft.png) | Failed Done retains the source draft and editing state; the recoverable feedback seam was asserted before capture |

## Reproduction

The isolated test launched the app through the same accessibility identifiers
used by the committed UI suite and retained each `XCUIScreen` capture as an
XCTest attachment. Representative commands:

```sh
xcrun simctl ui EDD74643-CA6F-4ABB-B151-06F1B03A5769 appearance light
xcrun simctl status_bar EDD74643-CA6F-4ABB-B151-06F1B03A5769 override \
  --time 9:41 --batteryState charged --batteryLevel 100 \
  --wifiBars 3 --cellularBars 4

xcodebuild test \
  -project IslandNotes.xcodeproj \
  -scheme IslandNotes \
  -destination 'platform=iOS Simulator,id=EDD74643-CA6F-4ABB-B151-06F1B03A5769' \
  -derivedDataPath /tmp/islandnotes-visual-evidence-gial6k/DerivedData \
  -resultBundlePath /tmp/islandnotes-visual-evidence-gial6k/VisualEvidence.xcresult \
  -only-testing:IslandNotesUITests/VisualEvidenceUITests/testCapturePrototypeInterfaceStates \
  -parallel-testing-enabled NO

xcrun xcresulttool export attachments \
  --path /tmp/islandnotes-visual-evidence-gial6k/VisualEvidence.xcresult \
  --output-path /tmp/islandnotes-visual-evidence-gial6k/exported
```

Result: **1 test passed, 0 failures, 59.830 seconds**. The result bundle reports
the expected iPhone 16 Pro / iOS 26.2 device and sixteen retained attachments.

## Scope and limitations

- `06-light-workbench-live.png` proves the app-side Live transition using the
  deterministic controller. It is not evidence of a real ActivityKit system
  surface.
- Compact, Minimal, Expanded Dynamic Island, and Lock Screen presentations
  were not captured. Those system-managed surfaces are not reliably
  addressable by this deterministic XCUITest setup, so no simulated or staged
  image is presented as real evidence.
- Editing and 240-limit captures intentionally retain the system keyboard.
- The status bar is fixed, but the Library card timestamp reflects the actual
  capture run and should be compared semantically rather than as a pixel-stable
  time value.
- The visual run uses an in-memory store. Durable restart recovery is validated
  by the feature/integration suite, not claimed by these screenshots.
