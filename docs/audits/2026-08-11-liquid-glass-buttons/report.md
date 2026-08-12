# Liquid Glass Buttons — Audit Report

日期：2026-08-11

设备：iPhone 16 Pro 26 Simulator，iOS 26.2

工具链：Xcode 26.3（17C529）

## 结论

右上角 More 不再使用旧的固定 Material 背景；在 iOS 26 上使用原生交互式 Liquid Glass，Light 模式有清晰的白色折射、高光和环境阴影，Dark 模式自动适配深色背景。用户参考图、旧实现与本轮新实现已放入同一张三栏对比图。

全部自定义按钮入口均迁移到统一的 `islandInteractiveGlass` 设计系统 modifier。该 modifier 在 iOS 26 调用 SwiftUI 原生 `glassEffect(.regular.interactive())`，并根据按钮语义选择 tint；在 iOS 17–25 使用原有 Material/Color/border fallback。没有用自制 blur 模拟 Liquid Glass。

## 覆盖清单

- `IslandIconButton`：Workbench More、Sheet Close、Note Library Replace。
- `IslandButtonStyle`：编辑态 Done 及通用 primary/neutral/live/destructive action。
- `DockIconAction`：Move 与 Delete。
- `LiveActionControl`：Go Live / Live 胶囊。
- `CharacterProgressView`：字符统计圆环按钮。
- `DeleteConfirmationButtonStyle`：最终 Delete Note 与 Cancel。
- `MoreMenu`：Note Library 与 Settings 两个菜单按钮。
- `SettingsRow`：Feedback、Website、About。
- `SettingsView.appearanceMenu`：Display Mode 菜单入口；系统 Menu 内的选项由 iOS 26 系统样式负责。

Dock 与 More Menu 中的多个玻璃元素分别放在 `GlassEffectContainer` 中，共享渲染环境，避免重复的独立模糊层并允许原生邻近响应。所有玻璃层都在布局、frame 和内容样式之后应用，且只对可交互控件启用 `interactive`。

## Simulator 证据

正式 App 已实际运行并覆盖：

1. Empty / Light 与 Dark。
2. Editing / Done。
3. Go Live / Live。
4. Delete Confirmation。
5. More Menu。
6. Settings：Display Mode 与三个 support row。
7. Note Library：Close 与 Replace。
8. Accessibility XXXL。

视觉结果：右上角 More、底部两个圆形 action 和中心胶囊具有一致的玻璃层级；Dark 模式保留可辨边界；Done 与 destructive action 使用语义 tint，但仍由原生 Glass 渲染；Settings 与 Note Library 的按钮也有可见高光、透射和阴影。

## 验证

- iOS Simulator production build：通过。
- `WorkbenchLayoutContractUITests`：通过；Glass 没有改变 Dock、More、Live 圆心或三槽几何。
- Light、Dark、Accessibility XXXL 视觉流程：最终分别通过并导出截图。
- More Menu → Settings → Note Library 玻璃按钮视觉流程：通过并导出 3 张截图。
- 完整 scheme：172/172 通过，0 失败，0 跳过。
- `git diff --check`：通过。

首次并行执行视觉流程时 Light/Dark Runner 被 Simulator `signal kill`，没有产品断言失败；Light 与 Dark 随后分别隔离重跑通过。该情况记录为 XCTest/Simulator 资源波动，不作为产品通过证据，最终证据只使用隔离成功的结果。

## 依据与限制

实现遵循 Apple 的原生 SwiftUI Liquid Glass API：[Applying Liquid Glass to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views)、[GlassEffectContainer](https://developer.apple.com/documentation/swiftui/glasseffectcontainer) 与 [GlassButtonStyle](https://developer.apple.com/documentation/swiftui/glassbuttonstyle)。

当前只有 iOS 26.2 Simulator，因此 iOS 17–25 fallback 由 availability 分支和对应 deployment-target 编译覆盖，没有旧系统运行截图。没有修改 NoteWorkspace、便签事务、ActivityKit、路由、持久化或 widget 业务行为。
