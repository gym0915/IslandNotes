# 保留数据与 Live Activity 不变量

新版高保真界面继续保留上一版已经验证的数据和系统生命周期不变量：始终只有一个当前便签；源文本受 240 个用户感知字符限制；入库、无损替换和删除使用原子 SwiftData 事务；SwiftData 是已提交便签内容的事实来源；任意时刻最多一个属于当前便签的 Live Activity；ActivityKit 实际枚举是 Live 状态事实来源；已提交的 Live 编辑更新同一 Activity；内容事务前执行结束屏障；启动、回前台和 deep link 后对账；保留 4 KB payload 校验；新当前便签不自动 Go Live；会话最长 8 小时、可能提前结束、不自动续期；Live Activity deep link 只回到 Workbench。唯一明确替换的相关旧契约是自动保存：编辑态现在持有内存草稿，只有 `Done` 成功提交后才更新 SwiftData 和 Live Activity。

未在 PNG 中画出的 SwiftData 与 ActivityKit 失败状态仍属于必需产品行为，并使用 Hints & Messages 视觉语言补齐。保存失败保留草稿与编辑态；Go Live、停止、同步和对账失败继续以 ActivityKit 实际结果为状态事实；入库、替换和删除失败保持数据不变且不得虚报完成；反馈使用英文并可被 VoiceOver 及时获知，错误不形成新的长期业务状态。
