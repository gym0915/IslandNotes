# Workbench Visual Detail Fix — Audit Report

日期：2026-08-10

设备：iPhone 16 Pro 26 Simulator，iOS 26.2

工具链：Xcode 26.3（17C529）

## 结论

本轮把 Workbench 的 Dock 与状态组件按权威原型重新量化，不再沿用早期票据中的近似值。两侧 Dock action 为 `56 × 56 pt`，中心 Live pill 为 `156 × 56 pt`；两侧控件相对 Note Surface 的左右边缘各内缩 `16 pt`。Character Progress 改为 `48 pt` 外径、`8 pt` 线宽，圆心仍保持原来的 trailing/bottom 锚点。

Go Live 的空心环与 Live 的绿色圆使用同一个固定布局槽及固定 leading anchor。XCUI 对真实渲染截图进行像素质心计算，两种状态的圆心误差在自动契约容差 `0.5 pt` 内；归档截图进一步得到两帧 Live 圆心均为 `(467.5, 2363.5) px`，偏差为 `0 px`。

Live 状态增加明暗交替的呼吸动效：绿色 core 与 halo 只改变 opacity，不改变 frame、offset 或 scale。两张实际截图的中心色分别为 `RGB(126, 160, 123)` 与 `RGB(78, 127, 74)`，同时质心保持不变。Reduce Motion 开启时循环任务不会启动，保留静态亮态。

## 视觉 token 与几何

- Workbench canvas：Light `#F4F4F5`，Dark `#000000`。
- Note Surface：Light `#FDFDFD`，Dark `#121213`；连续圆角 `34 pt`。
- Dock side action 背景：Light `#FDFDFD`，Dark `#101010`；常规对比度不加描边，Increase Contrast 使用 `2 pt` 描边。
- Live pill 背景：Light `#F4F4F5`，Dark `#000000`。
- Live pill border：Light `#E4E4E5`，Dark `#1A1A1A`，常规 `1 pt`。
- ready ring：`16 pt`、`2 pt` stroke，Light `#85858A`。
- live halo/core：`24 pt` / `16 pt`，core `#3F743A`；固定在同一 `18 pt` 逻辑槽中，halo 允许光学溢出但不参与布局。
- Live 呼吸半周期 `1.2 s`，core/halo 的暗相 opacity 分别为 `0.62` / `0.70`。
- Dock：`56 / 156 / 56 pt` 三槽水平结构，最小槽间距 `16 pt`；标准屏左右 padding 为 `40 pt`，即 Surface `24 pt` padding 加 `16 pt` 光学内缩。
- Character Progress：外径 `48 pt`，stroke `8 pt`。

## 测试反馈环

先增加两条会在旧实现失败的 UI 契约：

1. Dock 外侧 action 与 Note Surface 的光学边缘关系及 `56 / 156 / 56` 尺寸。
2. 对 `toggle-pin` 的真实截图做像素质心计算，验证 ready 空心环与 live 绿点切换后不位移。

旧实现的量化失败为：两侧 action 相对 Surface 各内缩 `37 pt`，且 Go Live → Live 的指示器水平移动约 `10.24 pt`（完整屏幕截图测得约 `12 pt`，差异来自裁图与阈值）。修复后两条契约与完整 `WorkbenchLayoutContractUITests` 均通过。

## Simulator 视觉验收

正式 App 在 booted iPhone Simulator 中完成 Empty → Editing → Done → Go Live → Live → Delete Confirmation 流程，并分别采集 Light、Dark 与 Accessibility XXXL。当前目录包含 14 张截图，其中第 09 与第 14 张是 Live 呼吸的两个不同相位；它们用于证明明暗变化，不把第 14 张声明为固定“暗相”。

首轮并行执行三条视觉流程时，Dark 流程被 Simulator 一次性 `signal kill` 中断，Light 与 XXXL 通过；Dark 随后独立重跑通过并重新导出完整 5 张截图。该异常没有对应产品断言失败。

视觉检查结果：

- Light/Dark 的 canvas、Surface、side action、Live pill 与 border 均使用专用原型采样 token。
- Dock 左右间距对称，三槽保持水平；XXXL 下所有动作仍在首屏且完整可点。
- Character Progress 的直径和粗细与原型接近，展开详情不推动 Dock。
- Go Live 与 Live 的指示器位置一致；呼吸只改变绿色明暗。
- Header 与 Surface 的尺寸、圆角及纵向间距较上一轮进一步接近原型。

## 最终验证

- 通用 iOS Simulator production build：通过。
- Workbench 两条关键视觉契约：通过。
- `WorkbenchLayoutContractUITests`：通过。
- `WorkbenchVisualAuditUITests`：Light、Dark、Accessibility XXXL 最终均通过；导出 14 张截图。
- 完整 scheme：171/171 通过，0 失败，0 跳过。
- 两路 code review：Standards 与 Spec 均无 P0/P1；发现的 Reduce Motion Preview 状态传递问题已修正。
- `git diff --check`：通过。

## 工具回退与证据限制

当前会话没有暴露 XcodeBuildMCP，因此按目标允许的等价路径使用 `xcodebuild`、`xcrun simctl`、XCTest UI 与 `xcresulttool` 完成构建、交互、截图及附件导出。

当前 `simctl` 只有一台可用 iPhone 16 Pro 26，无法提供真实 narrow-width Simulator 截图；窄宽仍由 `Dock · Narrow Width` 正式 Preview 和水平 fallback 覆盖。Reduce Motion 的停止条件由生产代码 guard 与 Preview override 传递覆盖，没有单独 Simulator 截图。呼吸周期截图使用两个运行时相位作人工视觉证据，不将固定等待时间描述为自动周期证明。

本轮没有修改 NoteWorkspace、便签事务、Done/Delete 业务语义、ActivityKit adapter、路由、持久化、deep link 或 widget 内容；只调整正式 Workbench 的 presentation、Design System token、Preview、测试与视觉证据。Wayfinder 票据 03–05 状态未修改。
