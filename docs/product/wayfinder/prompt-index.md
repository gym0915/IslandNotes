# 灵动岛便签 Wayfinder｜决策票执行提示词索引

> 每次只复制执行一张票。提示词的唯一正文放在对应决策票内，本索引只说明顺序与依赖。

## 推荐执行顺序

### 第一批：可以并行

1. [验证 Live Activities 与灵动岛的系统约束](../../decisions/tickets/01-system-constraints.md)
   - 类型：Research / AFK
   - 当前状态：open、unassigned、无票据阻塞，但研究执行受地图 Notes 暂停
   - 复制其“可复制执行提示词”即代表授权本次任务读取 Apple 官方公开资料

2. [确定当前便签工作台与便签库的页面交互](../../decisions/tickets/02-workbench-prototype.md)
   - 类型：Prototype / HITL
   - 当前状态：open、unassigned、无阻塞
   - 原型完成后必须由用户评审，不会自动关闭

### 第二批：等待系统约束研究关闭后，可以并行

3. [确定灵动岛与锁屏的视觉呈现](../../decisions/tickets/03-live-activity-presentation.md)
   - 类型：Prototype / HITL
   - 阻塞者：验证 Live Activities 与灵动岛的系统约束

4. [确定挂起失败与系统中断后的恢复规则](../../decisions/tickets/04-failure-recovery.md)
   - 类型：Grilling / HITL
   - 阻塞者：验证 Live Activities 与灵动岛的系统约束

### 第三批：最终收束

5. [锁定 MVP 验收边界与交付规格](../../decisions/tickets/05-acceptance.md)
   - 类型：Grilling / HITL
   - 阻塞者：工作台与便签库原型、灵动岛与锁屏视觉、异常与恢复规则

## 每张提示词都包含

- 应调用的 skill
- 允许读取与禁止读取的文件范围
- 领取前的 Status、Claim、Blocked by 检查
- 先认领、后工作的状态变更
- 该票的执行范围与禁止顺带事项
- 产物路径与内容要求
- 验证清单
- HITL 等待点
- Resolution、closed、地图 Decisions so far 与阻塞关系更新
- 最终回复必须报告的内容
