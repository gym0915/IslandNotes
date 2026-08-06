# 使用 Feature 组合层与深模块

IslandNotes 不采用完整经典 MVVM，而保留一个 `@MainActor @Observable IslandNotesFeature` 作为 SwiftUI 的统一行为入口、跨模块用例协调者和最高层功能测试 seam。复杂职责拆入 `NoteWorkspace`（SwiftData 事务与当前便签不变量）、`LiveActivitySession`（Live 生命周期、更新、结束屏障与对账）、`AppearanceSettings`（Display Mode 持久化）和独立 `AppRouter`（App 级页面呈现与 deep link 导航）；顶层 Feature 负责编辑会话、删除确认、错误呈现及跨模块协调，More Menu 展开状态属于 `WorkbenchView` 的轻量本地交互。SwiftData 只有一个真实 adapter，因此不增加 RepositoryProtocol；`LiveActivityControlling` 因同时存在 ActivityKit adapter 与测试 fake 而保留。按钮、设置行、Library row 和纯视觉组件不创建浅薄 ViewModel。

`NoteWorkspace` 完全不知道 ActivityKit，不保存 `isLive`，也不依赖 `LiveActivityControlling`。需要入库、替换或删除时，顶层 Feature 先要求 `LiveActivitySession` 结束并重新确认实际会话，再调用 `NoteWorkspace` 的原子 SwiftData 事务；若 Live 已结束而内容事务失败，便签数据保持原样、产品状态为非 Live，并向用户呈现可重试错误。

`AppRootView` 组装长生命周期对象；`WorkbenchView` 绑定 `IslandNotesFeature`，仅保留焦点和菜单展开等短暂视图状态；`NoteLibraryView` 读取库投影并发送替换动作；`SettingsView` 绑定 `AppearanceSettings`。这些页面均不创建独立 ViewModel，More Menu、Note Card、字符环、按钮、Library row、Settings row 和删除对话框保持无状态。只有出现真正独立的异步生命周期或复杂状态机时才重新评估新增 ViewModel。
