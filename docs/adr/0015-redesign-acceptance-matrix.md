# 锁定新版重构的验收矩阵

自动化与模拟器最低门槛包括：iPhone 16 Pro 当前 iOS 26.x 的全部 Feature/UI 测试；一台最低支持 iOS 17.x 的灵动岛模拟器上的构建、启动与核心流程；PNG 全部关键页面和状态的 Light/Dark 对照；系统外观与强制 Light/Dark 的交叉组合及重启持久化；默认与最大 Accessibility Dynamic Type；完整 VoiceOver 主流程；Reduce Motion；44pt 触控目标、非纯颜色状态表达；以及从现有 SwiftData 启动的升级兼容测试。

发布前至少使用一台当前 iOS 26.x 的真实灵动岛 iPhone 验证 Go Live、更新、停止、再次 Go Live、Compact、Minimal、Expanded、Lock Screen、deep link、圆点列表、独立截断、禁用 Live Activities、用户移除、后台、强杀、重启、8 小时生命周期、锁屏残留、240 字符与 4 KB 边界、VoiceOver、最大 Dynamic Type、Reduce Motion、Light/Dark 和系统隐私行为。第二种 Dynamic Island 宽度无法获得真机时可以用模拟器补充，但必须明确标为非真机证据；单元测试、Preview 和 Simulator 均不能证明 ActivityKit、锁屏或系统隐私的真实结果。
