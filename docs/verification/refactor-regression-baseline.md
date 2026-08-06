# Refactor Regression Baseline

Recorded on 2026-08-06 before responsibility-moving refactors.

- Fixed point: `a47e56ef751e6c979013e99a31adcc568c012c2a`
- Project: `IslandNotes/IslandNotes.xcodeproj`
- Scheme: `IslandNotes`
- Destination: iPhone 16 Pro simulator, iOS 26.2
- Result: 46 tests executed, 0 failures

```bash
xcodebuild -project IslandNotes.xcodeproj \
  -scheme IslandNotes \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro 26,OS=26.2' \
  -only-testing:IslandNotesFeatureTests \
  test
```

## Valid regression surface

| Area | Baseline suites | Observable contract retained |
| --- | --- | --- |
| Feature | `IslandNotesFeatureTests`, `CharacterLimitTests` | One current note, public editing actions, grapheme limit, persisted committed content, feature recreation |
| Activity payload | `ActivityPayloadTests`, `LiveActivityPresentationTests` | Codable payload, production byte measurement, 4 KB validation, system-surface content and deep link |
| Note Library | `LibraryMutationTests` | Archive order, lossless explicit swap, deletion confirmation, coherent persisted records |
| Reconciliation | `ReconciliationTests` | ActivityKit enumeration is truth, deterministic duplicate cleanup, orphan cleanup, inconsistent cleanup blocks new requests |
| Live lifecycle | `LiveActivityLifecycleTests` | One current activity, request/update failure behavior, update identity, end barrier |
| Deep link | `DeepLinkRoutingTests` | Live Activity links route only to Workbench; unknown hosts are ignored |
| Controller contract | `ActivityKitControllerContractTests` | The production ActivityKit adapter conforms to `LiveActivityControlling` |

## Explicitly not promoted to a new contract

The refactor safety net does not require or add assertions for:

- automatic saving while the user is still editing;
- exact Chinese feedback or confirmation strings;
- replacing a library note by tapping the whole row;
- the old SwiftUI view hierarchy, controls, or layout.

Existing tests may use content strings as inert test data. New characterization tests verify public feature state, SwiftData records, and fake ActivityKit results only.

## Added safety net

This ticket raises the functional target to 57 tests after retiring one obsolete
per-keystroke persistence test. The added safety net includes:

- two fixture-backed legacy-store recovery tests;
- three coherent transaction/unique-current tests and three forced-save-failure rollback tests;
- three Activity end-barrier tests, one for each content transaction;
- two exact 4,096-byte/4,097-byte payload boundary tests covering request and update.
