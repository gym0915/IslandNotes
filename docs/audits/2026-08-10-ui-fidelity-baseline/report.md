# Island Notes 原型一致性与组件化基线审计

审计结论：**当前 App 已有较好的 Design System 和可复用组件基础，但 Workbench 主骨架尚未达到高保真验收条件。** 你指出的两个问题都成立：Workbench Action Dock 没有相对屏幕底部安全区定位；Go Live / Live 仍使用 `lucide-radio` 近似表达，未复刻原型中的定制圆形状态指示器。

## 1. 审计依据与运行环境

- 权威视觉来源：`docs/prototypes/island-notes-ios-prototype.png`。
- 产品约束：ADR 0002 规定最新 PNG 优先于旧规格、代码和测试；ADR 0007 规定原型中的 token、组件状态、尺寸与层级是规范要求。
- 设备：iPhone 16 Pro Simulator，402 × 874 pt，iOS 26.2。
- 当前运行证据：Light、Dark、Editing、Live、More Menu、Note Library、Settings、Appearance Menu、Delete Confirmation，以及系统内容字号 `accessibility-extra-extra-extra-large`。
- 运行结果：浅色流程、深色流程、最大辅助字号流程均通过 XCTest UI 执行；正式产品工程另行构建成功。
- 取证方式：临时项目副本中的确定性 UI 测试；没有修改正式 SwiftUI 产品代码。

## 2. Complete product flow 健康度

| 状态 | 健康度 | 结论 |
| --- | --- | --- |
| Workbench Empty / Note | 结构不健康 | 内容卡片与 Dock 一起位于 `ScrollView > VStack`，Dock 最大 Y 为 628 pt，而屏幕高度为 874 pt；底部留下约 246 pt 空间。原型要求 Dock 靠近底部安全区。 |
| Character Count | 部分健康 | 圆环和展开胶囊存在，但它们跟随过短的内容卡片，整体垂直位置错误。 |
| Editing | 结构不健康 | `Done` 是卡片内部左下角的 69 pt 胶囊；原型是卡片外、键盘上方的横向主按钮。Dock 仍在布局树中，只是被键盘覆盖。 |
| Live | 状态不健康 | 当前头部显示广播图标和 `Live / Not Live`，Dock 中 Go Live 也使用广播图标；原型使用圆形空心/绿色实心状态指示器，且头部没有重复状态行。 |
| More Menu | 基本健康 | 锚点、菜单层级和 Light/Dark 方向接近原型；仍应在主骨架修正后重新核对像素位置。 |
| Note Library | 基本健康 | Sheet、标题、关闭按钮和卡片语言接近；本轮只有一条确定性数据，不能据此验收三条列表的完整节奏。 |
| Settings / Appearance | 基本健康 | 信息架构、列表层级和外观菜单接近；细节间距可放到 P2。 |
| Delete Confirmation | 基本健康 | 底部确认层、scrim 和危险动作层级接近；Dock 常态下提前使用红色危险样式不符合原型。 |
| 最大辅助字号 | 不健康 | 头部、占位文案和动作字号可缩放，但 Dock 退化为三行纵向布局；Delete 最大 Y 为 904.7 pt，首次呈现被屏幕裁切，需要滚动才能触达。 |
| Dynamic Island / Lock Screen | 本轮未验收 | Simulator 内确定性 Live controller 只能证明 App 状态流；无法证明 ActivityKit 托管表面的真实排版。本轮已有单独的真机证据目录，但不混入当前同视口基线。 |

关键比较图均为左侧原型、右侧当前 App：

- `comparisons/01-workbench-empty-light.png`
- `comparisons/03-editing-light.png`
- `comparisons/04-workbench-live-light.png`
- `comparisons/05-more-menu-light.png`
- `comparisons/06-note-library-light.png`
- `comparisons/07-settings-light.png`
- `comparisons/08-delete-confirmation-light.png`

## 3. UI Component Library 自查

### 已经独立并可复用的部分

工程并不是每个页面从零开始。已经存在以下复用层：

- token：`IslandDesign` 集中管理颜色、排版、间距、圆角、尺寸和动效。
- 基础组件：`IslandSurface`、`IslandButtonStyle`、`IslandIconButton`、`AppIconView`。
- 复合组件：`ActionDock`、`CharacterProgressView`、`MoreMenu`、`AppSheetContainer`、`SettingsRow`、`LibraryNoteCard`、`DeleteConfirmationView`。
- 行为语义：`WorkbenchActionAvailability` 与 `WorkbenchActionSemantic` 已把 enabled / disabled、Live、destructive 等行为语义集中化。

### 尚未达到原型组件库要求的部分

1. `ActionDock` 虽然已经是一个控件，但直接接收整个 `IslandNotesFeature`，视觉状态、业务调用和排版策略仍耦合在一起，不利于独立预览和视觉回归。
2. Live 没有独立的 `LiveStatusIndicator`。`AppIcon.live` 直接绑定 `lucide-radio`，而原型要求的是可定制圆形状态标记。
3. `IslandButtonStyle` 只覆盖 kind、pressed opacity、disabled opacity 和 Live 绿色点；没有把 busy、starting、stopping、confirming、error recovery 做成显式状态模型。
4. Delete 在 Dock 常态直接映射为 `.destructive`，导致红色实心按钮；原型中 Dock 的删除入口是中性图标，危险强调只出现在确认层。
5. `ViewThatFits` 在宽度不足时把整个 Dock 改成三行纵向按钮，这不是原型定义的自适应行为，并在最大辅助字号下产生裁切。
6. `DesignSystemTests` 当前验证 token 常量、图标资源和语义映射，但没有验证 Workbench 的关键几何约束、Dock 底部锚点、Live 状态视觉矩阵或 Light/Dark 截图基线。

因此，对问题 1 的回答是：**组件化基础已经存在，但核心 Action Dock 和 Live 指示器的视觉状态契约尚未完成，不能视为原型中的 UI Component Library 已完整实现。**

## 4. 优化优先级

### P0 — 先修正结构和核心状态

1. **重建 Workbench 布局骨架。** Header、可伸展 Note Surface、Workbench Action Dock 应是三个明确区域；非编辑态用底部安全区 inset 固定 Dock，而不是把 Dock 放在内容 `VStack` 末尾。
2. **实现定制 Live 状态组件。** 取消 `lucide-radio` 在 Workbench 头部和 Dock 的使用；以 SwiftUI `Circle` 的 fill / stroke 实现原型的空心 ready 和绿色 live 指示器。
3. **把编辑态 Done 移出 Note Surface。** Done 应在键盘上方形成独立、横向主操作区；编辑时 Workbench Action Dock 不应继续占据布局或被动藏在键盘后面。
4. **让 Note Surface 消耗 Workbench 的可用高度。** 当前固定 `editorMinimumHeight = 310` 使卡片过短，并把 Dock 提前到 580 pt 附近；高度应由容器可用空间和键盘状态共同决定。

### P1 — 完成组件状态与可访问性

1. 移除头部重复的 `Not Live / Live` 状态行，恢复原型中的单行标题和 More 对齐关系。
2. Dock 中 Delete 常态改为中性图标；只有 Delete Confirmation 的确认动作使用 destructive token。
3. 把占位文案恢复为原型文案，除非产品另有明确决定。
4. 为 Action Dock 建立显式状态矩阵：
   - Move：disabled / enabled / busy。
   - Live：disabled / ready / starting / live / stopping / failed-feedback。
   - Delete：disabled / enabled / confirming / busy。
   - 所有可交互状态：rest / pressed / disabled，并覆盖 Light / Dark。
5. 定义最大辅助字号行为。优先保持三个动作属于同一个 Dock；如果需要滚动或两行布局，必须保证首次出现时没有裁切、44 pt 触控目标完整、VoiceOver 顺序仍为 Move → Live → Delete。
6. 增加布局与视觉回归测试：Dock 到安全区的距离、三槽位对齐、Done 与键盘关系、Live ready/live 图形，以及 Light/Dark 关键截图。

### P2 — 主结构稳定后的视觉打磨

1. 重新核对 More Menu、Settings、Appearance Menu 的锚点、sheet 顶部间距、阴影和圆角。
2. 使用与原型相同数量和长度的 Library fixture，核对三条卡片的节奏、分隔线和元数据排版。
3. 对字符计数胶囊、进度圆环、卡片内边距做像素级叠图验收。

### Allowed — 可接受的系统自适应

- iOS 26 状态栏、电池、键盘键帽与原型生成环境之间的系统差异。
- 系统 Menu、Sheet、键盘和 ActivityKit 在不破坏语义层级、安全区和最小触控目标时产生的细微排版变化。
- 确定性测试数据的正文与时间内容不同；但验收视觉节奏时必须使用同等数量、近似长度的数据。

## 5. 建议的模块边界

```text
WorkbenchScaffold
├── WorkbenchHeader
├── WorkbenchNoteSurface
│   ├── RenderedNote / MarkedTextEditor
│   └── CharacterProgress
├── EditingCommitBar (editing only)
└── WorkbenchActionDock (non-editing, bottom safe-area anchored)
    ├── DockIconAction: Move
    ├── LiveActionControl
    │   └── LiveStatusIndicator
    └── DockIconAction: Delete
```

推荐让 `WorkbenchActionDock` 接收不可变的 presentation model 和三个 action closure，而不是直接持有完整 `IslandNotesFeature`。这样可在 Preview、测试和不同 Workbench 状态中复用同一个控件，并单独覆盖状态矩阵。

## 6. 下一轮视觉验收矩阵

| 维度 | 必验集合 |
| --- | --- |
| 外观 | Light、Dark |
| Workbench | Empty、Note、Character Count、Editing、Live、Delete Confirmation |
| Action Dock | no content、ready、live、busy、pressed、disabled |
| 宽度 | iPhone SE 级窄屏、iPhone 16 Pro |
| 文字 | Large、Accessibility XXXL |
| 系统设置 | Reduce Motion、VoiceOver 顺序、Increase Contrast |
| 系统展示 | 真机 Dynamic Island Compact / Expanded / Minimal、Lock Screen |

验收标准应同时包含人工并排图与自动化几何断言；仅有截图或仅有 token 单元测试都不足以证明高保真一致。

## 7. 证据限制

- 截图不能证明 VoiceOver 实际朗读顺序、Reduce Motion 全路径或真实 ActivityKit 生命周期。
- 本轮最大辅助字号确认了视觉裁切风险，但没有覆盖辅助字号下的编辑、菜单和 sheet。
- 真机 Live Activity 已有独立审计材料；当前报告只回答同一 Simulator 视口下的 App UI 基线问题。
