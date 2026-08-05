# “灵动岛便签”MVP 实施计划

- 日期：2026-07-30
- 依据：`docs/plans/2026-07-30-dynamic-island-note-design.md`
- 当前工具链：Xcode 26.3，Swift 6.2.4
- 真机验收：iPhone 16 Pro，iOS 26.5.2

## 目标

从空目录构建一个可在真机安装的原生 iPhone App：本机维护多张列表型便签，App 始终打开当前便签工作台，用户可手动将一张便签以只读 Live Activity 显示在灵动岛，并在 App 编辑后即时同步。

## 实施约束

- 不读取或复用 `原始资料/`。
- 内部工程名暂用 `DynamicIslandNotes`，显示名暂用“灵动岛便签”。
- 正式产品名和 Logo 不在本计划内，占位图标必须易于替换。
- App 使用 SwiftUI、SwiftData、ActivityKit 和 WidgetKit。
- 最低部署目标暂定 iOS 17.0，以覆盖 SwiftData 并保留较广的 Dynamic Island 设备范围；MVP 只承诺在指定 iOS 26.5.2 真机验收。
- 不加入云同步、通知、倒计时、归档、历史或灵动岛交互控件。
- 每个阶段先完成对应自动化验证，再进入下一阶段。

## 阶段 0：确认 Xcode 与真机链路

### 操作

1. 运行 `xcodebuild -showsdks`，确认 iOS SDK 可用。
2. 运行 `xcrun simctl list devices available`，选择可用的 Dynamic Island 模拟器。
3. 连接 iPhone 16 Pro，确认 Xcode 能识别 iOS 26.5.2、开发者模式已开启、签名 Team 可用。
4. 如果 Xcode 26.3 无法支持该设备系统版本，先升级兼容的 Xcode，再创建工程，避免在最后验收阶段返工。

### 完成标准

- 模拟器构建链路可用。
- Xcode 能识别目标真机并准备签名；若暂未连接，明确记录唯一待完成的真机步骤。

## 阶段 1：创建工程与目标

### 预计文件

- `DynamicIslandNotes.xcodeproj/`
- `DynamicIslandNotes/App/DynamicIslandNotesApp.swift`
- `DynamicIslandNotes/App/AppRootView.swift`
- `DynamicIslandNotes/Resources/Assets.xcassets/`
- `DynamicIslandNotesLiveActivity/NoteLiveActivityWidgetBundle.swift`
- `DynamicIslandNotesTests/`
- `DynamicIslandNotesUITests/`

### 操作

1. 创建 SwiftUI iOS App target：`DynamicIslandNotes`。
2. 添加 Widget Extension，并启用 Live Activity；不添加普通桌面 Widget 配置。
3. 添加 Unit Test 与 UI Test targets。
4. App 和扩展使用一致的 bundle identifier 前缀；签名 Team 在真机阶段配置。
5. App 的 `Info.plist` 启用 Live Activities。
6. 注册内部 deep link scheme，例如 `dynamicislandnotes://note/<id>`。
7. 创建共享 scheme，确保 App、Extension 和 Tests 都能在命令行构建。

### 验证

- App target 与 Widget Extension 均能在 iPhone 模拟器编译。
- 空测试 target 能由 `xcodebuild test` 启动。

## 阶段 2：实现 SwiftData 模型与排序规则

### 预计文件

- `DynamicIslandNotes/Domain/Note.swift`
- `DynamicIslandNotes/Domain/NoteItem.swift`
- `DynamicIslandNotes/Domain/NoteItemOrdering.swift`
- `DynamicIslandNotes/Persistence/ModelContainerFactory.swift`
- `DynamicIslandNotesTests/NoteItemOrderingTests.swift`
- `DynamicIslandNotesTests/PersistenceTests.swift`

### 操作

1. 建立 `Note`：ID、标题、创建时间、更新时间、最近打开时间和列表项关系。
2. 建立 `NoteItem`：ID、文字、完成状态、排序位置和所属便签。
3. 将排序规则集中在纯函数或小型领域服务中：未完成项在前、已完成项在后；分区内保持稳定顺序。
4. 定义勾选、取消完成、拖拽和删除后的 `sortOrder` 归一化规则。
5. 创建生产与内存测试用 `ModelContainer`。

### 测试

- 新增项目保持创建顺序。
- 拖拽只改变目标分区内的顺序。
- 勾选后项目移动到已完成区底部。
- 取消完成后项目回到未完成区底部。
- 删除后排序位置连续且稳定。
- 保存并重新创建容器后数据仍能恢复。

## 阶段 3：建立视觉设计系统

### 预计文件

- `DynamicIslandNotes/DesignSystem/DesignColors.swift`
- `DynamicIslandNotes/DesignSystem/DesignMetrics.swift`
- `DynamicIslandNotes/DesignSystem/SurfaceCard.swift`
- `DynamicIslandNotes/DesignSystem/CircularIconButton.swift`
- `DynamicIslandNotes/DesignSystem/PrimaryActionButton.swift`
- `DynamicIslandNotes/DesignSystem/PlaceholderNoteLogo.swift`

### 操作

1. 以语义 token 定义浅色与深色颜色，不在业务视图散落具体色值。
2. 定义页面边距、卡片圆角、浮层圆角、行高、分隔线和阴影层级。
3. 建立大圆角容器、圆形按钮、主按钮和占位 Logo 组件。
4. 全部文字使用 Dynamic Type；图标优先使用 SF Symbols。
5. 为 Light、Dark、较大字号和 Reduce Motion 建立 Preview 组合。

### 验证

- Preview 中浅色、深色和较大字号无截断或对比度问题。
- 业务组件只引用语义 token，不直接绑定原型截图中的固定颜色。

## 阶段 4：实现当前便签工作台

### 预计文件

- `DynamicIslandNotes/Features/Workspace/NoteWorkspaceView.swift`
- `DynamicIslandNotes/Features/Workspace/NoteItemRow.swift`
- `DynamicIslandNotes/Features/Workspace/AddNoteItemRow.swift`
- `DynamicIslandNotes/Features/Workspace/WorkspaceState.swift`
- `DynamicIslandNotesUITests/WorkspaceFlowTests.swift`

### 操作

1. 首次启动时创建一张空白便签；之后恢复 `lastOpenedAt` 最新的便签。
2. 顶部显示便签标题与切换入口，标题支持原地重命名。
3. 主体使用大圆角列表容器，展示未完成区和已完成区。
4. 支持连续新增、原地编辑、左滑删除、勾选和长按拖拽。
5. 完成状态变化调用阶段 2 的统一排序规则，并以系统弹簧动画移动。
6. 底部先放置无业务实现的 Live Activity 主按钮壳，阶段 7 再接入真实状态。

### 测试

- 首次启动、重启恢复和空便签状态。
- 连续新增与编辑。
- 勾选移动、取消完成、删除和拖拽。
- 较长文字、空文字和大字号边界。

## 阶段 5：实现多便签切换面板

### 预计文件

- `DynamicIslandNotes/Features/NoteSwitcher/NoteSwitcherSheet.swift`
- `DynamicIslandNotes/Features/NoteSwitcher/NoteSwitcherRow.swift`
- `DynamicIslandNotes/Features/NoteSwitcher/CreateNoteFlow.swift`
- `DynamicIslandNotesUITests/NoteSwitcherFlowTests.swift`

### 操作

1. 点击工作台顶部入口后展示底部切换面板。
2. 便签按最近使用时间排列，点击后设为当前便签并关闭面板。
3. 在面板中创建新便签并直接切换过去。
4. 删除前确认；删除当前便签后选择最近使用的剩余便签。
5. 删除最后一张后立即进入新的空白便签，避免出现无工作台状态。

### 测试

- 创建多张便签并切换。
- App 重启后恢复最后使用的便签。
- 删除普通、当前和最后一张便签。
- 面板在浅色、深色和大字号下保持可用。

## 阶段 6：建立 Live Activity 共享契约

### 预计文件

- `Shared/NoteActivityAttributes.swift`
- `Shared/NoteActivityContentBuilder.swift`
- `DynamicIslandNotes/LiveActivity/LiveActivityControlling.swift`
- `DynamicIslandNotes/LiveActivity/ActivityKitLiveActivityController.swift`
- `DynamicIslandNotesTests/NoteActivityContentBuilderTests.swift`
- `DynamicIslandNotesTests/LiveActivityStateTests.swift`

### 操作

1. 创建由 App 与 Widget Extension 共同编译的 `NoteActivityAttributes`。
2. Attributes 保存稳定的 `noteID`；Content State 保存标题、按展示顺序排列的文字快照和 revision。
3. 使用纯 `NoteActivityContentBuilder` 将 SwiftData 模型转换为可编码快照。
4. 用协议封装 ActivityKit，便于单元测试启动、更新、结束和状态恢复。
5. 控制器启动前结束已有的同类型 Activity，保证同一时间只有一张便签。
6. App 启动时以 `Activity.activities` 为真实来源恢复运行状态。

### 测试

- 快照保持便签当前顺序，不按完成状态筛选。
- 空便签、长文字和特殊字符可正确编码。
- 启动新便签前结束旧 Activity。
- 更新、手动停止、系统已结束和删除便签的状态一致。

## 阶段 7：实现灵动岛只读布局

### 预计文件

- `DynamicIslandNotesLiveActivity/NoteLiveActivityWidget.swift`
- `DynamicIslandNotesLiveActivity/ExpandedNoteContentView.swift`
- `DynamicIslandNotesLiveActivity/CompactNoteLogoView.swift`

### 操作

1. `compactLeading` 与 `minimal` 只显示单色占位 Logo。
2. 不在 compact/minimal 中显示标题、数量、进度或完成状态。
3. 展开布局显示标题和按顺序排列的列表文字。
4. 使用系统提供的 region、`ViewThatFits`、`lineLimit` 和裁剪组合适配展开高度；超出空间直接截断。
5. 不添加行级 `Button`、`Link`、勾选控件或滚动容器。
6. 对整个 Live Activity 配置指向 `noteID` 的 `widgetURL`。
7. 为紧凑、最小、展开、空内容、长内容和深色背景建立 Preview。

### 验证

- Widget Extension 编译通过。
- 展开内容不出现“更多”、剩余数量或操作元素。
- 不同内容长度下不越过系统区域，也不出现横向溢出。

## 阶段 8：连接工作台、同步和 deep link

### 预计文件

- `DynamicIslandNotes/LiveActivity/LiveActivityCoordinator.swift`
- `DynamicIslandNotes/Navigation/DeepLinkRouter.swift`
- `DynamicIslandNotes/App/AppRootView.swift`
- `DynamicIslandNotesTests/DeepLinkRouterTests.swift`

### 操作

1. 将工作台底部按钮接入真实 Activity 状态。
2. 点击“显示在灵动岛”时生成快照并启动；点击“停止显示”时结束。
3. 当前便签不是正在展示的便签时，按钮仍显示“显示在灵动岛”。
4. 每次 SwiftData 成功保存后，若修改的是正在展示的便签，则更新 Activity。
5. 删除正在展示的便签前结束 Activity。
6. 处理 `dynamicislandnotes://note/<id>`，找到便签后切换工作台。
7. deep link 指向已删除便签时安全回退到当前或空白便签。

### 测试

- 修改当前展示便签会更新；修改其他便签不会误更新。
- 切换工作台不自动替换 Activity。
- 删除展示中的便签会结束 Activity。
- 合法、未知和格式错误的 deep link 都有确定结果。

## 阶段 9：错误处理与无障碍收口

### 预计文件

- `DynamicIslandNotes/LiveActivity/LiveActivityAvailabilityView.swift`
- `DynamicIslandNotes/Components/TransientMessageView.swift`
- 对阶段 3–8 文件的小范围修订

### 操作

1. 使用 `ActivityAuthorizationInfo` 检查 Live Activities 是否可用。
2. 不可用时保留工作台能力，并在主按钮附近解释原因。
3. 保存失败时不发送旧快照；保留编辑值并允许重试。
4. Activity 更新失败时，以系统真实 Activity 状态校正按钮，并允许下一次编辑重试。
5. 为按钮、列表项、完成状态和切换面板补充 VoiceOver label/hint。
6. 检查 Reduce Motion、Dynamic Type、深色模式和足够的点击区域。

### 验证

- 禁用 Live Activities 时 App 仍可完整编辑便签。
- 模拟控制器失败时不丢本地数据、不显示错误运行状态。
- Accessibility Inspector 无阻塞问题。

## 阶段 10：自动化与真机验收

### 自动化检查

1. 对 App scheme 执行 clean build。
2. 在可用的 iPhone 16 Pro 模拟器执行全部单元测试与 UI 测试。
3. 单独构建 Widget Extension，确保共享文件 target membership 正确。
4. 检查编译警告、测试失败和未使用的临时实现。

建议命令形态：

```bash
xcodebuild -project DynamicIslandNotes.xcodeproj \
  -scheme DynamicIslandNotes \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  clean test
```

如果本机模拟器名称或 OS 不同，以 `xcrun simctl list devices available` 的实际结果替换 destination。

### 真机检查表

- 安装并首次启动 App。
- 创建、切换并编辑多张便签。
- 手动启动当前便签 Live Activity。
- 紧凑状态侧边只出现占位 Logo。
- 展开后只读显示标题与便签内容，过长内容直接截断。
- 展开状态没有任何可操作控件。
- 点击展开后的灵动岛进入正确便签工作台。
- 新增、编辑、删除、排序和勾选后内容同步。
- 切换工作台不会自动替换当前 Activity。
- 主动展示另一张便签会替换原 Activity。
- 手动停止、删除展示中便签和 App 重启后的状态正确。
- 浅色与深色外观均符合设计系统。

## 交付顺序

1. 工具链与工程骨架。
2. 数据模型与纯业务测试。
3. 设计系统与工作台。
4. 多便签切换。
5. Live Activity 契约与 Widget UI。
6. 同步、跳转和错误处理。
7. 自动化测试与真机验收。

每个阶段应形成一个边界明确、可独立回退的提交；不得把 `原始资料/` 或其他现有未跟踪文件混入提交。
