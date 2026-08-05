# 灵动岛便签原生 App Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 构建 iOS 17+ 原生 iPhone MVP：唯一当前便签槽位自动保存最多 240 个用户感知字符，并可把同一便签作为一次最长 8 小时、可能提前结束的 Live Activity 会话投影到灵动岛和锁屏。

**Architecture:** SwiftData 保存长期便签事实；一个 `@MainActor @Observable` 的 `IslandNotesFeature` 组合层协调公开用户动作、持久化、错误反馈与 ActivityKit，并作为最高优先级自动化测试 seam。ActivityKit 实际枚举是挂起真相；App 与 Widget Extension 编译同一最小 Codable 契约，Widget 只渲染 Content State，不访问 SwiftData。

**Tech Stack:** Swift 6、SwiftUI、Observation、SwiftData、ActivityKit、WidgetKit、XCTest、XCUITest、Xcode 26.3；最低部署目标 iOS 17.0。

---

## 1. 权威来源与执行纪律

- 唯一产品与验收事实来源：`docs/product/mvp-spec.md`。
- ActivityKit 边界核对：`docs/research/activitykit-system-constraints.md`。
- 视觉只读基线：`docs/prototypes/web-prototype/`；绝不修改该目录。
- 不执行或修改 `docs/plans/archive/2026-07-30-*` 旧计划。
- 不加入标题、列表项、完成状态、多当前便签、新建便签按钮、永久挂起布尔值、账号、网络、后端或 iCloud。
- 每个用户可观察行为严格执行 RED → 观察预期失败 → GREEN → 观察通过 → REFACTOR → 相关回归。
- 用户明确要求不 commit、push 或创建 PR，因此本计划不含提交步骤；每批用 `git status --short` 审计范围。
- 规格已经批准；本计划保存后直接执行，不再次请求产品批准。

## 2. 当前仓库与工具链基线（2026-08-04 检查，2026-08-05 复核）

- 工作目录：`<repository-root>`；分支 `main`。
- 所有既有规格、原型、审计图片和资料均为未跟踪用户文件，必须保护。
- 当前不存在 `.xcodeproj`、Swift 生产源码、测试 Target 或 Widget Extension。
- Xcode 26.3（17C529），Swift 6.2.4，iOS/iOS Simulator SDK 26.2。
- 可用带灵动岛模拟器：`iPhone 16 Pro 26`，iOS 26.2，UDID `EDD74643-CA6F-4ABB-B151-06F1B03A5769`，检查时 Shutdown。
- 本机没有 `xcodegen`、`tuist` 或 Ruby `xcodeproj`。为避免修改全局环境，直接维护最小 `IslandNotes/IslandNotes.xcodeproj/project.pbxproj` 与 shared schemes。

复查命令：

```bash
cd "$(git rev-parse --show-toplevel)"
git status --short --branch
rg --files
find . -maxdepth 4 \( -name '*.xcodeproj' -o -name '*.xcworkspace' -o -name '*.swift' \) -print
xcodebuild -version
xcodebuild -showsdks
swift --version
xcrun simctl list devices available
```

## 3. 目标工程与职责

```text
IslandNotes/
  IslandNotes.xcodeproj/
  Configuration/
    IslandNotes-Info.plist
    IslandNotesWidget-Info.plist
  Sources/
    IslandNotes/
      IslandNotesApp.swift
      Domain/{NoteRecord,WorkbenchRecord,ActivitySession}.swift
      Features/{IslandNotesFeature,TextLimiter}.swift
      LiveActivity/{LiveActivityControlling,ActivityKitLiveActivityController}.swift
      UI/{AppRootView,WorkbenchView,CharacterProgressView,ActionDock,NoteLibraryView,PreviewFixtures}.swift
    IslandNotesShared/
      {IslandNoteActivityAttributes,ActivityPayloadSizer,LiveActivityPresentationModel}.swift
    IslandNotesWidget/
      IslandNotesWidgetBundle.swift
  Tests/
    IslandNotesFeatureTests/
      TestSupport/{InMemoryFeatureHarness,FakeLiveActivityController}.swift
      {ProjectSmokeTests,IslandNotesFeatureTests,CharacterLimitTests,LibraryMutationTests,LiveActivityLifecycleTests,ReconciliationTests,ActivityPayloadTests}.swift
    IslandNotesUITests/
      {IslandNotesUITests,DeepLinkUITests}.swift
docs/verification/real-device-live-activity-checklist.md
```

职责边界：

- SwiftUI 只表达公开状态和动作，不直接调用 ActivityKit。
- SwiftData 保存稳定便签 ID、原样正文、创建/修改/最近入库时间与唯一当前便签指针；不保存长期挂起状态。
- `IslandNotesFeature` 持有 `ModelContext` 和可替换 `LiveActivityControlling`，维护事务与不变量。
- 生产 controller 是 ActivityKit 唯一适配边界；测试整体替换它。
- Widget Extension 只读共享 attributes/state，分别渲染 compact leading/trailing、minimal、expanded、Lock Screen。

建议模型：

```swift
@Model final class NoteRecord {
    @Attribute(.unique) var id: UUID
    var body: String
    var createdAt: Date
    var modifiedAt: Date
    var archivedAt: Date?
}

@Model final class WorkbenchRecord {
    @Attribute(.unique) var singletonKey: String // 固定 primary
    var currentNoteID: UUID
}
```

必须始终满足：

1. 恰好一个有效 current 指针；current 不在库中，库按 `archivedAt` 降序并稳定排序。
2. 空白判断只控制操作可用性，不 trim 或改写原文。
3. 同时至多一个本 App 活跃 Activity，且它必须属于 current。
4. ActivityKit 实际活动是挂起真相；没有长期 `isPinned`/`isLive`。
5. 挂起中入库、确认删除或交换必须先结束并重读活动；仍活跃则内容事务完全不发生。
6. 240 按 Swift `Character`；request/update 还要对最终 attributes + state JSON 合计执行 ≤4096 bytes 检查。

## 4. 通用精确命令

```bash
cd "$(git rev-parse --show-toplevel)"
SIM_UDID='EDD74643-CA6F-4ABB-B151-06F1B03A5769'
DESTINATION="platform=iOS Simulator,id=$SIM_UDID"
```

单测试模板：

```bash
xcodebuild test -project IslandNotes/IslandNotes.xcodeproj -scheme IslandNotes \
  -destination "$DESTINATION" \
  -only-testing:IslandNotesFeatureTests/<Suite>/<testName> \
  CODE_SIGNING_ALLOWED=NO
```

完整功能测试：

```bash
xcodebuild test -project IslandNotes/IslandNotes.xcodeproj -scheme IslandNotes \
  -destination "$DESTINATION" \
  -only-testing:IslandNotesFeatureTests CODE_SIGNING_ALLOWED=NO
```

## 5. TDD 任务

### Task 1：最小正式工程与四个 Targets

**目标行为：** `IslandNotes` App、`IslandNotesWidget` Extension、`IslandNotesFeatureTests`、`IslandNotesUITests` 均可被 Xcode 发现；iOS 17.0；App 嵌入 Widget。

**文件：** 新建 `IslandNotes/IslandNotes.xcodeproj/project.pbxproj`、两个 shared scheme、最小 App/Widget 入口、Info.plist、`ProjectSmokeTests.swift`、UI smoke 文件。

**先写失败测试：** 最小 smoke 测试引用 App 模块；首次命令应因工程/模块不存在失败。

**RED 命令：** `xcodebuild test -project IslandNotes/IslandNotes.xcodeproj -scheme IslandNotes -destination "$DESTINATION" -only-testing:IslandNotesFeatureTests/ProjectSmokeTests CODE_SIGNING_ALLOWED=NO`

**GREEN：** 只建立可编译测试宿主与空 App/Widget；Info.plist 声明 `NSSupportsLiveActivities=YES` 和 `islandnotes` URL scheme；不加入业务行为。

**重构边界：** 无第三方依赖、无全局工具安装、无产品逻辑。

**完整验证：** `xcodebuild -list -project IslandNotes/IslandNotes.xcodeproj`；App `build-for-testing`；Widget scheme generic simulator build。

**规格：** Solution；Implementation Decisions 2–3；US 87–89。

### Task 2：共享 Activity Codable 契约与 4 KB 防线

**文件：** 新建 `IslandNotes/Sources/IslandNotesShared/IslandNoteActivityAttributes.swift`、`ActivityPayloadSizer.swift`、`IslandNotes/Tests/IslandNotesFeatureTests/ActivityPayloadTests.swift`；把共享 attributes 加入 App 与 Widget target。

**RED：** 测试 attributes 的稳定 `noteID`、state 的原样 `body/version`、生产同源 JSON 往返和合计 byte count；覆盖 240 ASCII、中文、简单 Emoji、复杂 ZWJ/肤色/组合音标与超 4 KB。

**RED 命令：** 单独运行 `ActivityPayloadTests`，期望因类型缺失编译失败。

**GREEN：** `IslandNoteActivityAttributes: ActivityAttributes`，`ContentState: Codable, Hashable`；`ActivityPayloadSizer` 用固定 `JSONEncoder` 计算 attributes 与 state 两份最终 Data 之和并在 >4096 时抛错。

**重构边界：** 不引入 APNs、stale 长期状态或 Widget SwiftData。

**完整验证：** `ActivityPayloadTests` + Widget build。

**规格：** US 92–93；Implementation Decisions 8；Testing Decisions 10。

### Task 3：内存 SwiftData、可替换 controller 与主要组合 seam

**文件：** 新建 Domain 三文件、`LiveActivityControlling.swift`、`IslandNotesFeature.swift`、内存 harness、fake controller、`IslandNotesFeatureTests.swift`。

**RED：** 公开 API `bootstrap()` 后可观察一个空白 current、空 library、未挂起、三动作 disabled、库入口可用；断言 SwiftData 恰好一个 current。

**RED 命令：** 运行 `IslandNotes/Tests/IslandNotesFeatureTests/testFirstLaunchCreatesOneBlankCurrentNote`，期望 API/类型缺失。

**GREEN：** `ModelConfiguration(isStoredInMemoryOnly:true)`；一个 `@MainActor @Observable IslandNotesFeature`；fake 保存其代表的实际活动集合和可配置错误。测试不检查私有方法或调用次数。

**重构边界：** 不把每个小类型拆成独立 seam；功能组合层保持最高级测试入口。

**完整验证：** `ProjectSmokeTests` + `IslandNotesFeatureTests`。

**规格：** Testing Decisions 1–2；US 1–2、73–80。

### Task 4：首次启动、唯一 current 与重启恢复

**文件：** 修改 `IslandNotesFeature.swift`、两个 SwiftData model、`IslandNotesFeatureTests.swift`。

**RED：** 空容器只创建一次；重复 bootstrap 仍唯一；同一容器重建 feature 恢复相同 ID/body；损坏指针安全补位且不覆盖非空内容。

**RED 命令：** 逐个运行 `testBootstrapIsIdempotent`、`testRecreatedFeatureRestoresCurrentNote`。

**GREEN：** 查询 singleton 和 Note；缺失时一次 save 创建空 Note + current 指针；有效记录不重复创建。

**重构边界：** 修复只补指针/空白槽位，不静默删除有内容记录。

**完整验证：** 完整 `IslandNotesFeatureTests`。

**规格：** US 1–6、73–76、80–81。

### Task 5：纯文字编辑、即时自动保存与原样往返

**文件：** 新建 `TextLimiter.swift`；修改 feature；新增编辑 round-trip tests。

**RED：** 中文、英文、数字、标点、连续空格、空行、`-`/`*`/数字开头、简单/组合 Emoji 与 Return 换行，经 `editCurrentNote` 后 observable、SwiftData、重建 feature 三者完全相同。

**RED 命令：** 运行 `testEditingAutoSavesVerbatimText`。

**GREEN：** 可接受最终值立即更新 UI 并 `context.save()`；保存失败保留编辑会话文字、显示“内容尚未保存”，不以旧快照覆盖，也不更新 Activity。

**重构边界：** 无 parser、标题、保存、完成或提交命令。

**完整验证：** 编辑 suite + 重启 suite。

**规格：** US 3–11、20–21；Testing Decisions 3。

### Task 6：239/240/241、粘贴、marked text 与字符进度

**文件：** 修改 `TextLimiter.swift`、feature；新建 `CharacterLimitTests.swift`。

**RED：** 239 接受第 240；241 拒绝且保持 240；超限粘贴只取完整 `Character`；满额仍可删除/等长/缩短替换；marked text 提交后才限；圆环默认无数字，公开点击后返回 used/remaining；VoiceOver value 正确。

**RED 命令：** 运行 `CharacterLimitTests`，确认边界断言失败。

**GREEN：** 按 Swift Character 接受 proposed 最终值的 prefix(240)，返回 accepted/truncated/limitReached；marked text 活跃时不拆中间组合值。

**重构边界：** 240 只限制输入，不被当作 4 KB 或系统完整显示保证。

**完整验证：** `CharacterLimitTests` + `ActivityPayloadTests`。

**规格：** US 9、12–21；Testing Decisions 4。

### Task 7：Unicode 空白、入库与倒序 library

**文件：** 新建 `LibraryMutationTests.swift`；修改 feature。

**RED：** 空/全 Unicode whitespace 保留原文但禁用挂起/入库/删除、库入口仍可用；有效 current 入库后旧内容在库顶，新空白 current 未挂起；多次入库倒序，同时间稳定排序。

**RED 命令：** 运行 `LibraryMutationTests/testArchivingReplacesCurrentWithBlankAndOrdersLibraryNewestFirst`。

**GREEN：** `hasActionableContent` 只判定非 whitespace；入库在同一保存边界更新 archivedAt、创建空 Note、更新 current 指针；失败 rollback 并提示“放入便签库未完成”。

**重构边界：** 库无搜索、标签、手动排序或详情页。

**完整验证：** library suite + feature suite。

**规格：** US 22–26、37–43、50。

### Task 8：点击交换与空白补位

**文件：** 修改 `LibraryMutationTests.swift`、feature。

**RED：** 点击旧便签立即交换；非空 current 入库顶；空白 current 不产生库记录；选中 Note 离库并成为 current；新 current 未挂起；失效 ID 无副作用；库 API 不暴露编辑/挂起/删除旧便签。

**RED 命令：** 运行 `testSelectingLibraryNoteAtomicallySwapsWithCurrentNote` 与空白变体。

**GREEN：** 一次保存边界执行交换；失败 rollback 并保持三方状态不变。

**重构边界：** 无预览页、恢复按钮或确认。

**完整验证：** 完整 `LibraryMutationTests`。

**规格：** US 40–50。

### Task 9：删除确认与空白 current

**文件：** 修改 library tests、feature。

**RED：** `requestDelete` 只显示“删除后无法恢复”；取消零副作用；确认后删除旧 current、补入空白、未挂起；空白 delete disabled。

**RED 命令：** 运行 `testDeleteRequiresConfirmationAndCancelHasNoSideEffects`、`testConfirmedDeleteCreatesBlankCurrentNote`。

**GREEN：** enum 驱动确认；只有 confirm 进入事务；失败 rollback 并提示“删除未完成”。

**重构边界：** 无回收站或历史版本。

**完整验证：** library suite。

**规格：** US 24、51–54。

### Task 10：挂起、重复挂起、取消与错误

**文件：** 新建 `LiveActivityLifecycleTests.swift`；修改 feature 与 activity session。

**RED：** 有效 current 启动后 fake 仅一条 current 活动且 UI“挂起中”；空白不能启动；request 失败保持未挂起/内容不变并提示；重复挂起不改变活动；取消后重枚举，只有实际结束才显示未挂起；end 抛错但已结束可成功；仍活跃则提示“取消挂起尚未完成”。

**RED 命令：** 逐个运行 start/failure/repeat/cancel tests。

**GREEN：** request 前校验非空、240、4 KB、对账；request/end 后都重新 `activities()`；无持久布尔、无自动续挂或“已到期”。

**重构边界：** fake 只控制系统结果，断言落在用户状态/数据/实际 fake 活动集合。

**完整验证：** lifecycle + payload suites。

**规格：** US 27–32、68–72；Testing Decisions 6。

### Task 11：入库、删除、交换的结束屏障

**文件：** 修改 lifecycle/library tests 与 feature。

**RED：** 三动作各覆盖：结束成功才继续；end 抛错但重读已结束可继续；重读仍活跃则 current/body/library/pointer 全不变；结束成功但 SwiftData save 失败时活动已结束、内容槽位原样、UI 未挂起并提示操作未完成。

**RED 命令：** 运行 `testActiveSessionMustActuallyEndBeforeArchiveDeleteOrSwap` 及三个动作变体。

**GREEN：** 共享内部结束屏障：end → 重枚举 → 确认 target 不活跃 → 才执行内容事务。

**重构边界：** 不通过测试私有 barrier 或内部调用次数。

**完整验证：** lifecycle + library suites。

**规格：** US 39、47、54–56；Implementation Decisions 11。

### Task 12：挂起中编辑同步、防抖与失败恢复

**文件：** 修改 lifecycle tests 与 feature。

**RED：** 编辑后 SwiftData 先出现最新值；公开 `flushPendingActivityUpdate()` 后同一活动出现最终 body/version；连续输入提交最终值；update/4 KB 失败仍保留本地内容、保持系统实际挂起状态并提示“系统展示可能尚未同步”；下一公开动作可重试但无无限自动循环。

**RED 命令：** 运行 `testPinnedEditingSavesBeforeUpdatingSameActivity` 和 failure variants。

**GREEN：** 保存成功后取消旧 debounce task，排队最新已保存快照；测试用公开 flush 驱动而不依赖 wall-clock；错误后仅在下一编辑/前台/用户动作重试。

**重构边界：** 不承诺后台或强杀后 debounce 继续，不加 BackgroundTasks/APNs。

**完整验证：** lifecycle + persistence suites。

**规格：** US 33–36、79–80；Testing Decisions 7。

### Task 13：启动/前台对账、孤立与多个活动

**文件：** 新建 `ReconciliationTests.swift`；修改 feature。

**RED：** current 唯一活动→挂起；无活动→未挂起；孤立活动安全结束且 current 不交换；清理失败不虚报且禁新挂起；多个活动最终至多保留一个 current 活动；清理前禁 request；重复 reconcile 幂等；失效 deep link 仅工作台+对账。

**RED 命令：** 运行完整 `ReconciliationTests`。

**GREEN：** 先读 current，再枚举；确定性保留一个 current 活动，结束其余并重枚举；不一致只是短期反馈，不持久化第三状态。

**重构边界：** 不把“岛上可见性”当活动真相。

**完整验证：** reconciliation + lifecycle + feature suites。

**规格：** US 67、73–80；Testing Decisions 8。

### Task 14：正式 SwiftUI 工作台、进度与三动作

**文件：** 新建 AppRoot、Workbench、CharacterProgress、ActionDock、TransientFeedback、PreviewFixtures；修改 App 入口；修改 UI tests。

**RED：** UI test 首次启动找到可编辑 `current-note-editor`、始终可达 `open-library`、空白三动作 disabled；输入后自动保存且 enabled；删除确认文案准确。

**RED 命令：** `xcodebuild test ... -only-testing:IslandNotesUITests/IslandNotesUITests CODE_SIGNING_ALLOWED=NO`，期望 identifier 缺失。

**GREEN：** 单根 NavigationStack；大面积圆角 TextEditor 纸张、右下字符圆环、底部“放入便签库/挂起或取消挂起/删除”；系统字体/颜色/SF Symbols/安全区；弱绿同时配文字图标；≥44pt；Dynamic Type 时纵向重排；Reduce Motion 移除呼吸动画；完整 accessibility label/value/hint/disabled reason。

**重构边界：** 无查看态、DONE、虚拟键盘、更多设置或用户主题。

**完整验证：** App build + 稳定 UI tests + Preview 编译。

**规格：** US 1–28、82–86；Implementation Decisions 6–7。

### Task 15：便签库页面与删除确认 UI

**文件：** 新建 `NoteLibraryView.swift`；修改 Workbench/UI tests。

**RED：** 空白仍可进入库；空状态；多条倒序两行原样摘要；点击整行立即交换并回工作台；库行无编辑/挂起/删除；取消删除无副作用。

**RED 命令：** 运行 UI test 的 library/delete cases。

**GREEN：** 只读单列原生 List/ScrollView；行显示原文语义摘要与低强调入库时间；整行调用公开交换；item/enum 驱动原生确认。

**重构边界：** 不出现直接旧便签动作或预览详情。

**完整验证：** UI tests + feature tests。

**规格：** US 40–53、82–86。

### Task 16：ActivityKit 生产 controller

**文件：** 新建 `ActivityKitLiveActivityController.swift`；修改 App 入口/Info.plist。

**RED：** 编译型测试要求生产 controller 符合协议；核心功能仍注入 fake，不用 fake 冒充平台证明。

**RED 命令：** 运行 controller contract test，期望类型缺失。

**GREEN：** `Activity<Attributes>.activities` 映射 snapshot；iOS 17 `request(attributes:content:pushType:nil)`；同 activity ID update；`end(...dismissalPolicy:.immediate)`；错误上抛；scenePhase active 调 reconcile。

**重构边界：** 不使用 Xcode 26 新增但 iOS 17 不可用的 schedule/transient API。

**完整验证：** App generic simulator build + 功能测试。

**规格：** US 27–36、55–56、68–80。

### Task 17：Widget 四种 presentation 与统一 deep link

**文件：** 新建 Widget bundle、Live Activity widget/views、presentation contract tests。

**RED：** compact/minimal 的可测展示模型不含 body；expanded/Lock Screen 读取同一 state body；所有入口 URL 为 `islandnotes://workbench`；失效 noteID 不进入内容事务。

**RED 命令：** 运行 presentation contract tests；Widget build 预期因实现缺失失败。

**GREEN：** compact leading/trailing 共同显示单色便签标记+弱绿状态，不显示正文；minimal 只标记；expanded/Lock Screen 原生 Text 分别限行截断、不滚动、无按钮；统一 `widgetURL`。

**重构边界：** Widget 不读 SwiftData、不联网、不保证全文或逐行一致。

**完整验证：** Widget scheme build；compact/minimal/expanded/Lock Screen 短/长/换行/Emoji previews 编译。

**规格：** US 57–67；Implementation Decisions 13–14。

### Task 18：deep link、外观/无障碍收口与平台验证

**文件：** 新建 `DeepLinkUITests.swift`、真机验收清单；修改 App routing、previews、views/UI tests。

**RED：** 冷/热 `islandnotes://workbench?noteID=expired` 只打开 current 工作台并对账；不恢复/交换/挂起；最大 Dynamic Type 关键动作可达；VoiceOver 信息完整；Reduce Motion 不依赖动画。

**RED 命令：** 运行 deep link 与 accessibility UI tests。

**GREEN：** onOpenURL 只收敛到 workbench 并 reconcile，忽略历史 ID 的内容选择含义；补齐浅/深色、最大字号、Reduce Motion 与规格 Preview 矩阵。

**重构边界：** 不用私有 SwiftUI 层级或像素颜色作为业务断言。

**完整验证：** 下节全部命令与模拟器实际启动/截图。

**规格：** US 66–67、82–93。

## 6. User Story 可追溯矩阵

| User Stories | Tasks | 主要证据 |
|---|---|---|
| 1–6 | 3–5、14 | bootstrap、editor、autosave、UI smoke |
| 7–11 | 5 | 原样 round-trip、Return/Markdown 不解析 |
| 12–21 | 6、14 | CharacterLimitTests、进度/VoiceOver |
| 22–26 | 3、7、14 | Unicode whitespace、disabled 状态 |
| 27–32 | 10、16 | start/repeat/failure/实际枚举 |
| 33–36 | 12 | save-before-update、debounce、failure/retry |
| 37–39 | 7、11 | archive、blank replacement、end barrier |
| 40–50 | 7–8、15 | library order、swap、read-only UI |
| 51–56 | 9、11、15 | confirmation、delete、end barrier |
| 57–65 | 17 | 四种 presentation previews + 真机 |
| 66–67 | 17–18 | unified deep link、expired fallback |
| 68–72 | 10、13、16 | session lifecycle、no auto renewal |
| 73–80 | 4、12–13、16、18 | restart/foreground/orphan/multiple/data safety |
| 81 | 1–18 | 无网络/账号/iCloud 依赖审计 |
| 82–86 | 14–15、18 | appearance、Dynamic Type、VO、Reduce Motion |
| 87–91 | 17–18 | Preview、Simulator、真机清单 |
| 92–93 | 2、10、12、18 | payload tests、4 KB failures、真机样本 |

## 7. Preview、Simulator 与真机分层验证

Preview 至少覆盖：首次空白、有效短文、中英换行 Emoji、239/240、超限、挂起、未同步、空/多条库、删除确认、浅/深色、最大 Dynamic Type、Reduce Motion、compact、minimal、expanded、Lock Screen 短/长文本。

Simulator 使用 `iPhone 16 Pro 26`：

```bash
xcrun simctl boot EDD74643-CA6F-4ABB-B151-06F1B03A5769 || true
open -a Simulator
xcrun simctl bootstatus EDD74643-CA6F-4ABB-B151-06F1B03A5769 -b
xcodebuild clean build -project IslandNotes/IslandNotes.xcodeproj -scheme IslandNotes \
  -destination "$DESTINATION" CODE_SIGNING_ALLOWED=NO
xcodebuild clean build -project IslandNotes/IslandNotes.xcodeproj -scheme IslandNotesWidget \
  -destination "$DESTINATION" CODE_SIGNING_ALLOWED=NO
xcodebuild test -project IslandNotes/IslandNotes.xcodeproj -scheme IslandNotes \
  -destination "$DESTINATION" CODE_SIGNING_ALLOWED=NO
```

安装并启动 App，验证工作台、库、deep link 冷/热启动、浅/深色、基础 Dynamic Type 与可行的 request/update/end。优先用 XcodeBuildMCP 描述 UI/截图；不可用时明确记录 `simctl install/launch/io screenshot` fallback。模拟器结果不冒充真机。

真机未连接时保留为未执行：实际 compact/minimal/expanded、Lock Screen、首次系统 UI、禁用/重开 Live Activities、后台/终止/崩溃/强杀、设备重启、完整 8 小时与最多 4 小时锁屏尾部、手动移除、多 App activities、Always-On、锁屏访问与 redaction、371/408pt 宽度、最大 Dynamic Type、240 中文/ASCII/简单 Emoji/复杂字素的真实 request/update 与显示。

## 8. 最终验证门槛

每完成一个任务，先运行该任务最小测试和相关 suite；每三个任务运行完整功能测试与 `git status --short`。最终新鲜运行并读取完整结果：

```bash
xcodebuild -list -project IslandNotes/IslandNotes.xcodeproj
xcodebuild clean build -project IslandNotes/IslandNotes.xcodeproj -scheme IslandNotes \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
xcodebuild clean build -project IslandNotes/IslandNotes.xcodeproj -scheme IslandNotesWidget \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
xcodebuild test -project IslandNotes/IslandNotes.xcodeproj -scheme IslandNotes \
  -destination "$DESTINATION" -only-testing:IslandNotesFeatureTests CODE_SIGNING_ALLOWED=NO
xcodebuild test -project IslandNotes/IslandNotes.xcodeproj -scheme IslandNotes \
  -destination "$DESTINATION" -only-testing:IslandNotesUITests CODE_SIGNING_ALLOWED=NO
xcrun simctl launch "$SIM_UDID" com.steve.IslandNotes
xcrun simctl io "$SIM_UDID" screenshot /tmp/island-notes-final.png
git status --short
```

自动化替身通过只能证明组合 seam；真实 ActivityKit、Widget presentation、权限、生命周期与隐私必须按真机清单记录后，才能声称发布级 MVP 完全符合规格。
