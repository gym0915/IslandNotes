# ActivityKit 与灵动岛系统约束研究

> 研究范围：本地纯文字便签 MVP 在 iPhone 的 Live Activities / Dynamic Island / Lock Screen 上的系统边界  
> 资料范围：仅 Apple Developer Documentation、Apple Human Interface Guidelines、Apple 官方支持文档  
> 访问日期：2026-07-31  
> 版本口径：Apple 当前公开文档快照（稳定系统为 iOS 26；ActivityKit API 最低可用版本另列）。本文不把 iOS 27 beta 的未稳定行为当作产品承诺。

## 结论摘要

1. 【官方确认】Live Activities 自 iOS 16.1 可用；但当前 `ActivityContent` 形式的 `request(attributes:content:pushType:)` 自 iOS 16.2 可用。若产品只支持带灵动岛的 iPhone，Apple 当前 HIG 与 iOS 26 用户指南机型表列出的设备为：iPhone 14 Pro / Pro Max，iPhone 15 / 15 Plus / 15 Pro / Pro Max，iPhone 16 / 16 Plus / 16 Pro / Pro Max，iPhone 17 / 17 Pro / 17 Pro Max，以及 iPhone Air。列表没有 iPhone 16e。  
   来源：[ActivityAttributes](https://developer.apple.com/documentation/activitykit/activityattributes)；[`request(attributes:contentState:pushType:)`](https://developer.apple.com/documentation/activitykit/activity/request(attributes:contentstate:pushtype:))；[Live Activities — HIG, Specifications](https://developer.apple.com/design/human-interface-guidelines/live-activities#Specifications)；[iPhone User Guide — Models compatible with Dynamic Island（iOS 26）](https://support.apple.com/guide/iphone/aside/iphc36491887/26/ios/26)。访问日期：2026-07-31；API availability 对应 iOS 16.1/16.2，设备表对应 iOS 26。
2. 【官方确认】常规 Live Activity 最多活跃 8 小时；到点后系统结束它并立即从灵动岛移除。结束后的内容最多还能在锁屏保留 4 小时，因此锁屏绝对上限为 12 小时。  
   来源：[Displaying live data with Live Activities — Understand constraints](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities#Understand-constraints)。访问日期：2026-07-31；当前 Apple 文档，适用于当前 ActivityKit。
3. 【由多个官方事实推导】“一直挂起直到用户主动取消/切换/归档/删除”不能兑现为 Live Activity 的系统保证。长期便签必须保留在 App 自己的持久化数据中；Live Activity 只能被建模成有系统时限、可能被用户/系统提前结束或隐藏的投影。是否允许到期后由用户重启、是否设计受控续挂，需要另行产品决策。  
   来源：同上 8 小时限制；[Live Activities — HIG, Best practices](https://developer.apple.com/design/human-interface-guidelines/live-activities#Best-practices)（任务应有明确开始和结束，适合不超过 8 小时）。访问日期：2026-07-31。
4. 【官方确认】240 个“用户感知字符”不是 ActivityKit 的字符上限。真正的数据门槛是每个 Live Activity 的静态与动态数据合计不得超过 4 KB，且属性/状态必须可编码；界面另受 160 pt 高度与各 presentation 宽度限制。  
   来源：[Displaying live data with Live Activities — Understand constraints](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities#Understand-constraints)；[ActivityAttributes](https://developer.apple.com/documentation/activitykit/activityattributes)；[Live Activities — HIG, Specifications](https://developer.apple.com/design/human-interface-guidelines/live-activities#Specifications)。访问日期：2026-07-31。
5. 【由多个官方事实推导】240 个普通中文字符或简单 Unicode 字符通常能装进 4 KB，但“240 个任意用户感知字符必然完整传递”不能由字符数本身保证：一个 grapheme cluster 可能由多个 Unicode scalar 组成，JSON 编码还有字段名和结构开销。产品必须以最终编码后的静态+动态数据总字节数校验为准。  
   来源：Apple 的 4 KB 限制与 `ActivityAttributes: Decodable, Encodable` 要求，见上；Apple 没有提供“240 个 Character”豁免。访问日期：2026-07-31。
6. 【官方确认】compact 由 TrueDepth 相机两侧的 leading/trailing 两块组成；minimal 用于系统同时展示多个活动；长按 compact 或 minimal 才进入 expanded；Lock Screen 是独立 presentation，Apple 要求其布局“类似 expanded”，并不保证两者逐像素或逐行一致。  
   来源：[Displaying live data with Live Activities — Review presentations](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities#Review-Live-Activity-presentations-on-iPhone-and-iPad)；[Live Activities — HIG, Anatomy](https://developer.apple.com/design/human-interface-guidelines/live-activities#Anatomy)。访问日期：2026-07-31。
7. 【官方确认】点击 Live Activity 可以启动 App；可以给 Lock Screen、compact leading、compact trailing、minimal 配置 deep link，expanded 可用 `widgetURL(_:)` 或 `Link`。compact 两侧应跳到同一 App 场景。因此“点击 compact / expanded / Lock Screen 打开当前便签工作台”在 API 能力上成立。  
   来源：[Launching your app from a Live Activity](https://developer.apple.com/documentation/activitykit/launching-your-app-from-a-live-activity)。访问日期：2026-07-31；当前文档。
8. 【官方确认】默认允许 App 使用 ActivityKit；用户可在 Settings 对单个 App 禁用 Live Activities。App 可用 `areActivitiesEnabled` 同步查询，用 `activityEnablementUpdates` 监听变化；启动仍需捕获 `ActivityAuthorizationError` 等失败。Apple 没有提供一个独立的“预申请 Live Activity 权限”API。  
   来源：[ActivityAuthorizationInfo](https://developer.apple.com/documentation/activitykit/activityauthorizationinfo)；[`request(attributes:contentState:pushType:)`](https://developer.apple.com/documentation/activitykit/activity/request(attributes:contentstate:pushtype:))。访问日期：2026-07-31；API 最低 iOS 16.1。
9. 【官方确认】前台 App 可本地 `request` / `update` / `end`；App 在获得后台执行时间时也能本地更新或结束（Apple 以 BackgroundTasks 为例），但不能把“进入后台”理解为持续获得执行权。远程更新由服务器经 APNs ActivityKit push 完成；高优先级推送有每小时预算，Apple 不公布固定数值，超预算可能节流。  
   来源：[Displaying live data with Live Activities — Start/Update](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities#Start-the-Live-Activity)；[Starting and updating Live Activities with ActivityKit push notifications — Determine the update frequency](https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications#Determine-the-update-frequency)。访问日期：2026-07-31。
10. 【官方确认】系统停止 App 或 App 崩溃时，已开始的 Activity 可以继续处于活动状态；下次启动可通过 `Activity<Attributes>.activities` 找回并重新同步。ActivityKit 不替 App 持久化便签业务数据。  
    来源：[Displaying live data with Live Activities — Observe active Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities#Observe-active-Live-Activities)。访问日期：2026-07-31。
11. 【仍需真机验证】Apple 当前公开资料没有对“用户强制杀掉 App 后所有本地更新语义”“设备重启后 Activity 是否、何时恢复到灵动岛/锁屏”“重启期间 deep link 与本地便签状态如何重连”给出足以形成产品保证的逐场景承诺。不能从“App 崩溃时 Activity 可继续”外推到设备重启。  
    参考来源：[Displaying live data with Live Activities — Observe active Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities#Observe-active-Live-Activities)。访问日期：2026-07-31。

## 逐项约束表

| 主题 | 结论与等级 | 对本 MVP 的直接含义 | 官方依据（访问日期均为 2026-07-31） |
| --- | --- | --- | --- |
| 最低 iOS 版本 | 【官方确认】ActivityKit / `ActivityAttributes` 从 iOS 16.1 可用；旧的 `contentState` 启动重载覆盖 iOS 16.1–16.2，当前 `ActivityContent` 启动重载从 iOS 16.2 可用。 | 若产品声明“最低 iOS 16.1”，需保留旧 API 分支；若只走当前 `ActivityContent` API，实际 deployment target 至少 iOS 16.2。 | [ActivityAttributes](https://developer.apple.com/documentation/activitykit/activityattributes)；[`request(attributes:contentState:pushType:)`](https://developer.apple.com/documentation/activitykit/activity/request(attributes:contentstate:pushtype:))；[`request(attributes:content:pushType:)`](https://developer.apple.com/documentation/activitykit/activity/request(attributes:content:pushtype:)) |
| 带灵动岛的设备 | 【官方确认】Apple 当前 HIG 的 Dynamic Island 尺寸表与 iOS 26 用户指南机型表列出：14 Pro 系列；15 全系；16、16 Plus、16 Pro、16 Pro Max；17、17 Pro、17 Pro Max；iPhone Air。没有 16e。 | “仅支持带灵动岛 iPhone”可执行，但应用侧需要以产品支持清单或运行时 presentation 能力为准，不能简单写“iPhone 14 及以后”。 | [Live Activities — HIG, Specifications](https://developer.apple.com/design/human-interface-guidelines/live-activities#Specifications)；[iPhone User Guide — iOS 26 compatible models](https://support.apple.com/guide/iphone/aside/iphc36491887/26/ios/26) |
| 启动位置 | 【官方确认】一般应由前台 App 调用 `Activity.request` 启动；当前系统还支持 `LiveActivityIntent` 从部分系统入口在后台启动，以及远程 push-to-start（后者自 iOS 17.2）。 | 用户在 App 内点击“挂起”后启动是标准路径。纯本地 MVP 不需要为此引入服务器。 | [Displaying live data with Live Activities — Start](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities#Start-the-Live-Activity)；[Starting and updating Live Activities with ActivityKit push notifications](https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications) |
| 授权与禁用 | 【官方确认】默认可用；用户能在 Settings 对 App 禁用。`areActivitiesEnabled` 查询当前是否能启动，`activityEnablementUpdates` 监听变化；`request` 会抛出授权/容量等错误。频繁远程更新另有 `frequentPushesEnabled`。 | 首次点击应“查询后尝试启动并处理错误”，不能假设必成功；UI 不应伪造一个系统授权状态。 | [ActivityAuthorizationInfo](https://developer.apple.com/documentation/activitykit/activityauthorizationinfo)；[Displaying live data with Live Activities — Make sure available](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities#Make-sure-Live-Activities-are-available) |
| 首次系统提示 | 【仍需真机验证】Apple API 文档明确默认可用和用户可在 Settings 禁用，但没有承诺每个当前 iOS/设备配置下首次 `request` 必定出现何种提示、提示文案或提示时序。 | “首次点击挂起时按系统实际处理授权/失败”方向正确；具体 onboarding 文案和截图需真机确认，不能写死为必有 permission prompt。 | [ActivityAuthorizationInfo](https://developer.apple.com/documentation/activitykit/activityauthorizationinfo)；[`ActivityAuthorizationError`](https://developer.apple.com/documentation/activitykit/activityauthorizationerror) |
| compact | 【官方确认】单个主要活动通常显示 compact；由 TrueDepth 相机两侧的 leading/trailing 两块共同表达一个信息。HIG 当前尺寸：leading/trailing 各为 52.33×36.67 pt 或 62.33×36.67 pt（按机型）。 | “compact 不显示正文，只显示标记”技术上可行；但两侧仍须一起构成可识别的信息，且系统也会在其他上下文复用 compact。 | [Displaying live data with Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)；[HIG — Compact](https://developer.apple.com/design/human-interface-guidelines/live-activities#Compact)；[HIG — Specifications](https://developer.apple.com/design/human-interface-guidelines/live-activities#Specifications) |
| minimal | 【官方确认】多个 App 的 Live Activities 同时活跃时，系统可用 minimal 展示两个；系统决定谁显示以及 attached/detached 位置。用户可点按打开 App，长按进入 expanded。 | 即使 MVP 只希望 compact，也必须提供 minimal；不能保证自己的活动永远占用 compact。 | [Displaying live data with Live Activities — compact/minimal](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities#Create-the-compact-and-minimal-presentations)；[HIG — Minimal](https://developer.apple.com/design/human-interface-guidelines/live-activities#Minimal) |
| expanded | 【官方确认】长按 compact 或 minimal 展开；内容被分到 center / leading / trailing / bottom 区域。当前 HIG 尺寸为宽 371 或 408 pt，高 84–160 pt；系统可短暂用 expanded 呈现重要更新。 | “long press 看正文”能力成立，但正文能显示多少取决于字体、换行、Dynamic Type、语言和区域布局，不能按字符数承诺。 | [Displaying live data with Live Activities — expanded](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities#Create-the-expanded-presentation)；[HIG — Specifications](https://developer.apple.com/design/human-interface-guidelines/live-activities#Specifications) |
| Lock Screen | 【官方确认】Lock Screen 是单独的 `ActivityConfiguration` content closure；HIG 要求布局类似 expanded。当前 iPhone 尺寸同样为宽 371/408 pt、高 84–160 pt，超过 160 pt 系统可能截断。 | 可复用同一份便签状态和同一子 View，但系统不保证排版与 expanded 完全一致；“正文一致”只能承诺数据来源一致，不能承诺逐行完整显示一致。 | [Displaying live data with Live Activities — Lock Screen](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities#Create-the-Lock-Screen-presentation)；[HIG — Lock Screen](https://developer.apple.com/design/human-interface-guidelines/live-activities#Lock-Screen) |
| 点击与 deep link | 【官方确认】点击会启动 App。Lock Screen、compact leading/trailing、minimal 使用 `DynamicIsland.widgetURL(_:)`；expanded 可用 `widgetURL(_:)` 或 `Link`。未提供 deep link 时系统仍以 `NSUserActivityTypeLiveActivity` 打开 App。 | compact / expanded / Lock Screen 均可打开当前便签工作台。deep link 必须携带稳定的便签标识，并处理便签已归档/删除的失效场景（后者是产品恢复票的范围）。 | [Launching your app from a Live Activity](https://developer.apple.com/documentation/activitykit/launching-your-app-from-a-live-activity) |
| 本地更新 | 【官方确认】持有 `Activity` 后可调用 `update(_:)`；也可用 `Activity<Attributes>.activities` 取回进行中的活动。更新数据仍不得超过 4 KB。Apple 没有公布本地 `update` 的固定每分钟配额。 | “编辑后短暂停顿自动同步”在 App 正在运行时成立；但应按最终一次数据更新，不应把 debounce 当作后台执行保证。 | [Displaying live data with Live Activities — Update](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities#Update-the-Live-Activity) |
| App 进入后台 | 【官方确认】App 获得后台执行时间时可更新/结束，Apple 以 BackgroundTasks 为例；官方没有保证 App 进入后台后持续运行。 | 若用户编辑后立刻离开 App，最后一次本地同步的可靠时机需真机验证；不能宣称后台会持续自动刷新。 | [Displaying live data with Live Activities — Start](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities#Start-the-Live-Activity) |
| 远程更新 | 【官方确认】服务器可经 APNs 更新或结束 Activity；Live Activity 自己运行在独立 sandbox，不能自行联网。纯本地 MVP 不具备 App 不运行时的远程更新能力。 | 本地纯文字便签无需远程更新才能显示已提交内容；但 App 被杀后若还要变更内容，必须有 APNs/服务器，或等 App 下次运行。 | [Displaying live data with Live Activities — Understand constraints](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities#Understand-constraints)；[Starting and updating Live Activities with ActivityKit push notifications](https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications) |
| 更新频率 | 【官方确认】APNs 高优先级（10）ActivityKit push 受每小时预算约束；超过可能节流。低优先级（5）不计同一预算但不是即时保证。开启 frequent updates 需要 Info.plist 声明，用户也能关闭。Apple 不公布通用固定次数。 | 不得写出“每 N 秒必刷新”的承诺。纯本地编辑同步不应启用 frequent push；若未来引入远程更新需单独验证预算和节流。 | [Starting and updating Live Activities with ActivityKit push notifications — Determine the update frequency](https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications#Determine-the-update-frequency) |
| App 被系统停止/崩溃 | 【官方确认】Apple 明示：系统可能停止 App 或 App 崩溃而 Activity 仍活跃；下次启动通过 `activities` 找回并同步。 | Live Activity 生命周期不等于 App 进程生命周期。业务便签必须自己持久化，重启 App 后重建“便签 ↔ Activity ID/状态”的对应。 | [Displaying live data with Live Activities — Observe active Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities#Observe-active-Live-Activities) |
| 用户强制杀 App | 【由多个官方事实推导】已显示 Activity 由系统承载，不因普通进程终止天然消失；但本地代码不再运行。Apple 当前文档没有单独承诺“force quit”后各类后台回调或本地更新。 | 可预期已提交画面可能继续显示，但不能承诺本地自动同步或恢复回调；列入真机矩阵。 | 同上；[Starting and updating Live Activities with ActivityKit push notifications](https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications) |
| 设备重启 | 【仍需真机验证】官方公开资料未给出可作为产品保证的重启恢复规则。 | 不承诺重启后仍在灵动岛持续显示；业务便签仍在 App 本地持久化，Activity 是否恢复、状态如何枚举需要实测。 | 官方资料缺口；参考 `activities` 恢复入口：[Activity.activities](https://developer.apple.com/documentation/activitykit/activity/activities) |
| 最长持续时间 | 【官方确认】活跃最多 8 小时；到点立即从 Dynamic Island 消失；Lock Screen 最多再 4 小时，总计最多 12 小时。用户和 App 都可提前结束/移除。 | “无限挂起”与系统硬限制冲突。 | [Displaying live data with Live Activities — Understand constraints](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities#Understand-constraints) |
| stale | 【官方确认】`staleDate` 到达后 `activityState` 变为 `.stale`，视图的 `isStale` 为 true；stale 是“内容过期”状态，不等同于自动结束。 | 可用于表达同步内容已旧，但不能用它绕过 8 小时上限。纯便签是否设置 stale 需要产品决定。 | [Displaying live data with Live Activities — Configure](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities#Configure-the-Live-Activity)；[ActivityContent.staleDate](https://developer.apple.com/documentation/activitykit/activitycontent/staledate) |
| 结束与 dismissal | 【官方确认】`end` 后立即离开 Dynamic Island；Lock Screen 按 `.immediate`、`.default` 或 `.after(date)` 移除，最长仍是结束后 4 小时。用户随时可从 Lock Screen 移除，这会使 Activity 状态变为 dismissed，但不会自动改变 App 内原任务。 | 用户在系统 UI 移除 Activity 后，便签本体不应被当作删除；App 下次运行需把“挂起”状态与 Activity 实际状态对齐。 | [Displaying live data with Live Activities — End](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities#End-the-Live-Activity)；[ActivityUIDismissalPolicy](https://developer.apple.com/documentation/activitykit/activityuidismissalpolicy) |
| 数据模型与序列化 | 【官方确认】`ActivityAttributes` 遵循 `Decodable & Encodable`；其 `ContentState` 是动态数据（示例同时要求 `Codable & Hashable`）。远程 payload 必须匹配状态结构，系统使用默认 JSON 解码策略。静态+动态数据合计 ≤4 KB。 | 便签正文若可编辑应放在动态 `ContentState`，稳定便签 ID 可放 attributes；每次启动/更新前按实际编码结果校验。 | [ActivityAttributes](https://developer.apple.com/documentation/activitykit/activityattributes)；[Starting and updating Live Activities with ActivityKit push notifications — payload](https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications#Construct-the-ActivityKit-remote-push-notification-payload)；[Displaying live data with Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities) |
| 240 个用户感知字符：传输 | 【由多个官方事实推导】没有 240 字符 API 上限；240 个普通中文/ASCII/简单 emoji 加少量 JSON 字段很可能低于 4 KB，但任意 grapheme cluster 可能包含多个标量，无法只靠 `String.count <= 240` 保证字节数。 | “最多 240 个用户感知字符”可作为产品输入规则，但还必须加序列化后总大小 ≤4 KB 的防线；超限时启动或更新不能被承诺成功。 | 4 KB 与 Codable 官方事实同上；“任意 grapheme 不能仅按个数担保字节数”为这些官方约束的工程推导。 |
| 240 个用户感知字符：显示 | 【官方确认 + 仍需真机验证】Apple 只规定物理布局（expanded/Lock Screen 高 84–160 pt，超高可能截断），没有给出“最多显示 N 字符”。 | expanded 与 Lock Screen 都不能承诺完整展示 240 字；实际可见量必须按字体、Dynamic Type、中英/emoji、换行、机型实测。可以完整传递，不等于完整显示。 | [Displaying live data with Live Activities — Lock Screen](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities#Create-the-Lock-Screen-presentation)；[HIG — Specifications](https://developer.apple.com/design/human-interface-guidelines/live-activities#Specifications) |
| Lock Screen 与 expanded 内容一致性 | 【官方确认】两者使用同一 Activity state，但由不同 presentation builder 布局；HIG 要求 Lock Screen 使用“类似 expanded”的布局，而非相同布局。 | 可以保证语义/数据一致；不能保证逐像素、逐行或可见字符完全一致。 | [ActivityConfiguration](https://developer.apple.com/documentation/widgetkit/activityconfiguration)；[HIG — Lock Screen](https://developer.apple.com/design/human-interface-guidelines/live-activities#Lock-Screen) |
| 锁屏隐私与显示开关 | 【官方确认】HIG 要求避免敏感信息，建议以无害摘要替代或用 `privacySensitive` 让用户决定是否显示；WidgetKit 在用户选择隐藏时会渲染 placeholder/redaction。用户也能在 Face ID & Passcode 的锁屏访问设置中限制相关锁屏数据。 | “产品不主动模糊”不等于“系统永远显示完整正文”。即便不用 `privacySensitive`，用户仍能禁用 Live Activities/锁屏访问；若标记敏感，系统可按用户隐私设置遮盖。真实差异需真机确认。 | [HIG — Best practices](https://developer.apple.com/design/human-interface-guidelines/live-activities#Best-practices)；[Creating a widget extension — Hide sensitive content](https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension#Hide-sensitive-content) |

## 对既有产品决策的影响

| 既有决定 | 研究判断 | 影响 |
| --- | --- | --- |
| 仅支持带灵动岛 iPhone | 【可实现，但需收紧设备定义】 | 应按 Apple 当前 HIG 明列的机型支持；不能用“iPhone 14 及以后”作等价表达，因为普通 iPhone 14 与 iPhone 16e 不在表中。设备清单会随硬件发布漂移，应在发布前按当时 HIG 再核。 |
| compact 不显示正文，只显示标记 | 【可实现】 | 仍必须实现 leading、trailing、minimal，并保证系统复用 compact 到其他设备/场景时可识别。 |
| long press 看 expanded 正文 | 【可实现，但显示量不保证】 | 系统负责长按展开；expanded 最高 160 pt，240 字不能承诺全部可见。 |
| tap compact/expanded 打开当前便签工作台 | 【可实现】 | 用同一个稳定便签 ID 构造 deep link；compact leading/trailing 必须跳到同一目标。Lock Screen 也可同样 deep link。 |
| Lock Screen 显示与 expanded 一致正文且产品不主动模糊 | 【部分可实现，表述需调整】 | 同一数据可以提供给两种 presentation，布局可相似；但实际排版、截断、用户禁用、系统隐私/锁屏设置不受产品完全控制，不能保证“始终完整一致可见”。 |
| 当前挂起内容编辑后短暂停顿自动同步 | 【前台可实现；后台边界需明确】 | App 运行时可 debounce 后调用本地 `update`。若 debounce 尚未完成用户就退后台/杀进程，后台执行不保证；必须做真机可靠性验证，不能把后台持续刷新写进承诺。 |
| 最长 240 个用户感知字符 | 【可作为产品规则，但不是系统显示保证】 | 还需要 4 KB 序列化总大小校验；expanded/Lock Screen 可见字符量另由布局决定。 |
| 一直挂起直到主动取消/切换/归档/删除 | 【不可由 Live Activity 实现为系统保证】 | 与 8 小时硬上限、用户可随时移除、用户可禁用、系统可控制 presentation 的事实冲突。必须重新讨论产品模型和用户文案。 |
| 首次点击挂起时按系统实际处理授权/失败 | 【方向成立】 | `areActivitiesEnabled` + `request` 错误处理是官方路径；首次提示样式/时机不得写死，需真机确认。 |

## 必须调整或重新讨论的决定

以下只陈述冲突边界，不替用户选择方案：

1. **“持续挂起”定义必须改变。** Live Activity 不可能被承诺为无限期常驻。需要决定产品文案是明确“最长 8 小时”、到期后要求用户重新挂起，还是提供某种受控续挂流程；任何流程都不能对系统展示的无缝连续性作保证。
2. **便签与 Live Activity 的身份关系必须分层。** 便签是 App 的长期持久状态；Live Activity 是可以过期、被移除、被禁用、被系统结束的短期展示。系统 dismissed 不应等同于删除/归档便签。
3. **“锁屏与 expanded 一致”应从视觉保证改成数据/语义一致目标。** 两者是不同 presentation，系统尺寸、截断、隐私和锁屏设置会造成实际差异。
4. **“240 字完整显示”若是既有隐含期待，必须撤回。** 240 字可以是输入上限；传输要另过 4 KB 校验，完整可见性没有 Apple 字符数保证。
5. **后台/中断后的同步承诺需要单独决策。** 纯本地 MVP 在 App 不执行时不会自行更新；强杀、重启、用户移除后的业务状态恢复，应由“确定挂起失败与系统中断后的恢复规则”票处理。
6. **隐私表述必须改成能力边界。** “产品不主动模糊”只能描述 App 自己没有主动 redaction；不能承诺锁屏一定展示正文，因为用户能关闭 Live Activities/锁屏访问，系统也会按隐私配置渲染或隐藏受保护内容。

## 真机验证清单

建议覆盖至少一台 371 pt 宽灵动岛机型（例如 iPhone 17 Pro / 16 Pro / 15 Pro / 14 Pro）和一台 408 pt 宽机型（Pro Max、Plus 或 iPhone Air），系统版本以发布时最新 iOS 26.x 为基线；若要支持 iOS 16.x，再追加最旧系统设备。

- [ ] 首次安装后第一次 `Activity.request`：是否出现系统提示、提示具体时机、取消/允许后的 `areActivitiesEnabled` 与错误值。
- [ ] Settings 中关闭本 App Live Activities：已有 Activity 是否立即消失、再次 `request` 的错误、重新开启后的行为。
- [ ] Face ID & Passcode 锁屏访问相关开关、Always-On、设备锁定/解锁下：正文是否展示、隐藏、redact 或整个 Activity 不出现。
- [ ] 不使用 `.privacySensitive()` 与使用 `.privacySensitive()` 两组：Lock Screen、Always-On、expanded 的差异；确认“产品不主动模糊”的实际用户可见结果。
- [ ] compact leading/trailing、minimal、expanded、Lock Screen 的点击：冷启动/热启动均能 deep link 到正确便签；compact 两侧目标一致。
- [ ] 便签已归档/删除后再点击旧 Activity：App 的降级入口（此项属于恢复规则票，当前只记录验证需求）。
- [ ] 240 个中文字符、240 个 ASCII、240 个简单 emoji、含 ZWJ/肤色/组合音标的 240 个 grapheme：分别记录 JSON 编码字节数和 `request/update` 结果。
- [ ] 上述文本在 371/408 pt、默认字体、最大辅助字体、粗体文本、深色/浅色、Always-On 下的 expanded 与 Lock Screen 实际行数、截断和可读性。
- [ ] App 前台编辑后 debounce 更新；编辑后立即 Home、锁屏、切 App、强杀，确认最终内容是否已提交。
- [ ] App 正常进入后台、被系统终止、崩溃、用户强制杀掉后：Activity 是否仍显示；重新打开时 `Activity.activities` 能否枚举并与本地便签重连。
- [ ] 设备重启前后：Activity 是否保留、在 Lock Screen / Dynamic Island 的恢复时机、`activities` 枚举结果、deep link 结果。
- [ ] Activity 运行满 8 小时：从 Dynamic Island 移除的实际时刻；Lock Screen 后续保留与最多 4 小时自动移除。
- [ ] 用户从 Lock Screen 手动移除：`activityStateUpdates` / 下次启动查询到的 dismissed 状态，以及 App 内便签是否保持完整。
- [ ] `staleDate` 到时：确认只切换为 stale / `isStale`，不会被误当作 ended；UI 不误导用户正文已删除。
- [ ] 多个 App Live Activities 并存：本活动从 compact 变 minimal、被系统暂不展示时的行为；不能把“未在灵动岛可见”误判为已结束。

## 研究问题覆盖核对

| 票据要求的八类问题 | 覆盖位置 | 状态 |
| --- | --- | --- |
| 紧凑态 | 逐项约束表：compact / minimal | 已回答；尺寸和系统选择均有官方来源 |
| 展开态 | 逐项约束表：expanded；240 字显示 | 已回答；完整可见量需真机验证 |
| 锁屏 | 逐项约束表：Lock Screen、隐私、与 expanded 一致性 | 已回答；隐私组合需真机验证 |
| 跳转 | 逐项约束表：点击与 deep link | 已回答；冷/热启动和失效便签需真机验证 |
| 更新 | 逐项约束表：本地、后台、远程、频率 | 已回答；后台最终一次提交需真机验证 |
| 持续时间 | 逐项约束表：8 小时、stale、dismissal | 已回答；8+4 小时实际边界需长时真机验证 |
| 设备 | 最低版本与官方 HIG 设备表 | 已回答；发布前应复核漂移 |
| 授权 | 启动、授权与禁用、首次系统提示 | API 已回答；首次 UI/时序需真机验证 |

## 来源索引

以下均为 Apple 官方一手资料，访问日期均为 **2026-07-31**。

1. Apple Developer Documentation — [Displaying live data with Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)  
   用途：presentation 结构、8+4 小时时限、4 KB、160 pt、启动/更新/结束、后台更新、状态恢复。
2. Apple Human Interface Guidelines — [Live Activities](https://developer.apple.com/design/human-interface-guidelines/live-activities)  
   用途：compact/minimal/expanded/Lock Screen 的设计关系、隐私建议、当前 iPhone 尺寸和带灵动岛机型表。当前公开表列到 iPhone 17 / iPhone Air，作为 2026-07-31 的设备快照。
3. Apple Developer Documentation — [Launching your app from a Live Activity](https://developer.apple.com/documentation/activitykit/launching-your-app-from-a-live-activity)  
   用途：默认启动、`NSUserActivityTypeLiveActivity`、Lock Screen/compact/minimal/expanded 的 deep link。
4. Apple Developer Documentation — [ActivityAuthorizationInfo](https://developer.apple.com/documentation/activitykit/activityauthorizationinfo)  
   用途：默认可用、用户禁用、`areActivitiesEnabled`、授权变化、frequent push 权限。API availability：iOS 16.1+。
5. Apple Developer Documentation — [ActivityAuthorizationError](https://developer.apple.com/documentation/activitykit/activityauthorizationerror)  
   用途：启动失败/拒绝需要显式处理。
6. Apple Developer Documentation — [ActivityAttributes](https://developer.apple.com/documentation/activitykit/activityattributes)  
   用途：`Decodable & Encodable`、静态 attributes / 动态 ContentState。API availability：iOS 16.1+。
7. Apple Developer Documentation — [`request(attributes:contentState:pushType:)`](https://developer.apple.com/documentation/activitykit/activity/request(attributes:contentstate:pushtype:))  
   用途：iOS 16.1 旧启动入口、前台要求、授权错误。API availability：iOS 16.1–16.2。
8. Apple Developer Documentation — [`request(attributes:content:pushType:)`](https://developer.apple.com/documentation/activitykit/activity/request(attributes:content:pushtype:))  
   用途：当前 `ActivityContent` 启动入口。API availability：iOS 16.2+。
9. Apple Developer Documentation — [ActivityContent](https://developer.apple.com/documentation/activitykit/activitycontent) 与 [staleDate](https://developer.apple.com/documentation/activitykit/activitycontent/staledate)  
   用途：动态状态、stale、relevance。API availability：iOS 16.2+。
10. Apple Developer Documentation — [ActivityUIDismissalPolicy](https://developer.apple.com/documentation/activitykit/activityuidismissalpolicy)  
    用途：`.default` / `.immediate` / `.after` 的锁屏移除边界。
11. Apple Developer Documentation — [Starting and updating Live Activities with ActivityKit push notifications](https://developer.apple.com/documentation/activitykit/starting-and-updating-live-activities-with-activitykit-push-notifications)  
    用途：远程 start/update/end、APNs payload、默认 JSON 解码、推送预算和 frequent updates；文档按具体能力注明 iOS 17.2、iOS 18 等版本差异。
12. Apple Developer Documentation — [Creating custom views for Live Activities](https://developer.apple.com/documentation/activitykit/creating-custom-views-for-live-activities)  
    用途：各 presentation 的复用、Dynamic Island 背景、Lock Screen/Always-On 适配。
13. Apple Developer Documentation — [Creating a widget extension — Hide sensitive content](https://developer.apple.com/documentation/widgetkit/creating-a-widget-extension#Hide-sensitive-content)  
    用途：`privacySensitive`、系统 privacy redaction、锁屏访问设置。
14. Apple Support — [About iOS 26 Updates](https://support.apple.com/123075)  
    用途：本报告“当前稳定系统为 iOS 26”的版本锚点；访问日仍需以发布时最新 26.x 小版本复测。
15. Apple Support — [iPhone User Guide — Dynamic Island compatible models（iOS 26）](https://support.apple.com/guide/iphone/aside/iphc36491887/26/ios/26)  
    用途：交叉核对 2026-07-31 时带灵动岛的 iPhone 机型范围；与 HIG Specifications 当前表一致。

## 事实、推导与资料缺口边界

- 文中【官方确认】只用于 Apple 页面直接陈述的事实。
- 【由多个官方事实推导】用于把 4 KB、Codable、8 小时、不同 presentation 等事实合并后对本产品得到的结论；它不是 Apple 对本产品的背书。
- 【仍需真机验证】集中在 Apple 没有给确定保证或高度依赖设备/设置的场景：首次授权 UI、force quit、设备重启、240 grapheme 实际编码与渲染、隐私组合、后台 debounce 最终提交。
- 本研究没有读取产品源码或既有资料，也没有生成实现方案；“必须重新讨论”部分只列系统事实造成的冲突，不替用户选择产品取舍。
