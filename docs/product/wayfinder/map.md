# 灵动岛便签 MVP｜Wayfinder 地图

- Tracker: local-markdown
- Label: `wayfinder:map`
- Status: open

## Destination

形成一份可直接交给设计与开发的 MVP 产品规格：产品行为无歧义，关键界面经过用户确认，iOS 系统约束得到验证，异常路径与验收标准明确。

## Notes

- 产品领域：iPhone App、Dynamic Island、Live Activities、本地纯文字便签。
- 每次继续推进时使用 Wayfinder；涉及术语与状态模型时使用 domain-modeling；涉及用户决策时使用 grilling，一次只问一个问题。
- 当前阶段不读取 `../../prototypes/web-prototype/`、项目内其他文件或外部资料；只使用本次对话及本地图文件。
- 因上述限制，技术研究票只建档，不启动研究或子代理，直到用户明确允许。
- Wayfinder 默认只做规划和决策，不进入正式开发。
- [决策票执行提示词索引](prompt-index.md)汇总了推荐执行顺序；每张票的提示词正文保存在票据自身。

## Decisions so far

- [确定灵动岛便签 MVP 的核心产品模型](overview.md) — 已确定单一当前便签槽位、显式挂起、次级便签库、240 字符输入模型、灵动岛与锁屏行为及 MVP 范围边界。
- [验证 Live Activities 与灵动岛的系统约束](../../decisions/tickets/01-system-constraints.md) — 已确认 8 小时活动上限、4 KB 数据边界、系统展示与授权能力；冲突决定转入新的 grilling 子票。
- [重新确认展开态与锁屏的内容承诺](../../decisions/tickets/07-content-commitment.md) — 两处使用同一当前便签与同一内容状态，但不承诺呈现或全文可见一致；产品不主动处理正文隐私，最终可见结果服从用户设置与系统行为。
- [重新定义 Live Activity 的挂起生命周期](../../decisions/tickets/06-session-lifecycle.md) — “挂起”改为最长 8 小时且可能提前结束的短期展示会话；会话结束后便签保持完整并回到未挂起。

## Not yet specified

- 正式品牌、App 名称、图标、视觉 token 与最终界面文案；待页面和系统展示原型确定后再细化。
- App Store 上架、商业模式、数据迁移和长期版本路线；这些不阻塞 MVP 产品规格，是否另立地图待后续决定。

## Out of scope

- 定时提醒、定时挂起、倒计时和自动取消挂起。
- iCloud、账号体系与跨设备同步。
- 搜索、标签、文件夹、收藏和手动置顶。
- 桌面小组件、锁屏小组件、分享扩展、快捷指令和其他 App 的分享入口。
- 非灵动岛 iPhone 的替代体验。
- 便签颜色、字体、字号和主题自定义。
- 灵动岛内编辑、完成按钮及其他快捷操作。
