# IslandNotes 文档导航

本目录收录 IslandNotes 的产品规格、决策记录、系统研究、实施计划、验收资料、交互原型和审计证据。

## 当前权威资料

1. [新版设计与职责重构规格](product/mvp-spec.md)：已综合确认决定并发布为 `ready-for-agent` 的正式实施与验收契约。
2. [最新高保真原型](prototypes/island-notes-ios-prototype.png)：当前产品范围、界面状态、交互意图和 Design System 的默认最高权威输入。
3. [本轮 ADR](adr/)：对 PNG 未表达清楚的行为作绑定解释；只有 ADR 明确记录的修订才在具体冲突上优先于 PNG。权威顺序详见 [ADR-0002](adr/0002-high-fidelity-prototype-is-current-product-authority.md)。
4. [ActivityKit 与灵动岛系统约束](research/activitykit-system-constraints.md)：系统能力边界；产品原型与决策不能覆盖 Apple 平台约束。
5. [原生 App 实施计划](plans/2026-08-04-native-app-implementation.md)：上一版实现记录，不是新版开发顺序。
6. [真机 Live Activity 验收清单](verification/real-device-live-activity-checklist.md)：上一版发布验证基线；新版发布须按正式规格扩展并留存证据。

## 分类

- [`product/`](product/)：MVP 规格、Wayfinder 记录和产品资产。
- [`decisions/`](decisions/)：决策票与已确认决策。
- [`research/`](research/)：平台与技术研究。
- [`plans/`](plans/)：当前计划；`archive/` 中的文档已过时，仅供追溯。
- [`verification/`](verification/)：手工和真机验收清单。
- [`prototypes/`](prototypes/)：当前高保真 PNG 原型输入；旧 Web 原型已被取代。
- [`audits/`](audits/)：审计报告、截图和复跑证据。

## 项目代码

Xcode 工程、源码、配置与测试统一位于 [`../IslandNotes/`](../IslandNotes/)。
