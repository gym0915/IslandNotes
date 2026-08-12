# 锁定 Workbench 的屏幕布局与安全区契约

- Parent: [Island Notes 高保真 UI 一致性与组件化修正地图](../map.md)
- Type: grilling
- Status: resolved
- Claim: codex:/root
- Blocked by: 01

## Question

Workbench 在非编辑、编辑、Live、错误提示、窄屏与最大辅助字号下，Header、Note Surface、Character Progress、Done 和 Workbench Action Dock 分别属于滚动内容、固定屏幕区域还是键盘上方区域；它们应使用什么对齐、间距、伸缩和安全区规则，才能既复刻 PNG，又不在系统自适应场景中遮挡或漂移？

## Answer

### 决定摘要

Workbench 锁定为一个屏幕级 scaffold，不再是一条由内容高度决定位置的滚动列。非编辑态为“安全区内固定 Header + 占用剩余空间的 Note Surface + 屏幕底部安全区上方的 Workbench Action Dock”；编辑态把 Dock **从布局树移除**，用键盘上方的 Editing Commit Bar 取代。Character Progress 是 Note Surface 内部的右下角配件，不是独立根区域。临时反馈和删除确认都是 overlay，不参与主骨架测量。

本答案使用以下标记区分权威性：

- **P（Prototype）**：PNG 及 ADR 0002 / 0007 直接规定，默认尺寸和主结构必须保持。
- **A（Adaptive）**：iOS 为安全区、键盘、窄屏、Dynamic Type 和 VoiceOver 允许或要求的降级。
- **F（Forbidden）**：即使布局引擎能自动产生，也不能接受的结果。

### 坐标系与总体不变量

- 画布背景可以延伸到全屏；除全屏 scrim 外，所有内容和交互目标都以当前 safe-area rect 为坐标系。禁止为某一型号硬编码状态栏、Dynamic Island、Home Indicator 或键盘高度。
- 水平内边距 **P 理想值 24 pt**；窄屏或 Accessibility 可降到 **A 最小 16 pt**，不得更小。默认 iPhone 16 Pro 402 pt 视口下，Note Surface 与底部区域都使用约 354 pt 内容宽度。
- 顶部安全区到 Header 内容的距离为 **P 16 pt**；底部控件的可视底边为 `screenHeight - bottomSafeAreaInset - bottomPadding`，`bottomPadding` **P 理想 24 pt，A 最小 16 pt，最大 32 pt**。
- 空闲高度的压缩顺序固定：先把 Header–Surface 空白从 64 pt 压到 24 pt，再把 Surface–底部区域间距从 32 pt 压到 16 pt，最后才压缩 Note Surface 可见高度并让其内容滚动。Header 和底部交互控件不小于 44 pt，也不通过移出首屏来解决空间不足。
- Light / Dark 只替换语义颜色、材质、边框和阴影 token；**所有尺寸、对齐、槽位、换行和 z-order 必须同构**。

### 根区域契约

| 区域 | 类型与对齐 | 安全区 | 最小 / 理想 / 最大 | 间距与遮挡 |
| --- | --- | --- | --- | --- |
| Header | **固定 / 内在高度**。默认为屏幕水平居中的 `Island Notes`，More 位于尾随侧；不再为 `Not Live / Live` 保留第二行。 | 完全在顶部安全区内，顶距 16 pt。 | 高度最小 44 pt，默认理想 48 pt，最大为标题两行的内在高度；More 目标最小 44×44，理想 48×48。 | 展示态到 Note Surface 理想 64 pt（两个 32 pt token），最小 24 pt；编辑态为 24 pt，可压到 16 pt。z = 0。 |
| Note Surface | **可伸缩外框 + 内部滚动内容**。外框左右填满内容宽度，正文顶部左对齐。外框不随正文内容增长。 | 不跨越顶部安全区，不进入底部 inset 或键盘。 | 宽度：窄屏 320 pt 视口时最小可用 288 pt，402 pt 时理想约 354 pt，最大为 safe width - 32 pt。高度：非编辑 A 最小 240 pt，402×874 的 P 理想约 520–560 pt，最大为分配后的全部剩余高度；编辑 A 最小 160 pt，理想/最大为键盘与 Commit Bar 留下的全部剩余高度。 | 内边距 P 24 pt，A 可降为 16 pt。非编辑时与 Dock 理想 32 pt，最小 16 pt。z = 0；不允许覆盖 Dock / Commit Bar。 |
| Character Progress | **Note Surface 内部 overlay**，永远为 Surface 右下角对齐，展开详情位于 ring 的 leading 侧。它不占根布局的一行。 | 跟随 Note Surface，不单独处理 safe area。 | ring 视觉直径 P 34 pt，整个可点区最小 44×44 pt；详情胶囊默认单行内在宽度，最大不超过 Surface 内宽减去 ring 和 8 pt 间距。 | 右/底内距 P 24 pt，A 16 pt；详情与 ring 间距 8 pt。z = 1；正文/编辑器必须为它留出 bottom/trailing content inset。 |
| Editing Commit Bar | **固定底部区域，仅编辑态存在**。`Done` 是水平填满的单一主操作，不在 Note Surface 里。 | 由键盘 safe area 提供位置；键盘可见时按钮底边距键盘顶部 P 16 pt（A 最小 8 pt），键盘未显示时改用 bottom safe area。 | 按钮高度最小 44 pt，P 理想 48 pt；bar 总高最小 60 pt，理想 80 pt，最大 96 pt。 | 左右同 Surface；按钮上下理想各 16 pt。z = 10。不能被键盘遮挡。 |
| Workbench Action Dock | **固定底部区域，仅非编辑态存在**。一个水平三槽位复合控件：Move（leading icon）→ Live（center pill）→ Delete（trailing icon）。 | 必须由 bottom safe-area inset 定位，不从 Surface 或正文坐标推导 Y 值。 | 两侧 icon target 最小 44×44 pt，P 理想 48×48 pt；中间控件高度最小 44 pt，理想 48 pt，默认理想宽约 152 pt、最小标准字号宽 112 pt、最大使用两侧槽位后的剩余宽度。Live indicator 只保留 18×18 pt 对齐槽（A 16–20 pt）；内部图形由票据 03 决定。 | 槽位间 P 16 pt，A 最小 8 pt；底距安全区 P 24 pt，A 16 pt。z = 10。禁止被 Surface 内容推动。 |
| Feedback | **临时 overlay**，就近锚定在当前底部操作区域上方：非编辑对 Dock，编辑对 Commit Bar。 | 始终在水平和底部 safe area 内，不进入键盘。 | 默认为组件库中的单行胶囊；最小高度约 32 pt，理想为内在尺寸，最大宽度为 safe width - 32 pt，Dynamic Type 下允许多行而不截断。 | 与 Dock / Commit Bar 上边缘最小 8 pt。z = 20。它不改变 Header、Surface 外框或底部区域的 frame。 |
| Delete Confirmation | **全屏阻断 overlay**：scrim 覆盖全屏，确认卡底部居中。背景 Workbench 冻结，不重排。 | scrim 忽略 safe area；卡片和按钮必须在 safe area 内，卡底距底部安全区 P 16–24 pt。 | 宽度最小为窄屏 safe width - 32 pt，理想为 safe width - 32 pt，iPhone 范围内最大 430 pt；高度内在，最大不超过 safe height - 48 pt。两个按钮各最小 44 pt，理想 48 pt。 | scrim z = 40，dialog z = 41。背景所有区域停止 hit testing 并从 VoiceOver 树隐藏；反馈若与确认同时存在，放入 dialog 内，不叠加第二个全局胶囊。 |

### 非编辑态

1. Dock 必须使用屏幕底部 safe-area inset；其位置公式是 `dockBottom = safeAreaBottom - 16...24 pt`，而不是 `noteSurface.maxY + spacing`。默认高度、正文行数、Character Count 展开和 feedback 都不得改变该 Y 坐标。
2. Header 和底部 inset 完成测量后，Note Surface 获取两者之间扣除规定间距后的全部剩余高度。`310 pt` 只能是旧实现证据，不是新契约的高度或 `minHeight`。
3. 展示内容、空态文案和 Character Progress 都在 Note Surface 内。当 240 个字符在窄屏或辅助字号下超过可见高度时，只滚动 Surface 的正文层；Header、Surface 外框和 Dock 不滚动。
4. Feedback 不在主 `VStack` 中插入新一行。它出现/消失时 Header、Surface frame 和 Dock 不动。若它与 Surface 右下角内容冲突，允许的 A 降级只是增加正文的临时 bottom content inset，或在 Surface 内把 Character Progress 上移一个反馈高度；不得推动 Dock。

### 编辑态

1. 根布局保持默认 keyboard safe-area 行为，不对整个 Workbench 使用 `.ignoresSafeArea(.keyboard)`。键盘出现后，它先改变可用底边；Editing Commit Bar 在该底边上方测量，Note Surface 再使用剩余高度。
2. Workbench Action Dock 在 `isEditing == true` 时不参与测量、绘制、hit testing 或 accessibility tree；不接受 opacity 0、offset 到屏外、被键盘遮住或 `hidden()` 但仍保留布局空间。
3. `Done` 在 Surface 外、键盘上方保持水平整宽；Character Progress 仍在 Surface 右下角，统计 editing draft，不随 `Done` 移到 Commit Bar。
4. `MarkedTextEditor` / `UITextView` 自身是编辑滚动容器。当 Surface 被键盘压缩或选区改变时，编辑器必须把当前 caret/selection 滚到可见 rect，并在底部/尾随内容 inset 中避开 Character Progress。禁止再用一层整页 `ScrollView` 与 `UITextView` 争夺键盘和光标滚动。
5. 保存失败时编辑态和键盘保留；feedback 锚定在 Commit Bar 上方。它可以改变 editor 的内部可见 rect，但不改变 Header、Surface 外框或 `Done` 的屏幕锚点。

### 窄屏、Accessibility XXXL 与文本规则

- 可换行：空态 helper copy、展示/编辑正文、feedback、Delete Confirmation 标题和说明；标题 `Island Notes` 只在窄屏 + Accessibility 无法与 More 同行容纳时允许最多两行；Character Count 详情无法单行容纳时可最多两行，或通过内部 `ViewThatFits` 改为 detail 在 ring 上方的紧凑排列。
- 优先保持单行：`Done`、`Live`。`Go Live` 在最大辅助字号下可最多两行，但 indicator 和文本仍在同一个中心 pill 内。Move 和 Delete 在 Dock 中继续是图标槽位，完整名称作为 accessibility label，不把长文字强行画进新的纵向大按钮。
- 必须保持至少 44×44 pt 的控件：More、Character Progress、Move、Live、Delete、Done、Delete Confirmation 的 Delete Note 和 Cancel。视觉图形可小于 44 pt，但命中区不可。
- Dock 的降级顺序为：水平内边距 24→16，槽位间距 16→8，中间 pill 的水平内边距 16→8，必要时仅让 `Go Live` 在 pill 内换两行。**Dock 不允许三个纵向大按钮，不允许横向滚动，不允许将 Delete 移出首屏。**
- 三个 Dock 动作在视觉和 VoiceOver 中的顺序始终是 **Move to Note Library → Go Live / Live → Delete Note**。禁止为适配宽度交换顺序或使用与视觉顺序不同的 accessibility sort priority。
- Accessibility XXXL 下允许 Header 增高、Surface 内容滚动、中间 pill 增高和确认文案换行；不允许限制系统字号、文字不可见截切、触控目标缩小，或让 Dock/Delete 只能靠整页滚动才出现。

### 逐状态布局矩阵

| 状态 | P：原型规定 | A：iOS 允许的自适应 | F：明确禁止 |
| --- | --- | --- | --- |
| Empty | 单行 Header；大型 Note Surface 展示 helper copy 和右下 ring；三槽 Dock 在底部安全区上方，动作为 disabled 但槽位不消失。 | helper copy 换行；垂直间距按压缩顺序缩小；Surface 内部必要时滚动。 | 使 Dock 跟随空态文案或卡片高度上浮；隐藏 Delete 槽位；增加头部 `Not Live` 第二行。 |
| Note | 渲染内容顶部左对齐；Surface 外框与 Empty 同几何；Dock 位置不变。 | 240 字符在大字号下转为 Surface 内部滚动。 | 正文增长推动 Surface 或 Dock；把三个动作当 Tab Bar 或页面按钮。 |
| Character Count | detail 与 ring 是 Surface 右下角的同一内部组件；Surface 和 Dock 不动。 | detail 可换两行或在 Surface 内改为上下紧凑排列；内容 inset 随组件占位增大。 | 把 detail 放成 Surface 与 Dock 之间的根布局行；展开时推动 Dock。 |
| Editing | source editor 在 Surface；ring 仍在右下；整宽 `Done` 位于 Surface 外和键盘上方；Dock 不存在。 | 键盘压缩 Surface；编辑器滚动保持 caret 可见；中文/日文 marked text 完成后再限制字符。 | `Done` 放在卡内；Dock 留在键盘后；整个 Workbench 随键盘乱滚。 |
| Live | 与 Note 完全同几何；只替换中心槽的 `Go Live / Live` 内容。Live indicator 使用固定 18 pt 对齐槽。 | 中心 pill 在大字号下可增高，但两侧槽位不变序。 | 因 Live 改变 Surface 或 Dock 位置；增加 Header 状态行；在本票据预先决定 indicator 的填充、描边、颜色或动画。 |
| Delete Confirmation | 全屏 scrim + 底部确认卡；背景几何保持不变。 | 标题/说明换行；极端高度下只让说明/feedback 内容滚动，Delete Note 和 Cancel 固定可见。 | 把确认卡插入根 `VStack`；将确认按钮或 Cancel 裁切/移出首屏；让背景仍可交互或被 VoiceOver 读取。 |
| 临时反馈 | 使用原型 Hints & Messages 的胶囊语言，靠近触发动作。 | 多行、在 Dock / Commit Bar 上方避障，并通过调整 Surface 内部 content inset 保证正文/光标可见。 | 出现时推动 Dock、Done 或整个 Surface；覆盖任何可交互底部控件。 |
| 窄屏 | 仍是同一 Header、Surface 和三槽位 Dock。 | 水平边距/间距降到 16/8 pt；Header 由绝对居中降为 title leading + More trailing；中间 pill 局部换行。 | 三个纵向大按钮；整个 Dock 横向滚动；Delete 不可见；改变动作顺序。 |
| Accessibility XXXL | 主要结构、语义和三槽位不变，所有交互目标仍可达。 | Header 最多两行；Surface 内部滚动；feedback/详情/确认文案换行；center pill 增高；间距按规定压缩。 | 当前三行 Dock 且 Delete `maxY = 904.7 pt` 的结果；文字裁切；小于 44 pt；必须滚动整页才能到达 Delete。 |
| Light / Dark | 几何和内容一一对应，只变语义 token。 | 系统键盘、状态栏和系统材质可有平台差异。 | 为 Dark 建立不同的间距、高度、换行、Dock 槽位或 overlay 锚点。 |

### 现有结构为何造成基线偏差

`WorkbenchView.swift` 的根结构是一个 `ScrollView` 包住 `VStack(header, noteSurface, feedback, ActionDock)`。这会把 Dock 的 Y 坐标变成前面内容的函数，而不是屏幕 safe-area 的函数；基线已量得 Dock `maxY = 628 pt`，在 874 pt 屏幕上留下约 246 pt 空白。feedback 被插在 Surface 和 Dock 之间，因此每次出现都会使 Dock 下移。

同一文件对展示态和编辑态都使用 `IslandDesign.Sizing.editorMinimumHeight = 310`，导致 Surface 只保证一个内容最小高度，却不消耗 Header 与底部区域之间的剩余高度。`Done` 与 Character Progress 同处 Surface 底部 `HStack`，所以只能形成卡内左下角胶囊，而不是键盘上方整宽 Commit Bar。`ActionDock(feature:)` 无条件出现，编辑态只是由键盘把它遮住，并未从布局和 accessibility tree 移除。Header 又通过第二行 `Not Live / Live` 增加了原型不存在的高度和重复状态。

`ActionDock.swift` 的 `ViewThatFits(in: .horizontal)` 把整个三槽 HStack 的 fallback 定义为三个 `expandedAction` / `liveAction` 纵向排列。在 Accessibility XXXL 下，这个 fallback 把一个 Dock 改成三个页面级大按钮，并在上述整页 `ScrollView` 内继续向下生长；基线中 Delete `maxY = 904.7 pt`，首屏被裁切。该问题不能通过继续调整 `VStack` 间距解决；必须把底部锚点与 Dock 内部窄宽自适应分开。Dock 的 Live / Delete 视觉语义偏差仍留给票据 03，本答案不决定其颜色、图形或动画。

### 建议的 SwiftUI 布局结构（仅契约，不是本轮实现）

```text
ZStack
├─ WorkbenchScaffold                         z 0
│  ├─ WorkbenchHeader                     fixed/intrinsic
│  └─ WorkbenchNoteSurface                flexible frame
│     ├─ RenderedNote ScrollView OR UITextView
│     └─ CharacterProgress overlay          z 1
├─ Feedback overlay                          z 20
└─ DeleteConfirmationOverlay                z 40/41

safeAreaInset(edge: .bottom, spacing: 0)
└─ if isEditing
   └─ EditingCommitBar                    keyboard-top, z 10
   else
   └─ WorkbenchActionDock                  bottom-safe-area, z 10
```

- **采用 `safeAreaInset(edge: .bottom)`**：在同一个条件位置二选一放入 Commit Bar 或 Dock，使根内容自然获得扣除底部区域后的 proposal。Dock 组件本身不读取屏幕高度。
- **采用默认 keyboard safe area**：不监听键盘通知手算高度，不在 Workbench 根视图忽略 keyboard safe area。这使同一个 bottom inset 在编辑时自然位于键盘上方。
- **有限采用 `ViewThatFits`**：可用于 Header 的“居中 / leading”两种对齐，Character Progress 的“水平 / 内部垂直”，以及中心 Live pill 的内边距/两行备选。禁止用它把整个 Dock 替换成三个纵向按钮。
- **优先采用一个小型自定义 `Layout`** 来执行 Header、可压缩空白和 Surface 的垂直分配/压缩顺序。不需要用 `GeometryReader` 读取键盘高度或在视图中散布绝对 Y 坐标；`GeometryReader` 只可作为局部宽度/测试量测备选，不是根布局策略。
- **采用局部 `ScrollView`**：展示正文超出时只滚动 Surface 内容；编辑时使用 `UITextView` 自身的滚动能力；Delete Confirmation 在极端高度下只滚动说明/feedback。不使用包含 Header、Surface 和底部操作的整页 `ScrollView`。
- **采用 `overlay` / `ZStack`**：Feedback 使用底部锚定 overlay；Delete Confirmation 使用忽略 safe area 的 scrim 加安全区内 dialog。确认态关闭背景 hit testing 并隐藏背景 accessibility。

### 票据 03 必须接受的布局输入和边界

票据 03 可决定 Action Dock 和 Live indicator 的视觉、交互和状态表达，但其原型必须把以下项视为不可改变的输入：

1. Dock 是一个组件，永远同时呈现 leading Move、center Go Live / Live、trailing Delete 三个槽位，视觉与 VoiceOver 顺序均为 Move → Live → Delete。
2. 家长布局负责 bottom safe-area 锚定和编辑态移除；Dock 不用屏幕高度算自己的 Y，也不在编辑态保留隐形占位。
3. 两侧目标最小 44×44 pt、理想 48×48 pt；center pill 高度最小 44 pt、理想 48 pt，标准字号宽度最小 112 pt、理想约 152 pt；槽位间距理想 16 pt、最小 8 pt。
4. Live indicator 拥有独立的 18×18 pt 对齐槽（可在 16–20 pt 之间做光学修正），Go Live 与 Live 切换不能改变 pill 或 Dock 的外部 frame。indicator 的空心/实心、光晕、描边、颜色、pressed/busy 和动画属于票据 03，本票据未预判。
5. 窄屏/XXXL 只能使用本答案规定的间距收缩和 center pill 局部两行降级；不得把 Dock 变为纵向三按钮、横向滚动条、分页、隐藏 Delete 或重排操作。
6. Light / Dark、disabled / enabled、Go Live / Live 及后续 busy/pressed 状态必须使用同一几何和槽位契约。Delete Confirmation 和 Feedback 不是 Dock 子槽位，不能用它们扩展 Dock 高度。

本答案仅锁定布局契约，未修改正式 SwiftUI 产品代码，也未制作或开始票据 03 的原型。
