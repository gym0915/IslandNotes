# 确定当前便签工作台与便签库的页面交互

- Parent: [灵动岛便签 MVP｜Wayfinder 地图](../../product/wayfinder/map.md)
- Label: `wayfinder:prototype`
- Status: open
- Claim: codex:019fb7dd-a3a9-74e2-ad34-56c18087ec1c
- Blocked by: none

## Question

什么样的低成本交互原型，能让用户确认当前便签编辑器、挂起与取消挂起、放入便签库、删除、圆形字符进度、便签库入口和点击交换在同一套页面结构中足够清晰且不互相干扰？

## 可复制执行提示词

~~~text
$wayfinder
$prototype
$build-ios-apps:swiftui-ui-patterns
$build-ios-apps:ios-debugger-agent
$build-ios-apps:ios-simulator-browser
$product-design:audit
$browser:control-in-app-browser
$domain-modeling

请在仓库根目录中，只领取并解决决策票“确定当前便签工作台与便签库的页面交互”。

这是一个 HITL 原生 UI prototype 票：目标是让用户在现有 HTML 视觉基线之上，通过 iPhone Simulator 中可真实操作的 SwiftUI 原型比较并选择工作台与便签库交互，不是开发正式 App。HTML 只作为 Baseline O，不再作为候选方案的实现技术。先核对已有基线审计，再制作原生受控候选；不得跳过基线、从零随意重设计，也不得把 SwiftUI 原型冒充生产代码。

开始前：

1. 完整读取并遵守 wayfinder、prototype、prototype/UI.md、build-ios-apps:swiftui-ui-patterns、build-ios-apps:ios-debugger-agent、build-ios-apps:ios-simulator-browser、product-design:audit、product-design 的 critical-overrides、browser:control-in-app-browser 与 domain-modeling。
2. 只允许读取：
   - docs/product/wayfinder/map.md
   - docs/product/wayfinder/overview.md
   - docs/decisions/tickets/02-workbench-prototype.md
   - docs/prototypes/web-prototype/island-notes-ios-prototype.html
   - docs/audits/2026-07-31-html-prototype/report.md
   - 上述审计目录中的编号截图
3. 除 `docs/prototypes/web-prototype/island-notes-ios-prototype.html` 外，不读取 `docs/prototypes/web-prototype/` 中任何文件；不读取现有产品代码或其他项目文件夹。
4. `docs/prototypes/web-prototype/island-notes-ios-prototype.html` 是只读视觉与问题基线，绝对不能修改。
5. 已有 `docs/prototypes/current-note-workbench/` HTML 候选已被用户否决为评审介质：保留为历史探索，不继续修改、不作为候选，也不把其视觉实现迁移到 SwiftUI。
6. 核对票据仍为 Status: open、Claim: unassigned、Blocked by: none；否则停止并报告。若票据已经由同一执行会话领取且 Claim 与当前执行者一致，则保持 Claim 不变并继续；不得重复领取或改写 Claim。
7. 核验无误后，只有在 Claim 尚为 unassigned 时才先改为当前执行者标识，再开始操作和制作。
8. 本次只解决工作台与便签库交互；灵动岛和锁屏只制作与本票状态联动所必需的最小示意，不探索最终视觉，不接入 ActivityKit，不做正式 iOS 实现。

阶段一：核对 Baseline O

1. 阅读已有审计报告与本轮 Baseline O 编号截图，确认其已经覆盖初始页、编辑、多行文字、开启 Live、紧凑态、更多菜单、便签库、点击旧便签、删除、设置、241 字符和真实长按尝试。
2. 只有在审计证据缺失、文件变化或截图与报告矛盾时，才通过本地 HTTP 与 in-app Browser 补跑缺失步骤；不得为了形式重复已经有当前证据的完整流程。
3. 保留已记录的长按验证缺口；不得通过改 class、调用页面函数或篡改状态伪造展开态。
4. 输出一张简洁的基线结论表，分为“保留的视觉语言”“必须纠正的产品行为”“本次无法验证的缺口”。

视觉基线：

1. 保留现有原型的总体气质：黑白为主、弱绿色强调、大号粗体、圆角纸张/卡片表面、柔和空间层次、接近 Apple 的克制感。
2. 保留“首页只聚焦当前便签”“次级入口收敛”“灵动岛紧凑态不显示正文”的原则。
3. 允许候选方案调整布局、层级和操作位置，但除非用户明确要求，不得改成与基线无关的品牌、配色或装饰风格。
4. 不把右侧营销文案、Widget 预览、设置页或虚拟键盘外观视为必须继承的视觉基线。

原生 SwiftUI 原型要求：

1. 在新目录创建纯 throwaway Swift Package：
   docs/prototypes/current-note-workbench-ios/
   包含可导入的 `CurrentNoteWorkbenchPrototype` target、`#Preview` 入口、README 与 screenshots；不得创建或修改正式 App 工程、scheme、签名、entitlement 或生产代码。
2. 原型最低目标为 iOS 17，使用 SwiftUI 与原生 SF Symbols，不引入第三方依赖。业务状态只保存在原型根视图的内存状态中，重新启动 Preview host 即重置。
3. 在同一个 SwiftUI 原型根视图中提供 A、B、C 三个候选，并用固定在底部、明确标注“仅供评审”的原生切换器切换。另为 A/B/C 提供独立命名的 `#Preview`，便于直接跳到指定方案；切换方案不得重置共享业务状态。
4. A/B/C 必须是对已发现问题的三种受控回答：在信息层级、主要操作位置和便签库进入方式上真正不同，不能只是换颜色；也不能为了“不同”而背离现有视觉语言或已确认产品契约。
5. 首页从首次启动起始终只有一个空白、可直接输入的当前便签纯文字编辑器；当前便签本身就是编辑器，不存在预览态、单独编辑入口、保存按钮、完成按钮或 `DONE`。
6. 使用已确认产品词汇：“挂起 / 取消挂起”“便签库 / 放入便签库”。产品 UI 不使用“Live”作为主要动作名，不使用“归档”，不引入完成状态。
7. 文本原样保留中英文、空格、标点、手动换行和 Emoji；不得解析 Markdown、自动生成列表或重新编号。
8. 使用 Swift `String` 的扩展字素簇语义实现 240 个用户感知字符上限：
   - 汉字、英文字母、数字、标点、空格、换行各计 1；完整显示的 Emoji（包括组合 Emoji）计 1；
   - 达到 240 后停止接受新增字符，但仍允许删除和替换；
   - 粘贴超限时只保留可容纳部分；
   - 超限时轻提示“最多 240 个字符”；
   - 圆形进度默认只表达容量，点击后临时显示“已输入”和“还可输入”；
   - 圆环可通过 VoiceOver 聚焦，并提供已用、上限和剩余的辅助文案。
9. 内容为空或只有空白字符时，挂起、放入便签库和删除必须是真正 disabled；编辑器和便签库入口仍可用。
10. 当前便签可挂起和取消挂起；挂起后继续编辑会更新最小灵动岛示意。放入便签库或删除时自动取消挂起。
11. 放入便签库后内容保留在库中，当前槽位自动补为空白；便签库按最近入库时间倒序。
12. 删除属于不可恢复操作，必须先出现原生二次确认，明确说明删除后无法恢复；确认后当前槽位变为空白。
13. 便签库只浏览和恢复，不提供编辑、挂起或删除。点击旧便签立即交换，不经过预览或二次确认：
    - 若当前便签有内容，它先进入便签库顶部；
    - 被点击旧便签从库中移除并成为当前便签；
    - 若当前便签正在挂起，交换前先取消挂起；
    - 新当前便签不自动挂起；
    - 若当前便签为空，不把空白内容放入便签库。
14. 移除 Widget、主题选择和其他设置范围。只实现跟随系统的浅色/深色与 Dynamic Type 适配，不提供颜色、字体、字号或主题自定义。
15. 提供真实的中英文、换行、组合 Emoji、空白字符、239/240/241 字符和多条旧便签样例。
16. 原型加入仅供评审的原生 state inspector（折叠面板或 sheet），显示 currentNote、isPinned、library、graphemeCount 与最近动作；它不得遮挡候选方案的核心控件。
17. 不做网络请求、数据库、账号、iCloud、通知、真实 Live Activity 或生产级错误处理。
18. 虽然代码是 throwaway，视觉可判断性本身属于本票问题：必须使用原生间距、语义色、Material、系统字体层级、SF Symbols、安全区与标准转场，达到足以评审的完成度。“Throwaway”不是粗糙、错位或遮挡的理由，但也不得为此建立生产级架构。

验证：

1. 使用 `build-ios-apps:ios-simulator-browser` 的 SwiftUI Preview Workflow：选择一个已 boot 的 iPhone Simulator，通过 `swiftui-preview-browser.mjs` 启动 package preview，再用 `serve-sim` 将同一 UDID 映射到 in-app Browser。若没有已 boot 的 Simulator，停止并请用户先启动；不得擅自用其他设备或浏览器替代。
2. 给出 Swift Package 路径、package target、Preview 启动命令、Simulator UDID、镜像 URL，以及 A/B/C 的独立 Preview 名称；保持 Simulator 镜像打开供用户评审。
3. 对 Baseline O 与 A/B/C 使用同一套规范状态序列，候选方案至少逐一截图：
   - 首次启动的空白编辑器；
   - 输入中英文、多行和组合 Emoji；
   - 点击圆环显示已输入/还可输入；
   - 第 240 个字符；
   - 第 241 个字符被拒绝及轻提示；
   - 挂起、挂起中编辑、取消挂起；
   - 放入便签库后回到空白槽位；
   - 便签库倒序列表；
   - 当前有内容且已挂起时点击旧便签完成交换；
   - 删除确认与确认后的空白槽位；
   - 空白操作禁用；
   - 系统浅色与深色。
4. 使用 `build-ios-apps:ios-debugger-agent` 的 `describe_ui`、tap、type 与 screenshot 能力检查状态，而不只看截图：验证被选旧便签确实离库、原当前便签确实入库置顶、交换后确实取消挂起、新便签确实未自动挂起。
5. 验证字符计数至少覆盖汉字、换行、普通 Emoji、家庭/肤色/ZWJ 组合 Emoji、粘贴超限，以及达到上限后的删除和替换。
6. 验证重新启动 Preview host 后业务状态重置，切换 A/B/C 时业务状态保持；不得使用 UserDefaults、SwiftData、Core Data、文件或其他持久化保存业务状态。
7. 验证三个方案结构确实不同；若只是换皮或微调间距，重做相似方案。
8. 在至少一个标准 iPhone 视口和一个较窄 iPhone 视口检查：无横向溢出，240 字符不破坏顶部与操作区，按钮目标清晰，软件键盘与 VoiceOver 焦点可用，原型切换器不遮挡产品控件。
9. 检查圆环辅助名称、按钮 disabled 语义、Dynamic Type 基础重排与系统浅色/深色；记录 Simulator 截图不能证明的 VoiceOver 和真机行为，不得声称完整无障碍合规。
10. README 提供 Baseline O 与 A/B/C 对照矩阵，至少比较：信息层级、主要操作位置、便签库入口、字符反馈、空白状态、删除确认、交换反馈、窄屏长文本、原生键盘行为、优点、代价。
11. 保存每个方案同状态、同 Simulator、同外观的关键截图，并在 README 中写出复现路径。截图必须逐张打开检查，拒绝空白、裁切、错误状态、键盘遮挡、控件重叠或加载中的截图。

HITL 收口：

1. 原型完成后不要自行选择赢家，也不要关闭票据。
2. 保持 Simulator 镜像打开，向用户展示 Baseline O 对照矩阵、A/B/C Preview 入口、同状态截图和三个方案的核心差异；只问一个决定性问题：选择 A、B、C，还是组合哪些部分；等待用户亲自评审。
3. 用户尚未确认时保持 Status: open 和 Claim 不变。
4. 用户确认后，将选择、理由和被否决方案写入本票 Resolution，并链接 Swift Package 与截图。
5. 将 Status 改为 closed，在 Wayfinder 地图 Decisions so far 追加本票链接和一行结论。
6. 如果用户的选择使新的问题变得明确，先创建新票，再补阻塞关系；不要顺手开发正式界面。
7. 最终回复报告：获选方案、Swift Package 路径与 Preview 运行命令、Simulator 验证结果、票据和地图状态，以及下一张已解除阻塞或仍可领取的票。
~~~
