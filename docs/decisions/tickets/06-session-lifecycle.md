# 重新定义 Live Activity 的挂起生命周期

- Parent: [灵动岛便签 MVP｜Wayfinder 地图](../../product/wayfinder/map.md)
- Label: `wayfinder:grilling`
- Status: closed
- Claim: `codex:/root (thread 019fb7e4-dac9-72b2-b625-2a428f15edbf)`
- Blocked by: none
- Execution: complete

## Question

在 Live Activity 最多只能活跃 8 小时、用户或系统也能提前移除或禁用展示的前提下，MVP 应如何重新定义“挂起”的用户承诺、到期后的状态，以及用户再次挂起的边界？

## Conflict surfaced by research

- 已确认决定要求便签持续挂起，直到用户主动取消、切换、放入便签库或删除。
- Apple 官方约束规定常规 Live Activity 最多活跃 8 小时；到点后立即离开灵动岛，锁屏最多再保留 4 小时。
- Live Activity 还可能被用户移除、被用户在 Settings 禁用，或受系统 presentation 选择影响。

## Context

- [ActivityKit 与灵动岛系统约束研究](../../research/activitykit-system-constraints.md)
- [验证 Live Activities 与灵动岛的系统约束](01-system-constraints.md)

## Decision boundary

本票只决定产品语义与用户承诺，不设计实现方案，不处理具体异常恢复流程；后者仍由“确定挂起失败与系统中断后的恢复规则”解决。

## Resolution

决策资产：[挂起生命周期决策](../records/session-lifecycle.md)

“挂起”正式定义为用户在 App 中显式启动的一段最长 8 小时、可能提前结束的 Live Activity 展示会话，不是便签的长期身份或永久常驻承诺。活动达到 8 小时上限或确认提前结束后，当前便签统一进入“未挂起”；产品不主动保留 Lock Screen 尾部，系统残留也不改变该状态。

用户可以在“未挂起”时回到 App 显式再次挂起同一条当前便签；每次都是全新的展示会话，不限次数、不设冷却、不自动续挂、不重置活跃会话，也不承诺系统一定接受请求。Live Activity 结束不会删除、入库、替换便签或使内容丢失。

面向用户采用静默生命周期，不主动说明 8 小时或正常结束原因；但不得暗示永久显示、只由用户结束或无缝续挂。活动状态检测、错误反馈、自动重试、重启对账和权限关闭后的恢复继续由[确定挂起失败与系统中断后的恢复规则](04-failure-recovery.md)处理。
