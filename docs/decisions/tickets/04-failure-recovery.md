# 确定挂起失败与系统中断后的恢复规则

- Parent: [灵动岛便签 MVP｜Wayfinder 地图](../../product/wayfinder/map.md)
- Label: `wayfinder:grilling`
- Status: open
- Claim: unassigned
- Blocked by: none

## Question

当挂起权限不可用、活动启动或更新失败、系统结束活动、设备重启或 App 状态与灵动岛状态不一致时，用户应看到什么状态、得到什么反馈，并通过什么动作恢复一致？

## 可复制执行提示词

~~~text
$wayfinder
$grilling
$domain-modeling

请在仓库根目录中，只领取并解决决策票“确定挂起失败与系统中断后的恢复规则”。

这是一个 HITL grilling 票。技术事实来自已经关闭的系统约束研究，产品取舍必须逐题交给用户决定；不得替用户回答，也不得一次抛出多道问题。

开始前：

1. 完整读取并遵守 wayfinder、grilling 与 domain-modeling。
2. 读取：
   - docs/product/wayfinder/map.md
   - docs/product/wayfinder/overview.md
   - docs/decisions/tickets/04-failure-recovery.md
3. 检查“验证 Live Activities 与灵动岛的系统约束”是否已关闭，并读取：
   - docs/decisions/tickets/01-system-constraints.md
   - 其 Resolution 链接的研究文件
4. 若研究票未关闭、研究产物缺失或 Blocked by 未解除，停止并报告阻塞，不认领。
5. 若本票仍为 Status: open、Claim: unassigned 且已解除阻塞，先把 Claim 改为当前执行者标识。
6. 不读取 docs/prototypes/web-prototype/、产品代码或其他未列出的项目文件。
7. 本次只形成异常与恢复决策，不写正式代码、不解决其他票。

讨论方法：

1. 先从研究文件提取系统真实状态，不把可查事实问用户。
2. 建立工作文件：
   docs/decisions/records/failure-recovery.md
3. 矩阵每行至少包含：触发场景、系统事实、本地便签状态、系统 Activity 状态、用户可见状态、提示方式、恢复动作、是否自动重试、数据是否安全、待真机验证。
4. 至少覆盖：
   - 用户或系统禁用 Live Activities；
   - 首次挂起启动失败；
   - 已挂起时内容更新失败；
   - App 进入后台或被系统终止；
   - Live Activity 达到系统持续时间上限或被系统结束；
   - 设备重启；
   - App 显示“已挂起”但岛上不存在活动；
   - 岛上仍有活动但 App 本地状态认为未挂起；
   - 用户从岛或锁屏点击回到 App；
   - 用户删除、入库、交换当前便签时结束活动失败。
5. 按依赖顺序一次只讨论一个决策。每题先给出推荐答案、理由和一个具体场景，然后等待用户回复；不要批量发问。
6. 用户确认一项后立即更新决策矩阵；术语发生变化时，同步更新“灵动岛便签-MVP-Wayfinder.md”的领域词汇。不要把实现细节写进领域词汇。
7. 如果用户否决建议，完整移除被否决方案，不把它改写成“可选”。
8. 若研究事实暴露新的独立决策，创建新的子票并补阻塞关系，不把它偷偷塞进本票。

完成标准：

1. 所有场景都明确回答：App 认为是否挂起、用户看到什么、内容是否保留、下一步能做什么。
2. 不存在“当前便签”和“挂起便签”悄然分离的状态；若系统强制产生不一致，必须定义可见状态和收敛动作。
3. 每个错误提示都有触发条件，不用笼统的“发生错误”代替。
4. 所有自动恢复和自动重试都有边界，不能制造无限循环或误报已挂起。
5. 矩阵中的系统事实与研究文件一致，产品建议和技术事实明确分栏。
6. 用户明确确认已经达到 shared understanding 前，不得关闭票据。

收口：

1. 用户确认完成后，在本票新增 Resolution，概括最终状态模型并链接异常恢复矩阵。
2. 将 Status 改为 closed，保留 Claim；在地图 Decisions so far 追加本票链接和一行结论。
3. 检查“锁定 MVP 验收边界与交付规格”的 Blocked by，仅移除本票这一项，不领取最终票。
4. 最终回复报告：矩阵路径、核心恢复原则、仍需真机验证的场景、票据与地图状态、下一张可领取票。
~~~
