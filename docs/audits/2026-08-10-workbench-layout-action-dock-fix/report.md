# Workbench Layout & Action Dock Fix — Audit Report

日期：2026-08-10

设备：iPhone 16 Pro 26 Simulator，iOS 26.2

工具链：Xcode 26.3（17C529）

## 结论

Workbench 已从整页滚动结构改为屏幕级 scaffold：Header 与 Note Surface 使用主内容区，非编辑态 Dock 和编辑态 Commit Bar 通过 bottom safe-area inset 固定。Empty、Note、Character Count 与 Live 不再推动 Dock；编辑态完全移除 Dock；正文和编辑器只在 Note Surface 内部滚动。

Action Dock 已拆为三槽水平组件，顺序固定为 Move → Go Live / Live → Delete。两侧是中性圆形 icon action；中心 pill 在 ready、starting、live、stopping 之间保持同一 frame。LiveStatusIndicator 只用 SwiftUI `Circle` 的 fill/stroke 构造，没有 `lucide-radio`、广播图标、emoji、SVG 或图片近似。

本轮未修改 `NoteWorkspace`、当前便签/便签库事务、Done 提交语义、Delete Confirmation 业务流程、ActivityKit adapter、路由、持久化、deep link 或 widget 内容。短生命周期的 starting/stopping 仅是由现有异步动作驱动的页面 presentation state，并在动作完成后清理。

## 实现范围

- 新增 `WorkbenchScaffold`、`WorkbenchHeader`、`WorkbenchNoteSurface`、`EditingCommitBar`。
- 将 `WorkbenchActionDock`、`DockIconAction`、`LiveActionControl`、`LiveStatusIndicator` 拆为独立正式组件。
- Note Surface 按剩余空间布局；展示正文与 `UITextView` 各自内部滚动，并为 Character Progress/Feedback 保留内容 inset。
- Character Progress 固定在 Surface 右下角；Accessibility 字号下扩大详情避让空间。
- Delete Confirmation 在高度不足时只滚动说明/反馈，Delete 与 Cancel 固定可见。
- Header 只保留单行 `Island Notes` 与 trailing More。
- 增加 Dock presentation model、Design System token、确定性 Preview 矩阵及单元/UI/视觉测试。

## 测试反馈环

修改前完整基线：158 项测试通过，0 失败（134 feature + 24 UI）。

先增加失败契约，确认旧实现存在以下问题：Dock 未贴近底部、编辑态仍暴露 Dock、Header/空态文案错误、Go Live/Live frame 跳动，以及旧 destructive Dock Delete 语义。实现后相关单元测试、受影响业务回归、7 项 Workbench 布局契约与 3 项视觉流程均分别通过。

最终完整 scheme 结果记录在下方“最终验证”中。

## Simulator 视觉验收

按 Empty → Editing → Done → Go Live → Live → Delete Confirmation 的真实 UI 流程运行；Light、Dark 与 Accessibility XXXL 均由 XCTest 启动正式 App 并采集屏幕附件。

已采集：

1. Empty / Light
2. Empty / Dark
3. Note / Light
4. Note / Dark
5. Editing / Light
6. Editing / Dark
7. Go Live / Light
8. Go Live / Dark
9. Live / Light
10. Live / Dark
11. Character Count
12. Delete Confirmation
13. Accessibility XXXL

视觉判断：

- Dock 靠近底部安全区，主内容下方不再保留旧实现的大块空白。
- Empty、Note、Character Count、Live 使用同一 Surface/Dock 几何。
- Header 不再显示 `Not Live` / `Live` 第二行。
- ready 是空心圆，live 是绿色实心圆点；绿色没有扩散到整个 pill。
- Dock Delete 是中性入口；红色只出现在最终确认按钮。
- Editing Commit Bar 在 Surface 外部、键盘上方并横向填满。
- Light/Dark 的组件位置与尺寸一致。
- Accessibility XXXL 下三槽仍水平、首屏完整可点，没有纵向大按钮降级。

## 最终验证

- 通用 iOS Simulator production build：通过。
- Preview 所需正式 target 编译：通过；Preview fixtures 不连接真实数据库、ActivityKit、网络或全局 singleton。
- 全量 feature tests：136/136 通过。
- WorkbenchLayoutContractUITests：7/7 通过。
- 受影响业务 UI 回归：通过。
- WorkbenchVisualAuditUITests：3/3 通过并导出 13 张截图。
- 完整 scheme（稳定最终工作树）：170/170 通过，0 失败，0 跳过。
- `git diff --check`：通过。

## 工具回退与证据限制

当前会话没有暴露可调用的 XcodeBuildMCP 工具，因此按目标允许的等价路径回退到 `xcodebuild`、`xcrun simctl` 与 XCTest UI。构建、运行、交互、状态切换、截图和测试均在 booted Simulator 完成。

当前 `simctl` 只列出一台可用 iPhone（iPhone 16 Pro 26），所以没有窄宽 Simulator 截图。窄宽覆盖由 `Dock / Narrow Width` 正式 Preview、水平 `ViewThatFits` fallback 和 XXXL UI 契约提供；这不是等价于真实窄屏截图，仍作为证据限制保留。

Starting、Stopping、busy、Reduce Motion 与 Increase Contrast 由确定性正式 Preview、代码分支和编译覆盖验证，没有逐项 Simulator 截图。VoiceOver 顺序由 accessibility sort priority 与 XCUI 元素顺序断言覆盖，没有本轮真人 VoiceOver 朗读录屏。这些证据层级低于 Light/Dark/XXXL 的真实 Simulator 流程，不声称为同等视觉证据。

原型裁图带设备外框，Simulator 截图是系统原始画面；并排图按内容等高缩放，因此外框差异不应被解释为 App 几何差异。

## Wayfinder

正式实现已经先于剩余 Wayfinder 决策发生。本轮没有制作票据 03 的 throwaway prototype，也没有修改票据 03–05 的状态；后续可根据本目录的真实实现与视觉证据回填或关闭地图。
