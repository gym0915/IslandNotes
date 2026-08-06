# 保留最高层 Feature 行为测试 seam

重构后仍以 `IslandNotesFeature` 的公共用户动作作为主要自动化行为入口。测试 harness 继续组合内存 SwiftData `ModelContainer`、`FakeLiveActivityController`、隔离的外观偏好存储和真实 `AppRouter`；现有 46 条 Feature/契约测试在重构过程中持续运行，只有本次明确改变的产品行为才改写。`NoteWorkspace`、`LiveActivitySession` 与 `AppearanceSettings` 可以增加聚焦测试，但不能取代最高层组合测试，也不得通过断言私有方法、模块调用次数或类型拆分方式锁死架构。
