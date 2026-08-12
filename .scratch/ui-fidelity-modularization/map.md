# Island Notes 高保真 UI 一致性与组件化修正地图

- Tracker: local-markdown
- Label: `wayfinder:map`
- Status: open

## Destination

形成一份可直接交给设计与开发的高保真修正规格：逐状态说明当前 App 与 `docs/prototypes/island-notes-ios-prototype.png` 的差异，锁定 Workbench 的布局契约、Workbench Action Dock 与 Live 指示器的组件状态模型、跨页面复用边界，以及可重复执行的视觉验收矩阵。

## Notes

- 本地图只做审计、决策和实施前规格，不修改正式 SwiftUI 产品代码。
- `docs/prototypes/island-notes-ios-prototype.png` 是最高权威；`docs/adr/0002-high-fidelity-prototype-is-current-product-authority.md` 与 `docs/adr/0007-prototype-design-system-is-normative.md` 继续生效。
- 每次推进使用 Wayfinder；术语与组件边界使用 domain-modeling；运行中界面审计使用 product-design:audit；Simulator 取证使用 build-ios-apps:ios-debugger-agent。
- 用户已明确：三个动作是一个 Workbench Action Dock，而不是每页重做的三个按钮；非编辑态相对屏幕底部安全区定位；Live 视觉使用定制圆形状态指示器，不使用广播/电台图标近似替代。
- 票据 01 已在 booted iPhone 16 Pro（402 × 874 pt）、iOS 26.2 Simulator 上建立 Light、Dark 与 Accessibility XXXL 新基线；历史截图未作为本轮最终审计证据。
- 所有票据均以组件化、状态完整性和跨 Light/Dark 一致性为验收前提，同时保留 Dynamic Type、VoiceOver、Reduce Motion 与最小 44pt 触控目标。

## Decisions so far

- [票据 01](issues/01-establish-current-visual-baseline.md)：确认 Workbench 主骨架、Action Dock 底部锚点、Live 圆形状态组件和编辑态 Done 为首要结构/状态差异；完整证据见 `docs/audits/2026-08-10-ui-fidelity-baseline/report.md`。
- [锁定 Workbench 的屏幕布局与安全区契约](issues/02-lock-workbench-layout-contract.md)：锁定固定 Header、可伸缩且内部滚动的 Note Surface、Surface 内 Character Progress、键盘上 Commit Bar、底部 safe-area Action Dock 以及不重排主骨架的 feedback / delete overlays，并规定窄屏和 Accessibility XXXL 下三槽位不可退化为纵向三按钮。

## Not yet specified

- Note Library、More Menu、Settings 与 Delete Confirmation 已有同态基线，最终像素容差并入票据 05；Dynamic Island 与 Lock Screen 仍需同态真机证据确认。
- 视觉回归采用截图 diff、人工叠图还是两者结合，以及允许的像素误差；待基线质量可量化后决定。

## Out of scope

- 改变当前便签、便签库、Done 提交或 Live Activity 生命周期等既有产品行为。
- 新增页面、功能、主题、品牌或营销视觉。
- 本地图中的正式 SwiftUI 实现、提交、发布和 App Store 工作。
