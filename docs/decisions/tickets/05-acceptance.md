# 锁定 MVP 验收边界与交付规格

- Parent: [灵动岛便签 MVP｜Wayfinder 地图](../../product/wayfinder/map.md)
- Label: `wayfinder:grilling`
- Status: open
- Claim: unassigned
- Blocked by: [确定当前便签工作台与便签库的页面交互](02-workbench-prototype.md), [确定灵动岛与锁屏的视觉呈现](03-live-activity-presentation.md), [确定挂起失败与系统中断后的恢复规则](04-failure-recovery.md)

## Question

综合已确认的产品模型、页面原型、系统约束和异常恢复规则，哪些可观察行为构成 MVP 的完成标准，哪些内容明确留到后续版本，从而形成可直接交给设计与开发的最终规格？

## 可复制执行提示词

~~~text
$wayfinder
$grilling
$domain-modeling

请在仓库根目录中，只领取并解决决策票“锁定 MVP 验收边界与交付规格”。

这是地图的最终收束票。必须等所有前置票关闭后，才能把分散决策整理成一份可交给设计与开发的 MVP 产品规格；不要在前置答案不完整时用猜测补洞。

开始前：

1. 完整读取并遵守 wayfinder、grilling 与 domain-modeling。
2. 读取：
   - docs/product/wayfinder/map.md
   - docs/product/wayfinder/overview.md
   - docs/decisions/tickets/05-acceptance.md
3. 核对并读取以下三张前置票的 Resolution 及其直接链接产物：
   - docs/decisions/tickets/02-workbench-prototype.md
   - docs/decisions/tickets/03-live-activity-presentation.md
   - docs/decisions/tickets/04-failure-recovery.md
4. 同时读取已关闭的系统约束研究票及研究文件，作为技术事实来源：
   - docs/decisions/tickets/01-system-constraints.md
5. 如果任一前置票不是 closed、产物缺失，或本票仍有 Blocked by，停止并列出缺失项，不认领、不写规格。
6. 若本票为 Status: open、Claim: unassigned 且已解除全部阻塞，先把 Claim 改为当前执行者标识。
7. 不读取 docs/prototypes/web-prototype/、产品代码或其他未列出的项目文件；本次不进入实现。

规格产物：

1. 新建：
   docs/product/mvp-spec.md
2. 规格必须清晰区分“已确认产品决定”“Apple 系统约束”“仍需真机验证”，不得混写。
3. 至少包含：
   - 文档状态、目标、用户价值和非目标；
   - 领域词汇：当前便签槽位、当前便签、挂起便签、便签库、紧凑态、展开态；
   - 信息架构与页面职责；
   - 当前便签、挂起状态、便签库之间的状态模型和不变量；
   - 首次启动、编辑、自动保存、240 字符计数、超限粘贴、圆形进度；
   - 挂起、取消挂起、入库、删除、库内点击交换的完整流程；
   - 灵动岛紧凑态、展开态、锁屏态及点击回 App 的展示契约；
   - 本地数据边界、设备范围、浅色/深色与无障碍要求；
   - 权限、失败、中断、重启和状态不一致的恢复矩阵；
   - MVP 明确不做的内容；
   - 可观察、可验证的验收标准；
   - 真机验证清单；
   - 决策追溯表：每一章节链接到原始决策票或研究/原型资产。
4. 验收标准优先使用 Given / When / Then，至少覆盖：
   - 空白便签；
   - 有效输入与自动保存；
   - 239、240、241 字符及超限粘贴；
   - 中文、英文、换行、Emoji 的用户感知字符计数；
   - 挂起与取消；
   - 挂起中编辑并同步；
   - 入库后产生空白当前便签；
   - 删除二次确认；
   - 便签库排序和点击交换；
   - 当前便签与挂起便签不分离；
   - 紧凑态不显示文字；
   - 展开态与锁屏显示一致且允许截断；
   - App 重启、设备重启、系统结束活动与失败恢复；
   - 不支持设备和权限不可用。
5. 不写工程任务拆分、技术架构或生产代码；本票产物是产品规格与验收契约。

一致性验证：

1. 建立决策追溯表，逐条检查“灵动岛便签-MVP-Wayfinder.md”中的确认项都进入规格或被明确判定过时。
2. 搜索并消除以下矛盾：
   - 不得出现“新建便签”按钮；
   - 不得让便签库直接编辑、挂起或删除；
   - 不得让当前便签与挂起便签是两条不同便签；
   - 不得把便签写成待办或加入“完成”；
   - 不得加入地图 Out of scope 中的功能；
   - 不得承诺 Apple 系统不支持的持续时间或后台更新行为。
3. 检查所有链接存在、所有票据状态与阻塞关系一致、地图 Decisions so far 只做索引不重复决策。
4. 将无法从已有材料确认的内容列为“待决”，不要自行补齐；使用 grilling 一次只问用户一个问题，并给出推荐答案。
5. 用户明确确认规格无误之前，保持票据 open。

收口：

1. 用户确认规格后，在本票新增 Resolution，链接最终规格并概括验收边界。
2. 将本票 Status 改为 closed，在地图 Decisions so far 追加本票链接。
3. 检查地图是否还有 open 子票或指向 Destination 的 Not yet specified：
   - 若有清晰的新问题，创建新票并接线，地图保持 open；
   - 若仅是已明确排除的后续工作，移入 Out of scope；
   - 若没有剩余问题，地图 Status 改为 closed，并声明 Wayfinder 阶段完成、可以进入正式设计与开发规划。
4. 最终回复报告：规格文件路径、已覆盖的验收范围、剩余真机验证项、所有票据状态、地图是否关闭及下一步交接建议。
~~~
