# 灵动岛便签 MVP 真机发布验收清单

> 状态：未执行。本文是发布门槛，不得用单元测试、SwiftUI Preview 或 Simulator 结果代替。

## 测试记录

- App 构建/版本：
- 测试日期：
- 测试人：
- iOS 版本：
- 窄宽度灵动岛设备（约 371 pt 级）：
- 宽宽度灵动岛设备（约 408 pt 级）：
- 系统语言、地区、外观与字体大小：

## 核心 presentation 与入口

- [ ] 首次启动 Live Activity 时的系统提示与拒绝路径符合预期。
- [ ] compact leading/trailing 只显示便签标记与状态，不泄露正文。
- [ ] minimal 只显示单色标记，不泄露正文。
- [ ] expanded 展示最新已保存正文，长文、换行与 Emoji 由系统安全截断且不滚动。
- [ ] Lock Screen 展示与 expanded 使用同一最新 ContentState 正文。
- [ ] compact、minimal、expanded、Lock Screen 每个入口都返回当前工作台。
- [ ] 带失效 `noteID` 的旧入口只打开当前工作台并对账，不恢复、交换或重新挂起旧便签。

## 生命周期与对账

- [ ] request、同一 Activity update、end 三条真实 ActivityKit 链路均成功。
- [ ] 重复点“挂起”不会创建第二条活动。
- [ ] 手动移除活动后，App 回前台能对账为未挂起。
- [ ] App 在后台、正常终止、崩溃和用户强杀后分别记录系统展示与重新打开后的枚举结果。
- [ ] 设备重启前后分别记录系统展示、`Activity.activities` 枚举和 deep link 行为。
- [ ] 存在其他 App Live Activities 时，本 App 不误结束或修改它们。
- [ ] 完整运行 8 小时，记录系统结束时间以及 Lock Screen 最多约 4 小时尾部残留的实际结果。

## 设置、锁屏与隐私

- [ ] 系统设置中禁用 Live Activities 后，启动失败不丢本机正文、不虚报挂起。
- [ ] 重新启用后可由用户再次挂起，不自动续挂。
- [ ] 锁定/解锁、允许/禁止锁屏访问的组合行为已记录。
- [ ] Always-On 开/关组合下的实际显示已记录（设备支持时）。
- [ ] 系统隐私/redaction 行为已记录，产品不承诺绕过系统隐藏策略。
- [ ] 浅色、深色、提高对比度、Reduce Motion 下状态不只依赖颜色或动画。
- [ ] VoiceOver 能读出编辑器、字符进度、库入口、三项动作及 disabled 原因。
- [ ] 最大 Dynamic Type 下工作台、库与所有关键动作仍可滚动到达且触控目标不小于 44 pt。

## 240 字与 4 KB 样本

分别对 request 与 update 记录编码大小、系统结果和 App 反馈：

- [ ] 240 个中文字符。
- [ ] 240 个 ASCII 字符。
- [ ] 240 个简单 Emoji。
- [ ] 240 个复杂组合字素/家庭 Emoji/变体选择符样本。
- [ ] 超过 4 KB 的极端 Unicode payload 被本地校验阻止；正文仍保存，启动不虚报挂起。
- [ ] 已挂起时 update 超过 4 KB：本机正文仍保存，活动实际状态保持，出现“系统展示可能尚未同步”。

## 通过判据与证据

- [ ] 两种设备宽度上的必测项全部通过，或每个偏差都有复现步骤、系统版本和产品承诺收紧结论。
- [ ] 附上 compact、minimal、expanded、Lock Screen、最大字体、深色与隐私设置组合截图。
- [ ] 附上 8 小时生命周期、强杀、重启、禁用/重开 Live Activities 的时间线记录。
- [ ] 未把 Preview/Simulator 截图标记成真机证据。
