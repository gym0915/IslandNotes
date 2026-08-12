# 建立原型与当前构建的逐状态视觉基线

- Parent: [Island Notes 高保真 UI 一致性与组件化修正地图](../map.md)
- Type: task
- Status: resolved
- Claim: codex:/root
- Blocked by: none

## Question

在同一台 booted iPhone Simulator、同一视口、同一 Light/Dark 与同一内容状态下，重新采集 Workbench Empty、Note、Character Count、Editing、Live、More Menu、Note Library、Settings、Delete Confirmation 以及可验证的系统展示截图，并与权威 PNG 并排或叠图后，哪些差异属于结构错误、组件状态错误、视觉 token 错误和可接受的系统自适应？

## Answer

基线已经在 iPhone 16 Pro（402 × 874 pt）、iOS 26.2 Simulator 上重新建立，浅色、深色和 Accessibility XXXL 三条 XCTest UI 流程均通过。证据与完整分类位于 `docs/audits/2026-08-10-ui-fidelity-baseline/`。

- 结构错误：Workbench Action Dock 跟随 `ScrollView > VStack`，当前最大 Y 为 628 pt，未锚定底部安全区；Note Surface 过短；编辑态 Done 位于卡片内部且 Dock 只是被键盘覆盖。
- 组件状态错误：Live 仍用 `lucide-radio`，没有原型中的空心/绿色圆形状态组件；Dock 删除入口常态错误使用 destructive 红色；最大辅助字号把 Dock 退化为三行并把 Delete 推到 904.7 pt。
- 视觉 token / 内容偏差：头部多出 `Not Live / Live` 状态行，占位文案与原型不同；More Menu、Library、Settings、Appearance Menu 和 Delete Confirmation 的整体语言基本一致，细节进入后续像素验收。
- 允许的系统自适应：iOS 状态栏、键盘、系统 Menu/Sheet 的细微差异；ActivityKit 托管表面本轮未用 Simulator 证据判定为通过。

本票据只建立审计基线，没有修改正式 SwiftUI 产品代码。后续应分别由票据 02 锁定 Workbench 布局契约、票据 03 锁定 Action Dock / Live 状态模型。
