# Legacy SwiftData fixtures

`LegacyStoreV1.store` is a checkpointed SwiftData SQLite store captured from the
pre-refactor `NoteRecord` and `WorkbenchRecord` schema at commit
`a47e56ef751e6c979013e99a31adcc568c012c2a`.
It uses SQLite's `DELETE` journal mode so the same fixture can also be opened through
SwiftData's read-only configuration to characterize failed atomic saves.

It contains one current note, two Note Library entries, and one Workbench pointer.
The values are deterministic and asserted in `LegacyStoreRecoveryTests`; the fixture
loader copies this file before every use so tests never mutate the checked-in source.

SHA-256:

```text
c1a97cf9e047332843e7c75fd7cd428849a420e7a27ff524219d0d57397883be
```
