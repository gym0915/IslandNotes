# Island Notes Full Product Interface Rebuild Design

## Goal

Rebuild every Island Notes product surface from the current high-fidelity prototype while preserving the existing SwiftData, editing, note-library, and Live Activity behavior guarantees.

The normative visual and interaction source is `docs/prototypes/island-notes-ios-prototype.png`. Confirmed ADRs clarify behavior that the PNG cannot express. Previous web prototypes and screenshots do not fill gaps or override the current prototype.

## Scope

The rebuild covers:

- Workbench display and editing states.
- Character-capacity presentation.
- The three-action dock and all enabled, disabled, Live, and destructive states.
- More Menu.
- Note Library sheet, empty state, populated state, timestamps, and explicit replacement controls.
- Settings sheet, persistent Automatic/Light/Dark appearance modes, and confirmed no-action support rows.
- App-owned delete confirmation.
- Hints, messages, and recoverable error presentation.
- Dynamic Island Compact, Minimal, and Expanded presentations.
- Lock Screen Live Activity presentation.
- Light and Dark compositions, Dynamic Type, VoiceOver, Reduce Motion, and compact-device adaptation.

Existing exclusions in `docs/adr/0014-explicit-scope-exclusions-for-the-redesign.md` remain in force.

## Recommended Approach

Use a component-system-driven vertical rebuild. Establish the prototype's semantic design tokens and reusable primitives first, then rebuild one complete surface at a time. Each vertical slice includes behavior wiring, accessibility, previews, focused tests, a simulator build, and visual comparison before moving to the next surface.

This approach avoids duplicated styling and makes Light/Dark, Dynamic Type, motion, and state behavior consistent across the App and ActivityKit extension. It also keeps regressions attributable to a small slice instead of replacing every screen at once.

## Architecture

Preserve the existing deep-module boundaries:

- `IslandNotesFeature` remains the SwiftUI user-intent entry point and top-level feature-test seam.
- `NoteWorkspace` remains responsible for SwiftData transactions and current-note invariants.
- `LiveActivitySession` remains responsible for ActivityKit lifecycle, reconciliation, and end barriers.
- `AppRouter` continues to own the single App-level sheet destination.
- A focused `AppearanceSettings` module owns persistent Automatic/Light/Dark selection without acquiring navigation or note responsibilities.

SwiftUI views own only presentation and transient local UI state. More Menu expansion stays local to Workbench. Shared visual components remain stateless or receive narrow bindings. The rebuild does not introduce page ViewModels, a repository protocol, or a second persisted note representation.

## Design System

Centralize all normative tokens and forbid approximate constants in business views.

### Color

Use semantic roles for Canvas, Surface, Raised Surface, Primary Text, Secondary Text, Border, Progress Track, Live, Destructive, and Scrim. Light mode uses a near-white canvas, white surfaces, neutral text, and soft elevation. Dark mode uses a near-black canvas and deep-gray surfaces. Live green is the only routine semantic accent; destructive red is reserved for irreversible actions.

### Typography

Use system SF Pro through semantic roles such as Product Title, Screen Title, Note Body, Action, Caption, Metadata, and Feedback. Every role scales through Dynamic Type. No product content uses a fixed custom point size that prevents accessibility scaling.

### Geometry and motion

- Spacing scale: 4, 8, 16, 24, and 32 points.
- Radius scale: 14, 22, 34, and pill.
- Minimum interactive target: 44 by 44 points.
- Motion duration: 160 to 210 milliseconds.
- Reduce Motion removes displacement, scaling, and pulsing while preserving semantic state changes.

### Icons

App-owned controls use reusable Lucide-style vector icons with a consistent 2-point stroke. Do not replace these with approximate SF Symbols. System-owned keyboard, sheet, and ActivityKit behavior remains native.

### Reusable components

Build narrow components for:

- Circular icon buttons.
- Primary, neutral, Live, destructive, and disabled actions.
- Workbench note surface.
- Character-capacity ring and detail label.
- More Menu and menu rows.
- Sheet header and modal surface.
- Settings groups and rows.
- Library note card and explicit replacement button.
- Hints and messages.
- Delete confirmation surface.
- Dynamic Island brand mark and shared rendered-note content.

## Product Surfaces

### Workbench

Workbench retains generous empty space and makes the current note the only dominant surface. The header communicates product identity and Live state. The note surface switches between committed rendered content and source-text editing without moving persistence logic into the view. The character indicator uses committed source in display state and the in-memory draft while editing. The action dock presents Move to Note Library, Go Live/Live, and Delete Note with the prototype's exact hierarchy and state styling.

### More Menu and sheets

More Menu contains only Note Library and Settings, dismisses outside, and retains local transient state. The App router permits at most one App-level sheet.

Note Library content is readable but not directly actionable by tapping the row. A distinct trailing Replace Current Note control performs the lossless saved-note exchange. Notes are ordered and timestamped according to the current product specification.

Settings persists Automatic, Light, or Dark. Automatic follows the system in real time; Light and Dark override only the App's surfaces. Feedback, Website, and About retain the prototype's pressed appearance but intentionally perform no action.

### Delete confirmation and messages

Delete uses the prototype's App-owned bottom confirmation card and scrim rather than a system alert. Cancellation is lossless. Confirmation still respects the Live Activity end barrier before the atomic note deletion.

Hints and messages present recoverable save, replacement, deletion, or Live errors without erasing valid content or in-memory editing state.

### Live Activity

Compact and Minimal show the approved brand note icon. Expanded and Lock Screen display only committed source, using the same exact `- ` bullet semantics as Workbench. Each system surface owns its line wrapping and truncation. Draft text and App-only appearance preferences never enter ActivityKit content.

## Interaction and State Flow

1. Workbench starts in committed display state.
2. Tapping the note begins an in-memory source editing session.
3. Typing and IME composition update only the draft and its character indicator.
4. Done attempts one explicit SwiftData commit.
5. Success increments the content version, exits editing, renders the result, and updates the same Live Activity when active.
6. Failure keeps the exact draft and editing state and presents a recoverable message.
7. Opening or closing either sheet and normal background/foreground transitions preserve the living-process draft.
8. Library replacement deliberately discards an uncommitted draft, then atomically exchanges saved notes.
9. Archive and delete finish an active Live session before mutating the current note.
10. ActivityKit presentation always derives from committed content.

## Accessibility and Adaptation

All controls expose meaningful English labels, values, and hints. Visual state never depends on color alone. Touch targets remain at least 44 points. VoiceOver grouping preserves the reading and action hierarchy, especially for library cards and the separate replacement control.

Layout uses adaptive SwiftUI composition rather than device-specific copies. Default and maximum accessibility Dynamic Type retain access to editing, Done, sheet controls, and the action dock. Keyboard presentation, safe areas, native sheet behavior, and ActivityKit-hosted dimensions may adapt while preserving essential controls and semantic state.

## Verification

### Automated

- Preserve all existing feature and persistence tests.
- Add focused tests for appearance persistence, library timestamp formatting, component state mapping, and shared rendered-note semantics.
- Add UI tests for the complete display/edit/Done loop, menu and sheet navigation, library replacement, appearance selection and relaunch, custom deletion, Live start/update/stop, and save-failure draft retention.
- Run the full iPhone 16 Pro iOS 26.x scheme.
- Build the complete scheme for a generic iOS Simulator destination.
- When an iOS 17 Dynamic Island simulator runtime is available, build, launch, and exercise the core flow there.

### Visual and accessibility

- Provide previews for empty, display, editing, 240-character, Live, error, menu, library, settings, and delete-confirmation states in Light and Dark.
- Inspect the running App through the Build iOS Apps simulator workflow.
- Capture simulator frames for pixel-level comparison with the prototype.
- Exercise default and maximum Dynamic Type, VoiceOver ordering and labels, 44-point target sizing, Reduce Motion, keyboard handling, and draft preservation across sheets.

### Real-device boundary

Simulator and automated tests cannot prove system selection, permission behavior, exact truncation, Always-On behavior, or residual Lock Screen behavior. The existing real-device checklist must be extended to cover the rebuilt Compact, Minimal, Expanded, Lock Screen, Light/Dark, VoiceOver, payload, lifecycle, and deep-link flows before release.

## Completion Criteria

The rebuild is complete when every prototype product surface and defined state is represented in production SwiftUI, behavior invariants remain green, the full automated suite and generic simulator build pass, simulator visual evidence matches the approved prototype across Light and Dark, and any remaining real-device-only ActivityKit checks are explicitly reported rather than inferred.
