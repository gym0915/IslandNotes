# IslandNotes

IslandNotes 让用户维护一条当前便签，并按需将其内容短期展示在系统界面。本文定义产品讨论、规格、代码和测试共同使用的领域语言。

## Language

**Island Notes**：
用户可见的英文产品名称，包括 App display name、界面标题和无障碍文案；内部工程、模块和 Swift 标识继续使用 `IslandNotes`。
_Avoid_: IslandNotes（用户文案）、灵动岛便签

**Workbench**：
承载唯一当前便签及其展示、编辑、入库、Live 和删除动作的主界面与产品工作位置。
_Avoid_: Workspace、首页、编辑器页面

**当前便签**：
当前承载在主界面唯一工作位置中的便签。
_Avoid_: 活跃便签、打开的便签

**源文本**：
用户通过 `Done` 明确提交并由产品原样保存的纯文本，是便签内容的唯一持久事实来源，也是 240 个用户感知字符容量的唯一计数对象；列表前缀、空格和换行均计入容量。
_Avoid_: 渲染文本、格式化正文

**编辑草稿**：
编辑态中尚未通过 `Done` 提交的内存文本；它不更新源文本、SwiftData 或 Live Activity，并可能在 App 进程终止时丢失。
_Avoid_: 自动保存内容、临时源文本

**渲染内容**：
产品根据源文本和已支持的渲染规则生成的只读呈现；当前唯一格式化规则是把列表行显示为圆点列表，该规则同时适用于 Workbench 展示态和 Dynamic Island Expanded。渲染内容不是另一份可独立编辑或保存的便签内容。
_Avoid_: 保存后的正文、第二份正文

**列表行**：
源文本中以 `- ` 开头的行；在展示态渲染为圆点列表，除此之外的 Markdown 风格符号均按普通文字显示。
_Avoid_: Markdown 项、待办项、列表对象

**展示态**：
当前便签以渲染内容供用户阅读、但不直接接受文本输入的界面状态。
_Avoid_: 查看模式、只读便签

**编辑态**：
当前便签以源文本为起点创建编辑草稿并接受输入的界面状态；成功提交后回到展示态。
_Avoid_: Markdown 模式、源码模式

**完成编辑**：
用户点击 `Done` 提交编辑草稿；保存成功后结束编辑会话、回到展示态，并在需要时更新 Live Activity。
_Avoid_: 自动保存、仅收起键盘

**便签库**：
保存非当前便签的次级集合，按最近进入便签库的时间倒序呈现；界面以固定英文、12 小时制显示该时间，依次使用 `Today`、`Yesterday`、星期名或含年份的日期格式。
_Avoid_: 历史记录、归档、回收站

**库中便签**：
位于便签库中、当前不占用主界面工作位置的便签。
_Avoid_: 历史便签、已归档便签

**替换当前便签**：
用户通过库中便签的明确按钮发起的已保存内容无损交换：原当前便签有内容时进入便签库顶部，为空时移除；所选库中便签成为新的当前便签。若存在未提交编辑草稿，替换会直接丢弃该草稿且不二次确认。
_Avoid_: 覆盖当前便签、恢复、点击整行交换

**显示模式**：
用户为 App 选择的持久外观偏好，取值为自动、浅色或深色；它只控制 App 内界面，不控制系统托管的 Live Activity 表面。
_Avoid_: 主题、配色方案

**自动显示模式**：
App 外观实时跟随系统当前的浅色或深色设置。
_Avoid_: 默认主题、未选择

**浅色显示模式**：
App 始终使用浅色外观，不受系统当前外观影响。
_Avoid_: 浅色主题

**深色显示模式**：
App 始终使用深色外观，不受系统当前外观影响。
_Avoid_: 深色主题

**Live 会话**：
当前便签通过 Live Activity 在 Dynamic Island 和锁屏进行短期系统展示的会话；任意时刻最多存在一段有效会话。
_Avoid_: 挂起、固定、永久展示

**Go Live**：
当前没有有效 Live 会话时，用户显式尝试为当前便签启动新会话的动作。
_Avoid_: 挂起、显示在灵动岛

**Live**：
系统确认当前便签存在有效 Live 会话时的产品状态，也是用户可点击以结束该会话的控件标签。
_Avoid_: 挂起中、已固定

**Compact**：
Live 会话活跃时，Dynamic Island 通常使用的紧凑 presentation；IslandNotes 只在左侧显示品牌便签图标。它不是独立的产品或会话状态。
_Avoid_: 紧凑状态、Live 状态

**Minimal**：
存在多个 Live Activities 等情况下，系统可能为 IslandNotes 选择的最小 Dynamic Island presentation；只显示品牌便签图标。它不是独立的产品或会话状态。
_Avoid_: 最小状态、后台状态

**Lock Screen presentation**：
Live 会话在锁屏上的系统展示，使用与 Workbench 和 Dynamic Island Expanded 相同的源文本及圆点列表语义，但由锁屏空间独立决定排版、换行和截断。
_Avoid_: Expanded 副本、锁屏状态

**Move to Note Library**：
把含有有效内容的当前便签放入便签库顶部，并为主界面补入新的空白当前便签；若存在 Live 会话，必须先结束会话。
_Avoid_: 归档、保存、创建新便签

**Delete Note**：
经明确确认后永久删除含有有效内容的当前便签，并为主界面补入新的空白当前便签；若存在 Live 会话，必须先结束会话。
_Avoid_: 移除、清空、放入回收站

## Context and module boundaries

**IslandNotesFeature**：
SwiftUI 的统一行为入口、跨模块用例协调者和最高层功能测试 seam；负责编辑会话、删除确认、用户反馈，以及需要同时协调便签数据与 Live Activity 的用例。它不是经典 MVVM 中为页面属性做一对一转发的 ViewModel。
_Avoid_: WorkbenchViewModel、God ViewModel、App Store

**NoteWorkspace**：
封装 SwiftData 中当前便签、便签库、唯一当前便签不变量及原子内容事务的深模块；不感知 ActivityKit、`isLive` 或 `LiveActivityControlling`。
_Avoid_: NoteRepository、PersistenceManager、WorkspaceStore

**LiveActivitySession**：
封装 Live Activity 启动、更新、防抖、结束屏障和对账的深模块；以 ActivityKit 实际枚举结果作为 Live 会话事实来源，并继续通过 `LiveActivityControlling` 连接真实 adapter 与测试 fake。
_Avoid_: LiveActivityManager、LiveActivityViewModel、持久化 Live 布尔值

**AppearanceSettings**：
封装显示模式及其持久化的模块，不持有页面导航或便签业务状态。
_Avoid_: ThemeManager、SettingsViewModel

**AppRouter**：
只管理 Note Library 与 Settings 两个 App 级 sheet，并处理 deep link 回到 Workbench；同一时刻最多呈现一个 App 级 sheet。它不管理 More Menu 展开、编辑草稿、删除确认、便签事务、Live 会话或错误消息。
_Avoid_: NavigationManager、把业务状态放进 Router
