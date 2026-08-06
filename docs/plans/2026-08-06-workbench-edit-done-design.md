# Workbench 展示、编辑与 Done 提交闭环设计

## 目标

让 Workbench 默认呈现已提交源文本的渲染结果；用户点击便签后编辑纯源文本，只有 `Done` 才把内存草稿提交到 SwiftData，并在 Live 会话存在时更新同一 Activity。保存失败不得丢失草稿或退出编辑态。

## 已确认依据

- `docs/product/mvp-spec.md` 的 Workbench 编辑状态机、字符限制、渲染与验收要求。
- `docs/adr/0003-current-note-has-display-and-editing-states.md` 的显式提交与进程内草稿生命周期。
- `docs/adr/0012-preserve-data-and-live-activity-invariants.md` 的持久化与 Live Activity 不变量。
- `CONTEXT.md` 的 Workbench、源文本、编辑草稿、渲染内容与列表行术语。

这些材料已经声明没有阻塞实施的开放产品决定。本设计只固定工程映射，不改变产品行为。

## 方案选择

采用 `IslandNotesFeature` 持有编辑会话状态、`NoteWorkspace` 只处理显式持久事务、纯值类型负责源文本渲染与字符限制、SwiftUI View 只发送用户 intent 的组合。

没有选择把草稿放在 `WorkbenchView` 本地，因为草稿需要跨 Note Library、Settings sheet 和普通后台切换保留，并且 feature harness 必须能在不驱动视图的情况下验证完整状态机。也没有新增 `WorkbenchViewModel` 或 editor ViewModel，因为规格明确保留 `IslandNotesFeature` 作为统一行为 seam，并排除浅层 ViewModel。

## 状态与数据流

`IslandNotesFeature` 暴露互斥的展示态和编辑态：

1. bootstrap 后进入展示态，字符进度读取 `currentNote.body`。
2. `beginEditing()` 将已提交源文本复制到内存草稿并进入编辑态。
3. `stageEditorText` 只更新草稿。marked text 活跃时不截断组合输入；提交组合后按 240 个 Swift `Character` 截断。
4. `Done` 调用 Workspace 的原子提交。成功后发布新快照、增加内容版本、退出编辑态，并在 Live 时为同一 Activity 排队更新；失败时保留草稿、字符状态和编辑态。
5. sheet/router 和 scene phase 不拥有也不重建 Feature，因此进程存活期间草稿自然保留。替换、入库和删除当前便签继续通过已有成功路径重置编辑会话。

SwiftData 中仍只有已提交源文本；渲染内容和草稿都不形成第二份持久记录。

## 渲染

增加共享的纯值源文本解析：按换行保留空行与顺序；只有从第一个字符开始匹配 `- ` 的行成为圆点列表行，展示时移除该两字符前缀。`* item`、`# heading`、`-item`、缩进后的 `- item` 等全部按普通文字显示。

Workbench 展示态使用该投影生成只读内容；编辑态始终显示未经渲染的完整源文本。该解析模型可由后续 ActivityKit presentation 复用，避免两处列表语义漂移。

## 交互与错误

- 展示卡片整体可点击进入编辑，空白状态也可进入编辑。
- 编辑态显示源文本编辑器与明确的 `Done`。
- 字符环展示态计算已提交值，编辑态计算草稿值。
- 点击字符环显示 `N used · M remaining` 两秒；两秒内重复点击取消旧计时并重新计时。
- 保存失败继续显示编辑器和草稿，并使用既有 Workbench feedback 区域呈现英文错误。
- 输入或草稿本身不触发 SwiftData save，也不触发 Live update。

## Preview 与测试

已约定的 public seams 是：

- Feature harness：bootstrap、begin edit、stage、Done、Live update、失败保留与重启恢复。
- 内存 SwiftData 与不可写 store：验证提交前无持久变化、成功版本更新和失败回滚。
- Fake Live controller：验证草稿不更新 Live，Done 只更新同一 Activity。
- Text limiter 与源文本 renderer：验证 240 Character、粘贴、IME、组合 Emoji 和严格的 `- ` 规则。
- Workbench UI/accessibility identifiers：验证展示 → 编辑 → Done → 渲染，以及空白、上限和错误状态。
- SwiftUI Preview：覆盖关键 Light/Dark、空白、展示、编辑、240 上限和保存错误。

完成前运行定向测试、完整 feature test suite、UI tests（环境允许时）和 App build，并对最终差异执行 Standards/Spec 双轴审查。
