# 验证 Live Activities 与灵动岛的系统约束

- Parent: [灵动岛便签 MVP｜Wayfinder 地图](../../product/wayfinder/map.md)
- Label: `wayfinder:research`
- Status: closed
- Claim: `codex:/root (thread 019fb3c9-6a6b-78e0-9d50-6088381cc7a1)`
- Blocked by: none
- Execution: complete

## Question

在当前 iOS 与带灵动岛的 iPhone 上，MVP 已决定的紧凑态、展开态、锁屏内容、点击跳转、内容更新、持续挂起、设备兼容和授权行为分别受到哪些官方系统约束；哪些产品决定可直接实现，哪些必须调整？

## 可复制执行提示词

~~~text
$wayfinder
$research

请在仓库根目录中，只领取并解决决策票“验证 Live Activities 与灵动岛的系统约束”。

这条消息明确授权本次任务读取 Apple 官方公开资料并进行网络研究；仍然禁止读取项目中的 docs/prototypes/web-prototype/、产品源代码和其他既有资料文件夹。除下面列出的 Wayfinder 文件、新建的研究产物以及必要的 Git 只读状态外，不要探索项目目录。

开始前：

1. 完整读取并遵守 wayfinder 与 research 技能。
2. 只读取：
   - docs/product/wayfinder/map.md
   - docs/product/wayfinder/overview.md
   - docs/decisions/tickets/01-system-constraints.md
3. 核对票据仍为 Status: open、Claim: unassigned、Blocked by: none。
4. 如果任一条件不成立，停止并报告当前状态，不要继续研究。
5. 通过编辑票据，将 Claim 改为当前执行者标识，将 Execution 从 paused by map Notes 改为 active；这是认领动作，必须先于研究。
6. 本次只解决这一张票，不顺带做原型、异常恢复决策或正式开发。

研究执行：

1. 按 research 技能启动一个后台 research 子代理；子代理只研究本票问题，主代理负责状态、审阅与最终收口。
2. 只采用高信任一手来源：Apple Developer Documentation、ActivityKit API reference、Apple Human Interface Guidelines、Apple 官方 WWDC session、Apple 官方示例代码和支持文档。不要用博客、论坛或搜索摘要替代官方结论。
3. 必须核实并分别记录：
   - 当前可用的最低 iOS 版本与带灵动岛的兼容设备范围；
   - Live Activity 的启动、授权、禁用和权限查询机制；
   - 紧凑态、最小态、展开态与锁屏展示的系统结构和布局限制；
   - 点击紧凑态、展开态、锁屏活动后打开 App 及 deep link 的能力；
   - 本地更新、后台更新、远程更新及更新频率限制；
   - App 被杀、进入后台、设备重启时 Activity 与本地状态的实际行为；
   - Live Activity 的最长持续时间、过期、stale、dismissal 等规则；
   - Activity attributes/content state 的数据大小或序列化限制；
   - 240 个用户感知字符是否可以完整传递，以及展开态和锁屏能显示多少属于布局而非数据限制；
   - 锁屏内容能否与展开态一致，以及系统隐私设置可能造成的差异；
   - 用户是否能真正做到“持续挂起直到主动取消”，若不能，产品模型必须如何调整。
4. 对每项结论标记为“官方确认”“由多个官方事实推导”或“仍需真机验证”，不要把推断写成事实。
5. 每个关键结论附官方 URL、文档标题、访问日期；对可能随 iOS 更新漂移的事实注明验证日期和对应系统版本。
6. 将完整研究写入新文件：
   docs/research/activitykit-system-constraints.md
7. 研究文件至少包含：结论摘要、逐项约束表、对既有产品决策的影响、必须调整的决定、真机验证清单、来源索引。
8. 不修改产品代码，不生成实现方案，不替用户决定产品取舍。

验证与收口：

1. 主代理逐条复核研究文件中的关键结论是否都有一手来源，URL 是否对应声明，是否区分事实与建议。
2. 检查研究是否完整回答票据列出的紧凑态、展开态、锁屏、跳转、更新、持续时间、设备和授权八类问题。
3. 如果发现会推翻现有产品决定的系统约束，不直接改写已确认决定；创建新的 wayfinder:grilling 子票，写清冲突问题，并按 create-then-wire 方式补上阻塞关系。
4. 将研究文件链接写入本票的 Resolution 区，给出一段只概括答案、不重复全文的结论。
5. 把票据 Status 改为 closed，Execution 改为 complete；保留 Claim 作为执行记录。
6. 在 Wayfinder 地图的 Decisions so far 追加本票链接和一行结论指针，不把研究细节复制进地图。
7. 检查“确定灵动岛与锁屏的视觉呈现”和“确定挂起失败与系统中断后的恢复规则”是否因此解除阻塞；只更新其 Blocked by 状态，不领取或解决它们。
8. 最终回复必须报告：研究文件路径、最关键的系统约束、哪些决定需要重新讨论、票据与地图的最终状态、验证中仍需真机确认的项目。
~~~

## Resolution

研究资产：[ActivityKit 与灵动岛系统约束研究](../../research/activitykit-system-constraints.md)

Apple 当前官方约束确认：Live Activity 最多活跃 8 小时，不能承诺一直挂起到用户主动取消；静态与动态数据合计不得超过 4 KB，240 个用户感知字符仍需按最终序列化大小校验；expanded 与 Lock Screen 可使用同一份状态，但布局、截断和隐私结果不能保证完全一致。compact/minimal/expanded/Lock Screen 的 deep link、前台本地更新和授权状态查询均有官方 API 支持；强杀、设备重启、首次授权 UI 与极端 Unicode/辅助字体显示仍需真机验证。

研究产生两张未领取的 `wayfinder:grilling` 子票：[重新定义 Live Activity 的挂起生命周期](06-session-lifecycle.md)与[重新确认展开态与锁屏的内容承诺](07-content-commitment.md)。
