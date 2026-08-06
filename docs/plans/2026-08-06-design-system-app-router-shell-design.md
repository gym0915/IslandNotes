# Design System, AppRouter, and App Shell Design

## Scope

This slice establishes the shared visual and navigation foundation for the Island Notes redesign. It changes the user-visible product name and shell copy to English, adds a typed Lucide icon asset strategy, replaces the old library push navigation with a local More Menu and one App-level sheet route, and supplies representative Light/Dark previews. Note Library behavior remains available inside the new shell; Settings uses transitional content until its dedicated slice.

The slice does not introduce page ViewModels, persistent appearance preferences, the redesigned note display/edit state machine, or final Library and Settings page behavior.

## Architecture

`AppRouter` is a small `@MainActor @Observable` module. Its only state is an optional `AppSheet` value whose cases are Note Library and Settings. Presenting either destination replaces the current value, dismissal clears it, and a valid Workbench deep link clears it. The optional enum makes two simultaneous App-level sheets unrepresentable.

`AppRootView` creates and retains the router alongside `IslandNotesFeature`. A single `.sheet(item:)` renders both destinations through one shared rounded `AppSheetContainer`. `WorkbenchView` receives navigation actions and owns only the lightweight More Menu expansion flag.

## Design System

`IslandDesign` centralizes semantic Light/Dark colors, SF typography roles, the 4/8/16/24/32 spacing scale, 14/22/34/pill radii, elevation and material roles, a 44-point minimum touch target, and 160–210 ms motion. Green is exposed only as the valid Live-state semantic color.

App-owned icons use a typed `AppIcon` interface backed by maintained 24×24 Lucide SVG assets. The original Lucide geometry keeps its 2-unit stroke, round line caps, and round joins; SwiftUI uses template rendering so semantic foreground colors remain centralized. System-owned controls continue to use native system presentation.

## App Shell and Navigation

The Workbench header shows `Island Notes` and a More button. The menu contains exactly `Note Library` and `Settings`; selecting an item closes the menu and presents the matching sheet. A full-shell outside-tap layer dismisses the menu without changing AppRouter state.

The shared sheet container provides system background dimming, a visible drag indicator, a 34-point presentation corner radius, a centered title, and a circular 44-point close button. Dismissal from the drag gesture or close button clears router state. Opening or closing a sheet does not mutate note data or editing content.

Library reuses the existing data projection in the new container. Settings intentionally displays English transitional content only. All shell, menu, sheet, action, feedback, and accessibility strings touched by this slice are English. `CFBundleDisplayName` becomes `Island Notes`; internal target and Swift names remain `IslandNotes`.

## Accessibility and Motion

All controls meet or exceed the 44-point touch target, use English accessibility names, and expose stable identifiers only at user-facing UI seams. The menu transition uses the centralized short animation when Reduce Motion is off and no animation when it is on. Sheet scrolling and Dynamic Type remain native and adaptive.

## Verification

Focused `AppRouter` tests verify library/settings presentation, replacement exclusivity, dismissal, valid deep-link return to Workbench, and invalid URL no-op behavior. UI automation verifies the More Menu contents, outside-tap dismissal, both sheet shells, close behavior, and English product naming. SwiftUI previews cover Light and Dark app shells, the More Menu, and both sheet containers.
