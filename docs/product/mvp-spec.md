# Island Notes 新版设计与职责重构规格

- Tracker: `local-markdown`
- Label: `ready-for-agent`
- Status: `open`

## Problem Statement

Island Notes 已经有一版可运行的原生 iPhone 实现，能够维护唯一当前便签、在本机保存便签库，并通过 Live Activity 把当前便签投影到 Dynamic Island 和 Lock Screen。现有实现证明了 SwiftUI、SwiftData、ActivityKit、WidgetKit 与 Observation 的基本产品链路，也积累了内存数据库、ActivityKit fake、功能组合测试、UI 测试和真机验收清单。

但当前界面已经不再符合最新高保真产品方向。新版原型引入了完整的 Workbench 展示态与编辑态、显式 `Done` 提交、渲染后的圆点列表、More Menu、sheet 形式的 Note Library 与 Settings、持久化显示模式、定制删除确认、完整组件状态和规范性 Design System。旧规格仍描述常驻编辑器、每次输入自动保存、直接 Library 入口、整行交换、无 Settings、自定义外观不在范围等旧行为；若继续以旧规格或旧测试文案为准，会得到一个行为和视觉都错误的版本。

同时，当前 `IslandNotesFeature` 集中了界面状态、SwiftData 启动与事务、编辑保存、便签库操作、Live Activity 启动与停止、更新防抖、结束屏障、系统对账和错误反馈。这个集中入口适合作为最高层行为 seam，但职责已经过多，使新版页面状态、导航、外观和系统生命周期更难独立理解、验证和维护。问题不是缺少“MVVM”标签，而是持久化不变量、Live Activity 生命周期、App 导航和外观偏好没有形成边界清晰的深模块。

这次改版需要在不丢失现有数据、不破坏已经验证的 Live Activity 行为、并持续保持高层行为测试可用的前提下完成。实现不能通过大爆炸式重写、重置 SwiftData、引入没有第二个 adapter 的抽象层，或给每个按钮和视觉组件增加浅薄 ViewModel 来换取表面上的分层。

## Solution

把 Island Notes 更新为最新高保真原型定义的英文原生 iPhone 产品，并以 Workbench 作为唯一当前便签的工作位置。当前便签默认显示渲染内容；用户点击便签进入纯源文本编辑，输入只修改内存编辑草稿，点击 `Done` 才提交到 SwiftData。只有源文本中以 `- ` 开头的行渲染为圆点列表；源文本本身仍是唯一持久内容和 240 个用户感知字符的计数对象。

Workbench 的 More Menu 只提供 Note Library 和 Settings。两者以最新原型中的圆角 sheet 呈现。Note Library 按最近进入库的时间倒序显示便签，每行通过明确的行尾替换按钮交换当前便签；Settings 提供持久化的 Automatic、Light 和 Dark 显示模式，并保留 Feedback、Website 与 About 的无动作占位行。删除使用原型规定的 App 自有底部确认界面。产品界面、反馈和无障碍文案本次全部使用英文。

保留唯一当前便签、原子入库/替换/删除、240 字素限制、4 KB Activity payload 检查、最长 8 小时 Live 会话、ActivityKit 实际状态事实来源、结束屏障、启动/前台/deep link 对账以及既有数据原地升级。Live 会话使用 `Go Live` / `Live` 单一控件管理；Dynamic Island Compact 与 Minimal 只显示品牌便签图标，Expanded 和 Lock Screen 使用已提交源文本并呈现相同的圆点列表语义，同时允许系统根据各自空间独立换行和截断。

架构采用 Feature 组合层加深模块，而不是把完整 MVVM 当作目标。保留 `@MainActor @Observable IslandNotesFeature` 作为 SwiftUI 的统一用户意图入口、跨模块用例协调者和最高层测试 seam；把 SwiftData 事务与领域不变量集中到 `NoteWorkspace`，把 Live Activity 生命周期集中到 `LiveActivitySession`，把显示模式集中到 `AppearanceSettings`，并使用独立 `AppRouter` 管理 App 级 sheet 和 deep link。SwiftUI Views 负责声明式呈现、布局、系统环境和短暂本地交互；可复用视觉组件保持无状态。

实施采用增量迁移：先做保持行为不变的小范围职责抽取，再按 Design System、Workbench、Note Library、Settings、Live presentation、删除与反馈等纵向切片逐步完成必要重构和新版界面，每个切片都通过现有最高层功能测试、聚焦模块测试、UI/视觉验证和适当的真机验证后再继续。

## User Stories

1. As a returning Island Notes user, I want the redesigned app to open with all of my existing notes intact, so that the redesign never costs me saved content.
2. As a returning user, I want my existing current note to remain the current note after upgrading, so that the app does not silently change my work context.
3. As a returning user, I want existing library notes, stable identifiers, content versions, and timestamps to survive the upgrade, so that historical ordering and Live Activity identity remain coherent.
4. As a first-time user, I want the app to create exactly one blank current note, so that the Workbench is immediately usable without a separate creation flow.
5. As a user, I want the app to repair a missing or invalid Workbench pointer without deleting valid notes, so that local persistence failures converge to a usable state.
6. As a user, I want the redesigned app to start in the Workbench display state, so that saved content is presented clearly before I choose to edit it.
7. As a user, I want an old saved body to become the new source text without conversion, so that migration does not rewrite my words.
8. As a user with no previous appearance preference, I want the redesigned app to default to Automatic, so that its first appearance matches the system.
9. As a user, I want the Workbench to remain the one canonical place for the current note, so that I never have to decide which note is actively being worked on.
10. As a user, I want the Workbench to show rendered content by default, so that the note reads like the final presentation instead of a permanent text editor.
11. As a user, I want to tap the current note to enter editing, so that the transition from reading to changing it is direct.
12. As a user, I want editing to expose the exact pure source text, so that list prefixes, spaces, and line breaks remain under my control.
13. As a user, I want only lines beginning with `- ` to render as round bullet rows, so that the supported formatting rule is predictable.
14. As a user, I want Markdown-like syntax other than `- ` to remain ordinary text, so that the app does not invent formatting behavior that it does not support.
15. As a user, I want typing to update only an in-memory editing draft, so that my saved note changes only when I explicitly finish editing.
16. As a user, I want `Done` to commit my editing draft, so that there is one unambiguous save action.
17. As a user, I want a successful `Done` action to return the note to rendered display, so that I can immediately inspect the committed result.
18. As a user, I want a failed `Done` save to preserve my draft and keep me in editing, so that a storage error never discards my work.
19. As a user, I want an uncommitted draft to remain while I briefly background and resume the still-running app, so that an ordinary interruption does not reset my edit.
20. As a user, I want an uncommitted draft to remain while I open and close Note Library or Settings, so that inspecting another sheet does not implicitly save or discard it.
21. As a user, I accept that an uncommitted draft may be lost when the app process terminates, so that the product does not imply persistence before `Done`.
22. As a user, I want the committed source text to remain the only persistent content truth, so that rendered content and editing drafts cannot diverge into separate notes.
23. As a user, I want whitespace, punctuation, line breaks, Chinese characters, English text, numbers, and composed Emoji to be preserved verbatim, so that the app does not normalize my note.
24. As a user, I want actions requiring meaningful content to treat whitespace-only text as blank without trimming saved source text, so that eligibility rules do not rewrite my content.
25. As a user, I want the Workbench to use the user-visible product name `Island Notes`, so that the interface follows the approved naming.
26. As a user, I want every visible label, error, and accessibility string in this release to be English, so that the product language is consistent.
27. As a user, I want editing focus, the system keyboard, and local menu expansion to behave like native transient UI state, so that ordinary SwiftUI interactions remain familiar.
28. As a user, I want source text limited to 240 user-perceived characters, so that the note remains within the product's intended capacity.
29. As a user, I want the 240-character rule to count Swift extended grapheme clusters rather than bytes or UTF code units, so that a composed Emoji counts as one perceived character.
30. As a user, I want `- ` prefixes, spaces, punctuation, and line breaks included in the 240 count, so that the capacity reflects exactly what I typed.
31. As a user, I want rendered bullet markers not to add to the count, so that presentation does not change source capacity.
32. As a user, I want ordinary typing beyond 240 characters rejected without splitting a grapheme, so that the saved note remains valid.
33. As a user, I want an over-limit paste to keep the longest complete prefix that fits, so that useful pasted content is retained predictably.
34. As a user using an input method editor, I want marked text to remain composable until the composition is committed, so that the character limiter does not corrupt intermediate input.
35. As a user, I want the character ring to reflect the draft while editing and committed source while displaying, so that its value matches the content currently in context.
36. As a user, I want to tap the character ring and see `N used · M remaining`, so that I can understand both capacity values.
37. As a user, I want the character detail to fade after two seconds and a repeated tap to restart that interval, so that the detail is available without permanently occupying space.
38. As a user at the limit, I want the detail to show `240 used · 0 remaining`, so that the boundary is explicit.
39. As a user, I want Workbench actions to be disabled for a blank current note, so that Go Live, Move to Note Library, and Delete Note cannot create meaningless operations.
40. As a user, I want the More Menu to contain only Note Library and Settings, so that the top-level navigation remains focused.
41. As a user, I want tapping outside the More Menu to dismiss it, so that it behaves like a lightweight native menu.
42. As a user, I want Note Library to open as a sheet rather than a navigation push, so that the Workbench remains the persistent background context.
43. As a user, I want Settings to open as a sheet rather than a navigation push, so that appearance changes remain a modal task.
44. As a user, I want only one App-level sheet visible at a time, so that routing state cannot become ambiguous.
45. As a user, I want both sheets to use the approved rounded modal surface, background dimming, drag indicator, centered title, and circular close control, so that they match the high-fidelity design.
46. As a user, I want closing either sheet to return me to the same Workbench state, so that navigation does not mutate the current note or draft.
47. As a user, I want Note Library to list only non-current notes, so that the unique current note remains conceptually separate.
48. As a user, I want library notes ordered by their most recent library-entry time, newest first, so that the most recently moved or replaced note is easiest to recover.
49. As a user, I want library timestamps displayed in fixed English 12-hour form using Today, Yesterday, a weekday, or a dated form with year for older entries, so that temporal context is concise and consistent.
50. As a user, I want each library row to expose a distinct trailing replace button, so that replacement is deliberate rather than triggered by touching the row.
51. As a VoiceOver user, I want the visual-only replace button named `Replace current note`, so that its destructive context is understandable.
52. As a user, I want selecting the row itself to do nothing, so that scrolling or inspecting text cannot accidentally replace my current note.
53. As a user, I want replacing from the library to make the selected saved note current, so that I can resume an earlier note.
54. As a user with a nonblank committed current note, I want replacement to move that outgoing note to the top of the library, so that no committed content is lost.
55. As a user with a blank committed current note, I want replacement to remove the blank record instead of adding it to the library, so that the library contains no meaningless blank entries.
56. As a user, I want the replacement to be atomic, so that a failure cannot leave two current notes or lose either committed note.
57. As a user, I want a successful replacement to close Note Library and return to Workbench, so that the newly current note is immediately visible.
58. As a user, I want a failed replacement to remain in Note Library and report that it did not complete, so that the interface never presents false success.
59. As a user replacing a note while editing, I want the replace button to remain available and immediately discard the uncommitted draft without saving or confirmation, so that the explicitly chosen library note takes precedence.
60. As a user, I want Move to Note Library to place the committed current note at the top of the library and create a new blank current note, so that I can clear the Workbench without deleting the note.
61. As a user, I want a successful move to report `Note moved to your library.`, so that the result is clear.
62. As a user, I want a failed move to preserve the original data and avoid a false success message, so that local persistence remains trustworthy.
63. As a user, I want Delete Note to be unavailable for a blank current note, so that deletion only represents a meaningful permanent action.
64. As a user, I want Delete Note to open the approved bottom confirmation dialog with `Delete this note?`, `Cancel`, and `Delete Note`, so that irreversible deletion is explicit.
65. As a user, I want Cancel to close the dialog without changing data, so that I can safely back out.
66. As a user, I want confirming deletion to permanently remove the committed current note and create one blank current note, so that the Workbench remains valid afterward.
67. As a user, I want a failed delete transaction to retain the note and report failure, so that storage errors cannot silently erase or replace content.
68. As a user, I want Settings to include an Appearance section with Automatic, Light, and Dark, so that I can control the App's visual mode.
69. As a user, I want Automatic to track the current system appearance live, so that the App follows device preferences.
70. As a user, I want Light to keep App-owned screens light even when the system is dark, so that I can choose a consistently light App.
71. As a user, I want Dark to keep App-owned screens dark even when the system is light, so that I can choose a consistently dark App.
72. As a user, I want my display mode to persist across relaunches, so that I do not need to reselect it.
73. As a user, I want display mode to affect Workbench, Note Library, Settings, More Menu, feedback, and the custom delete dialog, so that the App-owned interface is consistent.
74. As a user, I want Dynamic Island and Lock Screen appearance to remain controlled by iOS, so that App settings do not claim control over system-owned surfaces.
75. As a user, I want Feedback, Website, and About rows to look pressable and show press feedback, so that Settings matches the approved prototype.
76. As a user, I expect Feedback, Website, and About to perform no action in this release, so that placeholder behavior matches the confirmed scope.
77. As a user, I want no Privacy row in this release, so that the interface does not imply an unconfirmed destination.
78. As a user with a nonblank committed note, I want to tap `Go Live` to request a Live Activity, so that the note can appear on system surfaces.
79. As a user, I want `Go Live` to change to green `Live` only after ActivityKit confirms one active activity for the current note, so that the UI reflects system truth rather than an optimistic flag.
80. As a user, I want to tap `Live` to stop the current Live session while retaining the note, so that ending system display never deletes content.
81. As a user, I want a successfully stopped session to return the control to `Go Live`, so that I can explicitly start another session later.
82. As a user, I want a newly blank, moved, deleted, or library-replaced current note not to start Live automatically, so that every new session requires explicit intent.
83. As a user, I want a successful `Done` commit during a Live session to update the same Activity rather than start another one, so that the system presentation follows the committed note.
84. As a user, I want Live updates to use a short cancellable debounce and send the latest committed value, so that repeated commits do not create stale system updates.
85. As a user, I want a draft that has not been committed with `Done` to remain absent from Live Activity, so that system surfaces never show unsaved content.
86. As a user, I want every Live start or update to validate the final encoded attributes and content state against the 4 KB ActivityKit limit, so that oversized Unicode payloads fail safely.
87. As a user, I want a Live start failure to keep the product non-Live and provide retryable English feedback, so that the UI never claims a session exists when it does not.
88. As a user, I want a Live update failure to preserve the committed SwiftData content, keep the actual system state, and warn that system display may not be synchronized, so that local data remains authoritative.
89. As a user, I want a Live stop failure to re-enumerate ActivityKit and remain `Live` when the activity is still active, so that I can retry without being misled.
90. As a user, I want Move, Replace, and Delete to end the current Live session and confirm its absence before changing note identity, so that the system never displays a note that is no longer current.
91. As a user, I want a failed Live end barrier to cancel the content transaction and preserve all notes, so that current-note and Live-session identity cannot diverge.
92. As a user, I want the app to reconcile ActivityKit at startup, foreground entry, and Live deep link handling, so that external system changes converge to accurate UI state.
93. As a user, I want reconciliation to keep at most one valid activity for the current note and attempt to end orphaned or duplicate activities, so that the one-session invariant is restored.
94. As a user, I want unresolved duplicate or orphan activity cleanup to block a new `Go Live` request and show retryable feedback, so that the app does not add more inconsistent sessions.
95. As a user, I want a session that expires, is removed, is disabled, or is ended by iOS to converge to non-Live while preserving the complete note, so that system lifecycle changes never become data loss.
96. As a user, I want a Live session to request a maximum lifetime of eight hours, allow iOS to end it earlier, and never renew automatically, so that temporary display remains an explicit finite session.
97. As a user, I want Dynamic Island Compact to show only the brand note icon on the leading side, with no trailing dot, status, or text, so that the compact presentation matches the prototype.
98. As a user, I want Dynamic Island Minimal to show only the brand note icon, so that the app remains identifiable when iOS selects the smallest presentation.
99. As a user, I want Dynamic Island Expanded to show the committed note with the same bullet semantics as Workbench, so that supported formatting remains consistent.
100. As a user, I want Lock Screen presentation to show the same committed source and bullet semantics while using its own layout and truncation, so that system space is used appropriately.
101. As a user, I want Compact, Minimal, Expanded, and Lock Screen taps to open Workbench, so that every system entry returns to the current note.
102. As a user, I want a historical or stale note identifier in a deep link ignored, so that deep links never restore, swap, delete, or restart a note automatically.
103. As a user, I want the App-owned interface to match the prototype's semantic colors, SF font roles, spacing scale, corner radii, materials, shadows, sizing, hierarchy, and component states, so that the redesign is implemented as a system rather than an approximation.
104. As a user, I want App-owned icons to use the approved Lucide 2px stroke visual language, so that iconography remains consistent across Workbench, Library, Settings, menus, and dialogs.
105. As a user, I want system-owned keyboard, sheet behavior, ActivityKit hosting, and platform gestures to remain native, so that the app respects iOS behavior.
106. As a user, I want valid Live status to be the only use of the approved green state color, so that green has one reliable meaning.
107. As a user, I want touch targets to be at least 44 points and states not to rely only on color, so that controls remain operable and understandable.
108. As a Dynamic Type user, I want App layouts to adapt at default and maximum accessibility sizes without hiding essential content or actions, so that the complete flow remains usable.
109. As a VoiceOver user, I want English names, values, states, focus order, and timely error announcements for the complete core flow, so that the app is operable without sight.
110. As a Reduce Motion user, I want nonessential transitions and state animations removed or significantly simplified, so that the interface remains comfortable.
111. As a user, I want ordinary transitions to follow the approved 160–210 ms motion range when Reduce Motion is off, so that feedback feels coherent with the Design System.
112. As a user, I want native adaptation for safe areas, keyboard, Dynamic Type, VoiceOver, system sheets, and ActivityKit constraints, so that strict visual fidelity does not break platform usability.
113. As a developer, I want representative Light and Dark previews for every key page and component state, so that visual regressions are discoverable before device testing.
114. As a developer, I want the refactor to preserve one highest-level feature test seam, so that behavior remains protected while responsibilities move internally.
115. As a developer, I want feature tests to drive public user actions using an in-memory SwiftData container, a fake Live Activity controller, isolated appearance storage, and a real AppRouter, so that product flows can be verified without implementation coupling.
116. As a developer, I want tests to assert observable state, persisted records, and fake system activity results, so that they remain stable through internal restructuring.
117. As a developer, I want changed old tests rewritten only where a confirmed new behavior replaces them, so that accidental behavior regressions remain visible.
118. As a developer, I want focused tests for NoteWorkspace, LiveActivitySession, and AppearanceSettings in addition to combination tests, so that deep-module edge cases are localized without losing end-to-end confidence.
119. As a developer, I want each vertical slice to keep the test suite green before the next slice begins, so that the redesign is incremental rather than a big-bang rewrite.
120. As a release verifier, I want the full Feature and UI suite run on an iPhone 16 Pro with the current iOS 26.x simulator, so that the primary target has repeatable automated evidence.
121. As a release verifier, I want the app built, launched, and exercised through its core flow on a minimum-supported iOS 17.x Dynamic Island simulator, so that deployment compatibility remains real.
122. As a release verifier, I want system appearance crossed with Automatic, forced Light, and forced Dark, including relaunch persistence, so that appearance behavior is complete.
123. As a release verifier, I want visual and functional checks at default and maximum Dynamic Type, with VoiceOver and Reduce Motion, so that accessibility is part of acceptance rather than a follow-up.
124. As a release verifier, I want at least one current iOS 26.x Dynamic Island iPhone used for Live start, update, stop, reconciliation, presentation, lifecycle, and privacy checks, so that simulator behavior is not mistaken for ActivityKit proof.
125. As a release verifier, I want a second Dynamic Island width tested on a real device when available, or explicitly labeled simulator evidence otherwise, so that width-specific results remain honest.

## Implementation Decisions

1. **Authority and terminology.** This specification is the consolidated implementation contract. It derives first from the confirmed redesign decisions and ADRs, then from the latest high-fidelity PNG, then from still-valid existing code and tests, then from unaffected portions of the previous specification. Previous prototypes, plans, audits, and deleted assets are historical only. Product and implementation language must use the project glossary: `Island Notes`, Workbench, current note, source text, editing draft, rendered content, Note Library, Live session, and the confirmed module names.

2. **Platform and existing technical foundation.** Continue as a native iPhone app using SwiftUI, SwiftData, ActivityKit, WidgetKit, and Observation, with iOS 17 as the minimum deployment target. The supported product target remains Dynamic Island iPhones. The app remains local-only with no account, backend, network dependency, or iCloud synchronization.

3. **Architectural objective.** Do not treat “MVVM” as the goal. The goal is to isolate state ownership, persistence invariants, ActivityKit lifecycle, navigation, appearance, and presentation so that each has a small public interface backed by complete behavior. Use Feature composition with deep modules, retain the highest-level behavior seam, and avoid pass-through abstractions.

4. **Composition and lifetime ownership.** The App root creates and retains the SwiftData container, production ActivityKit adapter, `NoteWorkspace`, `LiveActivitySession`, `AppearanceSettings`, `AppRouter`, and `IslandNotesFeature`. It connects app lifecycle and incoming URLs to the feature and router. Long-lived objects are not recreated by page rendering.

5. **SwiftUI View responsibilities.** SwiftUI Views declare layout, accessibility, environment adaptation, and bindings to observable state. Workbench may own only short-lived focus and More Menu expansion; sheets may own native dismissal mechanics. Views send public user intents to the feature, router, or appearance module and do not execute SwiftData transactions or call ActivityKit directly. More Menu, note card, character ring, buttons, library rows, settings rows, hints, Live indicators, and the delete dialog are stateless value/action components. No `WorkbenchViewModel`, `NoteLibraryViewModel`, `SettingsViewModel`, or per-control ViewModel is introduced in this scope.

6. **`IslandNotesFeature` responsibility.** Keep one `@MainActor @Observable` feature as the Workbench-facing behavior facade, owner of editing-session presentation state, delete-confirmation presentation state, user feedback, and cross-module use-case sequencing. Its public interface expresses user actions such as bootstrap, begin editing, stage text, commit with `Done`, reveal character details, move, replace, request/cancel/confirm deletion, start/stop Live, reconcile, and handle relevant lifecycle events. It exposes user-observable projections rather than underlying SwiftData models or ActivityKit objects.

7. **`NoteWorkspace` responsibility and interface.** Introduce a deep module that owns SwiftData access, bootstrap/repair, the unique-current-note invariant, committed source text, library projection, and atomic commit/move/replace/delete transactions. Its public interface operates in domain terms and returns stable snapshots or explicit failures. It does not know ActivityKit, `LiveActivityControlling`, Live status, editing drafts, App routing, or visual presentation. SwiftData has one real persistence adapter, so do not add a `RepositoryProtocol`.

8. **`LiveActivitySession` responsibility and interface.** Introduce a deep module that owns Activity enumeration, start, update debounce, flush, stop, end barrier, duplicate/orphan cleanup, and reconciliation. It derives Live state from actual active ActivityKit sessions and exposes a small session state plus outcome/error interface to the feature. It does not mutate SwiftData current-note identity or own App navigation.

9. **`LiveActivityControlling` seam.** Preserve the existing seam because it has both a real ActivityKit adapter and a test fake. It continues to expose reading the app's activities, requesting one activity, updating a specific activity, and ending a specific activity. Do not broaden it with UI, persistence, retry policy, or feature state.

10. **`AppearanceSettings` responsibility and interface.** Introduce an independently observable module for the three-value display mode and its persistence. It exposes Automatic, Light, and Dark, applies the corresponding App-scoped color-scheme behavior, and defaults existing users to Automatic. It owns neither general Settings navigation nor note data.

11. **`AppRouter` responsibility and interface.** Introduce an independently observable router with only three App-level destinations: Workbench as the base, Note Library sheet, and Settings sheet. It presents and dismisses either sheet, enforces at most one sheet, and routes all valid Live Activity deep links back to Workbench. It does not own More Menu state, editing state, delete confirmation, errors, current-note data, or Live lifecycle.

12. **Cross-module transaction ordering.** For Move, Replace, and Delete, the feature first asks `LiveActivitySession` to complete and verify the end barrier for the current note. Only after the session is confirmed absent may it invoke the corresponding `NoteWorkspace` transaction. If the barrier fails, no content transaction occurs. If the barrier succeeds but the SwiftData transaction fails, committed note data remains unchanged, the feature reflects non-Live system truth, and an English retryable error is shown.

13. **Data compatibility.** Preserve the existing SwiftData records and logical schema: stable note identifier, body/source text, content version, creation and modification times, library-entry time, and the Workbench pointer. Do not reset or replace the store. Existing body values become source text directly. Existing records first appear in display state. Any schema evolution must use a migration compatible with existing stores and be covered by upgrade tests.

14. **Current-note invariant.** At every committed boundary, exactly one valid current note exists and all other eligible notes are in Note Library. Bootstrap repairs a missing/invalid pointer without deleting valid content. Blank replacement records never enter the library. Transactions preserve deterministic reverse library ordering.

15. **Editing state machine.** Display state shows rendered committed content. Beginning editing copies source text into an in-memory draft. Character limiting applies to that draft. Typing, opening sheets, closing sheets, or ordinary backgrounding does not write SwiftData or Live Activity. `Done` is the sole normal commit action. Save success updates the current note and content version, schedules a Live update when applicable, clears editing state, and shows rendered content. Save failure retains draft and editing state. Process termination may discard the draft. Library Replace is the explicit exception and silently discards any draft before replacing the current note.

16. **Source text and rendering.** Source text is verbatim truth. Split it by source lines for presentation; only a line whose first two characters are hyphen plus space is a list line and renders with a round bullet. The stored prefix remains unchanged and counts toward capacity. All other Markdown syntax remains literal. Workbench display, Dynamic Island Expanded, and Lock Screen share these semantics, but each surface owns its layout and truncation.

17. **Character limiting and input methods.** Limit source/draft input to 240 Swift `Character` values. Never truncate an extended grapheme cluster. Delay final limiting while marked text is active, then apply it to the committed composition. Reject ordinary overflow and retain the longest whole-character prefix of an over-limit paste. Count the draft in editing state and committed source in display state.

18. **Character detail behavior.** Tapping the ring presents fixed English detail in the form `N used · M remaining` for two seconds. A repeated tap restarts the timer. At capacity it reads `240 used · 0 remaining`. The ring and transient text use the prototype's defined normal, active, and limit states and provide an accessibility value.

19. **Actionable-content rule.** Go Live, Move to Note Library, and Delete Note require at least one non-whitespace Unicode scalar. This rule controls availability only; it never trims, normalizes, or rewrites source text.

20. **Note Library behavior.** Present Note Library as the approved sheet. Query non-current notes ordered by descending most-recent library-entry time with a deterministic tie-breaker. Display fixed English 12-hour timestamps: `Today · h:mm a`, `Yesterday · h:mm a`, weekday plus time for the recent weekly form, and abbreviated month/day/year plus time for older entries. The row itself does not replace. The trailing circular Lucide-style action has the accessibility name `Replace current note`.

21. **Replace transaction.** Replacing makes the selected library note current. A nonblank committed outgoing current note receives the current library-entry time and moves to the top; a blank outgoing record is deleted. The entire data change is atomic. A successful replacement dismisses the sheet; a failure keeps it open and reports no false success. Replacement is available during editing and discards the draft without saving or confirming.

22. **Move transaction.** Move applies only to actionable committed content, performs the end barrier first, assigns the outgoing current note a new library-entry time, creates one blank current note, and changes the Workbench pointer atomically. Success reports `Note moved to your library.`; failure preserves data and reports the incomplete operation.

23. **Delete transaction and confirmation.** Delete applies only to actionable committed content and uses the custom bottom dialog defined by the prototype, not the prior native alert. The strings are `Delete this note?`, `Cancel`, and `Delete Note`. Confirmation performs the end barrier, permanently deletes the current record, creates one blank current note, and updates the pointer atomically. Cancel changes nothing; failure retains the note and keeps the system/data state truthful.

24. **Menu and sheet presentation.** More Menu contains only Note Library and Settings and dismisses on an outside tap. Both destinations use the prototype's rounded sheet surface with background context/dimming, drag indicator, centered title, and circular close button. Sheet presentation does not commit or cancel editing.

25. **Settings and display mode.** Automatic follows system changes; Light and Dark force only App-owned surfaces. Persist the selection across launches. Apply it to Workbench, sheets, More Menu, feedback, and custom dialogs, but never claim control over ActivityKit-hosted Dynamic Island or Lock Screen appearance.

26. **Settings placeholders.** Feedback, Website, and About appear and provide visual press feedback but perform no action, navigation, message, or accessibility “not available” hint. Privacy does not appear. This is a confirmed scope exception and must not be represented as functional support content.

27. **Product language and naming.** User-facing product name is `Island Notes`; internal modules and Swift identifiers may remain `IslandNotes`. All visible UI, errors, timestamps, accessibility text, and test-facing product strings are English for this release. Code may be organized for future localization, but no second localization is built or accepted.

28. **Design System as implementation contract.** Centralize the prototype's semantic color roles, SF font roles, 4/8/16/24/32 spacing scale, 14/22/34/pill corner radii, elevation/material/shadow roles, minimum 44-point targets, component states, and 160–210 ms motion. Green is reserved for a valid Live state. Do not scatter approximate literals across business views. These tokens and styles belong to UI implementation, not ViewModels or domain modules.

29. **Iconography.** App-owned icons use maintained Lucide vectors with the prototype's 2 px stroke character and consistent optical sizing. Do not substitute approximate SF Symbols. System-owned controls, keyboards, gestures, and ActivityKit hosting remain native.

30. **Allowed visual adaptation.** The prototype is normative for colors, hierarchy, component state, spacing rhythm, radii, typography roles, elevation, and motion. Native adaptation is allowed and required for safe areas, device width, Dynamic Type, VoiceOver, keyboard presentation, sheet behavior, and ActivityKit-hosted layout. Fidelity does not permit clipping essential content, fixed-height failure at accessibility sizes, or overriding system privacy behavior.

31. **Live-state truth.** Do not persist or trust a long-lived Live Boolean. A current note is Live only when ActivityKit enumeration reports exactly one valid active activity for it after reconciliation. Dynamic Island visibility is not a reliable state source. Errors and cleanup are transient outcomes, not additional product states.

32. **Live start.** `Go Live` validates actionable committed source, 240-character rules, and final 4 KB encoded payload, reconciles existing activities, blocks on unresolved inconsistencies, requests one new activity, re-enumerates, and only then exposes `Live`. Failure leaves the product non-Live with English retryable feedback.

33. **Live updates.** A successful `Done` commit during a valid session queues the latest committed note ID, source, and content version. `LiveActivitySession` uses a short cancellable debounce and updates the same activity. Update failure never rolls back SwiftData; it preserves actual session state and reports that system display may be out of sync. A future commit, foreground reconciliation, or explicit action may retry; there is no infinite timer loop.

34. **Live stop and end barrier.** `Live` requests end and re-enumerates before exposing `Go Live`. An end call that throws but has actually removed the activity counts as success after enumeration. An activity that remains active keeps the UI Live and produces retryable feedback. Pending updates are cancelled only after the relevant activity is confirmed absent.

35. **Reconciliation.** Run reconciliation after bootstrap, each foreground entry, and valid Live Activity deep links. Keep at most one active session belonging to the current note and attempt to end duplicates and orphans. If cleanup remains inconsistent, do not create a new activity and present recovery feedback. Expiration, user removal, disabled Live Activities, early system end, and restart all converge according to the latest ActivityKit enumeration without changing saved note content.

36. **Activity payload and lifetime.** Keep static attributes minimal and stable, including current-note identity; keep dynamic state minimal, including committed source and content version. Validate the combined final JSON representation against 4,096 bytes before start and update. Request an eight-hour stale date, accept that iOS may end earlier, and do not renew automatically. App-initiated end requests immediate removal intent, but ended Lock Screen content may remain under system control and does not mean the product is still Live.

37. **Live Activity presentations.** Compact leading contains only the monochrome brand note icon and intentionally provides no trailing dot, status, or text. Minimal contains only the same brand icon. Expanded renders committed source with list semantics and no editing, controls, or scrolling. Lock Screen uses the same source and semantics but its own native layout, line limits, wrapping, and truncation. All regions deep-link only to Workbench.

38. **Deep-link safety.** Accept only the Workbench destination. Ignore historical note identifiers and query values. A deep link dismisses any App-level sheet, returns to Workbench, preserves current-note identity, and triggers ActivityKit reconciliation. It never replaces a note, restores from the library, deletes content, or starts Live.

39. **Errors and feedback.** Retain required failure behavior even where the PNG omits it, using the prototype's Hints & Messages visual language. Messages are concise English, close to the triggering action, and announced by VoiceOver. Save failure keeps the draft; start/stop/update/reconcile follows system truth; move/replace/delete failure preserves committed data. Errors do not create permanent domain states or false success.

40. **Incremental migration sequence.** First extract `NoteWorkspace`, `LiveActivitySession`, and `AppRouter` behind the existing feature without changing user behavior. Then deliver vertical slices: centralized Design System and App shell; Workbench display/edit and explicit commit; Note Library; Settings and appearance; Live Activity presentations; delete and feedback. Each slice includes the minimal internal refactor needed for that slice, updates tests only for confirmed behavior changes, and restores a fully green suite before the next slice. Do not perform a wholesale rewrite or rename-only architecture pass.

41. **Old specification decisions explicitly replaced.** Replace the permanent editable text surface with display/edit states; replace per-keystroke SwiftData auto-save with `Done` commit; replace direct Library header navigation with More Menu and sheet routing; replace whole-row library exchange with an explicit row action; replace a native delete alert with the custom bottom dialog; add Settings and persistent display modes; replace system-following-only appearance with Automatic/Light/Dark; replace Chinese user-facing strings with English-only UI; replace approximate SF Symbols for App-owned icons with Lucide; add bullet rendering for `- ` list lines; make the new Design System normative; and use the updated Compact/Minimal icon-only presentations.

42. **Previous behavior still valid.** Preserve one current note; local-only SwiftData truth; stable existing records; verbatim source; 240 extended-grapheme capacity; IME-safe limiting; nonblank action eligibility; atomic move/replace/delete; reverse library ordering; a maximum of one current-note Live Activity; 4 KB validation; no automatic Live for a new current note; update of the same activity after committed edits; end barrier; bootstrap/foreground/deep-link reconciliation; eight-hour maximum with possible early end and no auto-renewal; Lock Screen presentation; Workbench-only deep links; English retryable failure semantics in the new UI; Dynamic Type, VoiceOver, and Reduce Motion support; and real-device acceptance for ActivityKit behavior.

## Testing Decisions

1. **Primary seam.** Preserve one highest-level combination seam around public `IslandNotesFeature` user actions. Its harness composes an in-memory SwiftData `ModelContainer`, the existing fake implementation of `LiveActivityControlling`, isolated appearance preference storage, a real `AppRouter`, deterministic time where needed, and the production feature/modules. This seam was explicitly confirmed during product grilling and requires no further approval.

2. **Test observable outcomes.** Drive bootstrap, begin edit, stage input, `Done`, ring reveal, menu routing, move, replace, delete, Go Live, Live stop, foregrounding, and deep links through public actions. Assert visible feature/router/appearance state, committed SwiftData records, library ordering, and fake ActivityKit sessions. Do not assert private methods, internal call counts, exact file ownership, concrete helper types, or private SwiftUI view hierarchy.

3. **Preserve prior art.** Continue the established XCTest patterns for feature behavior, character limits, payload sizing, controller contracts, library mutations, Live lifecycle, reconciliation, deep links, presentations, project smoke checks, and UI automation. Keep the existing 46 Feature/contract tests running through extraction; rewrite only tests whose external contract is explicitly replaced, especially per-keystroke auto-save, Chinese copy, native delete alert, direct Library entry, row-tap exchange, and old Live presentation expectations.

4. **Focused deep-module tests.** Add direct tests where they provide sharper failure localization: `NoteWorkspace` for bootstrap repair and atomic persistence invariants; `LiveActivitySession` for debounce, end barriers, duplicate/orphan cleanup, and reconciliation; `AppearanceSettings` for default, persistence, and forced-mode behavior; `AppRouter` for one-sheet exclusivity and Workbench deep links. These tests supplement rather than replace the combination seam.

5. **Editing and persistence matrix.** Cover display-to-edit transition, exact source seeding, draft-only typing, `Done` success, save failure retaining draft, sheets/background preserving draft, process restart losing uncommitted draft while restoring committed source, replacement discarding draft, committed Live update, and existing-store upgrade. Verify that rendered content is never persisted as a second body.

6. **Text and rendering matrix.** Cover empty/whitespace, ASCII, Chinese, line breaks, punctuation, simple Emoji, multi-scalar composed Emoji, 239/240/241 characters, over-limit paste, active marked text, source list lines, mixed list and ordinary lines, unsupported Markdown-like syntax, and character ring values in display/edit states. Verify identical list semantics in Workbench, Expanded, and Lock Screen presentation models without requiring identical layout.

7. **Library and transaction matrix.** Cover empty library, descending entry time, deterministic ties, timestamp categories, move, successful replacement with nonblank outgoing current, replacement with blank outgoing current, row no-op, draft discard, successful sheet dismissal, failed sheet retention, delete cancel/confirm/failure, and every Live end-barrier result. Assert atomic persisted outcomes and no blank library entries.

8. **Live Activity matrix.** Cover start success/failure, post-request verification, 4 KB start/update failures, update debounce and latest committed value, stop success, end-then-throw, keep-then-throw, expired/user-removed activities, wrong-note orphans, duplicates, cleanup failure, foreground/bootstrap/deep-link reconciliation, no auto-start after current-note changes, and repeated manual Go Live after an ended session.

9. **Appearance and routing matrix.** Cover Automatic reacting to system changes, forced Light over system Dark, forced Dark over system Light, restart persistence, App-only scope, More Menu dismissal, Note Library/Settings one-sheet exclusivity, close behavior, draft preservation, and deep-link return to Workbench without note replacement.

10. **Component and visual verification.** Maintain representative SwiftUI previews for every key Workbench display/edit/empty/limit/Live/error/delete state; Library empty/populated/replacement state; Settings and all appearance choices; More Menu; custom dialog; Light and Dark variants; default and maximum Dynamic Type; Reduce Motion; Compact, Minimal, Expanded, and Lock Screen. Compare key states against the high-fidelity PNG and centralized Design System tokens.

11. **UI automation.** Run complete primary flows on an iPhone 16 Pro current iOS 26.x simulator: first launch, edit/Done, ring, More Menu, Library move/replace, Settings modes, delete, Go Live/Live when simulator support permits, deep link, errors exposed through deterministic launch/test seams, accessibility labels, 44-point targets, maximum Dynamic Type, and Reduce Motion. UI tests may use stable accessibility identifiers but must assert user-visible behavior rather than private hierarchy.

12. **Minimum OS validation.** Build and launch on a Dynamic Island simulator running the minimum supported iOS 17.x version and execute the core Workbench, persistence, Library, Settings, and deep-link flow. Current-iOS-only visual behavior must degrade within the confirmed native adaptation rules rather than changing product semantics.

13. **Accessibility acceptance.** Manually verify the complete core flow with VoiceOver, including focus order, current note state, character value, replace action, display-mode selection, Live status, delete dialog, and timely error announcements. Verify default and maximum Accessibility Dynamic Type, non-color status cues, 44-point targets, and Reduce Motion behavior. The confirmed no-op support rows intentionally have no “not available” hint.

14. **Real-device ActivityKit acceptance.** Before release, use at least one current iOS 26.x Dynamic Island iPhone to verify Live start/update/stop/restart, Compact, Minimal, Expanded, Lock Screen, bullet rendering, independent truncation, all deep links, disabled Live Activities, user removal, background, force termination, device reboot, reconciliation, eight-hour lifecycle, possible Lock Screen residual content, representative 240-character payloads, 4 KB failure, VoiceOver, maximum Dynamic Type, Reduce Motion, Light/Dark, and privacy behavior. Use a second Dynamic Island width when available; otherwise record simulator-only evidence explicitly.

15. **Incremental green rule.** Each extraction or vertical slice begins from the currently passing suite, changes the smallest necessary external expectations, adds coverage for its new behavior, and ends with all applicable Feature, contract, UI, build, and visual checks green. A slice is not complete merely because new module tests pass while the highest-level behavior suite is broken.

## Out of Scope

- Full Markdown, headings, task items, rich text, or formatting beyond rendering source lines beginning with `- ` as round bullets.
- Note Library preview modes, whole-row replacement, editing or deleting library entries, search, tags, folders, favorites, manual ordering, or bulk management.
- Functional Feedback, Website, About, or Privacy destinations; the first three remain confirmed no-action rows and Privacy remains absent.
- Chinese localization, a language switch, or acceptance of a second language.
- Appearance customization beyond Automatic, Light, and Dark; no custom colors, fonts, paper styles, or type-size setting.
- Accounts, backend services, networking, iCloud, collaboration, or cross-device synchronization.
- Notifications, reminders, countdowns, scheduled Go Live, automatic Live renewal, or permanent display intent.
- A standalone home/lock-screen Widget product, share extension, Shortcuts, App Intents, or other system integrations beyond the existing Live Activity extension.
- Editing, controls, buttons, or scrolling inside Dynamic Island or Lock Screen presentations.
- A non-Dynamic-Island iPhone alternative product experience.
- A SwiftData repository protocol without a real second adapter, full classic MVVM, a Workbench page ViewModel, or shallow ViewModels for buttons, rows, settings, and visual components.
- App Store marketing assets, release copy, distribution, or store submission workflow.
- Ticket decomposition; this specification is published as one `ready-for-agent` item and will be planned separately.

## Further Notes

1. **Source priority.** Confirmed redesign decisions and ADRs govern explicit conflicts; the latest high-fidelity PNG governs product scope, states, interaction intent, and visual implementation by default; current code/tests provide compatibility evidence; unaffected previous behavior remains valid. Deleted prototypes and old plans cannot fill gaps or override this specification.

2. **System behavior versus code guarantee.** The app can guarantee its request parameters, payload validation, persisted data, reconciliation algorithm, and UI response to enumerated ActivityKit state. It cannot guarantee when iOS shows a Live Activity, whether the user permits it, which Dynamic Island presentation iOS selects, exact visible character count, exact wrapping/truncation, Always-On behavior, privacy redaction, continued execution after background/force termination, persistence across reboot, exact early-end timing, or Lock Screen residual duration. These are real-device observations and must be recorded as evidence, not asserted as deterministic unit-test contracts.

3. **Normative versus adaptive visuals.** Semantic colors, typography roles, spacing rhythm, radii, elevation, motion, icon family, component hierarchy, control states, and Light/Dark compositions are mandatory. Safe-area insets, sheet mechanics, keyboard avoidance, Dynamic Type reflow, VoiceOver grouping, device width, and ActivityKit-hosted line layout may adapt natively. Adaptation must preserve every essential action and semantic state.

4. **Compatibility boundary.** The redesign intentionally changes visible copy, navigation, editing commit behavior, list rendering, delete presentation, settings, iconography, and Live presentation. It does not authorize resetting data, weakening persistence atomicity, adding a second content truth, replacing ActivityKit enumeration with a Boolean, removing the end barrier, or abandoning the established feature-level test seam.

5. **Ready state.** Product scope, interaction behavior, architecture direction, test seams, exclusions, and acceptance environments have been explicitly confirmed. There are no open product decisions blocking implementation planning. Exact English error phrasing may be polished within the confirmed error categories and Hints & Messages design language without introducing new behavior.
