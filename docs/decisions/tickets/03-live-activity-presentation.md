# 确定灵动岛与锁屏的视觉呈现

- Parent: [灵动岛便签 MVP｜Wayfinder 地图](../../product/wayfinder/map.md)
- Label: `wayfinder:prototype`
- Status: open
- Claim: unassigned
- Blocked by: none

## Question

在系统允许的范围内，紧凑态只显示什么视觉标记，expanded 与 Lock Screen 如何分别排版同一条当前便签、表达各自截断并清楚传达系统不保证全文可见，才能符合用户已经确认的内容契约与交互边界？

## 可复制执行提示词

~~~text
$wayfinder
$prototype
$frontend-design
$domain-modeling

请在仓库根目录中，只领取并解决决策票“确定灵动岛与锁屏的视觉呈现”。

这是一个已由技术研究与内容承诺决策解除阻塞的 HITL UI prototype 票。仍须核对两张上游票及其 Resolution 资产，不能把网页模拟器当成系统真实能力证明。

开始前：

1. 完整读取并遵守 wayfinder、prototype、prototype/UI.md、frontend-design 与 domain-modeling。
2. 先读取：
   - docs/product/wayfinder/map.md
   - docs/product/wayfinder/overview.md
   - docs/decisions/tickets/03-live-activity-presentation.md
3. 再检查“验证 Live Activities 与灵动岛的系统约束”是否 Status: closed，并读取：
   - docs/decisions/tickets/01-system-constraints.md
   - 该票 Resolution 链接的研究文件
4. 检查“重新确认展开态与锁屏的内容承诺”是否 Status: closed，并读取：
   - docs/decisions/tickets/07-content-commitment.md
   - 该票 Resolution 链接的 docs/decisions/records/system-presentation.md
5. 若研究票或内容承诺票未关闭、任一 Resolution 产物不存在，或本票 Blocked by 仍未解除，停止并报告阻塞，不要认领、不制作。
6. 若本票为 Status: open、Claim: unassigned 且已解除阻塞，先将 Claim 改为当前执行者标识。
7. 不读取 docs/prototypes/web-prototype/、产品源代码或其他未列出的项目文件。
8. 本次只判断系统展示视觉，不实现正式 ActivityKit/SwiftUI 代码，不解决异常恢复。

原型要求：

1. 创建独立 throwaway 原型目录：
   docs/prototypes/dynamic-island-lock-screen/
2. 使用单一路由和 ?variant=A、B、C，制作 3 个结构与排版策略明显不同的视觉方案；提供 prototype 标准的浮动切换器和一个命令运行。
3. 原型必须清楚标注“系统展示模拟，不代表技术可行性证明”，所有尺寸与区域规则以研究票确认的系统约束为准。
4. 每个方案同时展示并可切换：
   - 紧凑态：不显示便签文字，只显示 App 或挂起状态的视觉标记；
   - expanded：显示当前便签文字，无快捷操作按钮；
   - Lock Screen：与 expanded 取自同一条当前便签、使用同一内容状态并保持语义与信息顺序一致，但允许排版、换行、截断位置和实际可见范围不同；
   - 点击进入当前便签工作台的视觉/交互说明；
   - 两套 presentation 文字空间不足时各自截断，不暗示 240 字全文完整可见。
5. 内置至少 6 组压力样例：短中文、长中文、英文、手动换行、Emoji、恰好 240 个用户感知字符。
6. 每个方案都要展示浅色与深色环境，并覆盖研究确认的实际系统区域，不虚构系统不允许的按钮、滚动、手势或布局。
7. 三个方案必须在标记语义、文本层级、对齐方式和截断提示策略上不同，不能只是颜色不同。
8. 不加入完成、取消挂起、编辑等灵动岛内操作；这些已明确超出范围。

验证：

1. 启动并给出本地 URL、A/B/C 直接链接和启动命令。
2. 对照研究文件逐项核查每个模拟状态，没有违反区域、生命周期、点击和内容约束。
3. 用浏览器截图记录每个方案的紧凑态、展开态、锁屏态及 240 字符压力态。
4. 检查 expanded 与 Lock Screen 使用同一条当前便签和同一内容状态，但不把相同排版、相同截断位置或全文完整可见当作验收条件；紧凑态不泄露便签文字。
5. 检查浅色/深色对比度、Dynamic Type 放大后的可读性方向和 VoiceOver 所需语义说明；无法由网页原型验证的内容明确列为真机验证项。
6. 任何与官方约束冲突的产品决定，不能在本票内静默修改；创建新的 wayfinder:grilling 决策票并补阻塞关系。

HITL 收口：

1. 原型完成后保持票据 open，不自行选定方案。
2. 向用户展示三个方案和系统约束差异，一次只问一个选择问题，等待用户实际评审。
3. 用户确认方案或组合方向后，把结论、理由、截图和原型路径写入本票 Resolution。
4. 将 Status 改为 closed，在地图 Decisions so far 追加本票链接与一行结论。
5. 原型保持 throwaway，不合入生产代码；如果存在 Git，按 prototype 技能将完整原型留在隔离的 throwaway 分支或明确记录未使用 Git 的原因。
6. 最终回复报告：获选方向、研究约束如何影响选择、原型路径、验证与真机待验项、票据及地图状态。
~~~
