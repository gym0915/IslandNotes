# 使用独立 AppRouter

IslandNotes 本次引入独立 `AppRouter`，集中管理 App 级页面呈现和从 deep link 回到 Workbench 的导航，即使当前主要路由只有 Note Library 与 Settings 两个 sheet。这个选择让导航成为明确、可独立演进的模块，而不是 `IslandNotesFeature` 中的附带状态；代价是当前版本会增加一层对象与注入关系，因此 Router 的公开接口必须保持小而完整，不能吸收编辑、删除、菜单或业务事务状态。

`AppRouter` 只负责呈现或关闭 Note Library、呈现或关闭 Settings、处理 deep link 后回到 Workbench，并保证同一时刻最多一个 App 级 sheet。更多菜单、展示态与编辑态、删除确认、当前便签、Live、SwiftData 事务和错误消息均不属于 Router。
