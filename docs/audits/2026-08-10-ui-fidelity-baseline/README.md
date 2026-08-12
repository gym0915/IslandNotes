# Island Notes UI fidelity baseline

本目录记录 2026-08-10 在 iPhone 16 Pro（iOS 26.2）Simulator 上重新采集的视觉基线，并把当前 App 与权威原型 `docs/prototypes/island-notes-ios-prototype.png` 做同状态并排比较。

- `report.md`：审计结论、优先级、组件化建议与验收矩阵。
- `current/`：本轮 XCTest UI 流程产生的当前 App 截图与布局坐标。
- `reference/`：从权威原型裁出的同状态手机画面。
- `comparisons/`：左侧原型、右侧当前 App 的等高比较图；中间灰线只用于分隔。
- `crop-coordinates.md`：原型裁图坐标和可追溯性说明。

本轮没有修改正式 SwiftUI 产品代码。UI 测试脚本只存在于 `/tmp` 的隔离项目副本，用于确定性地建立内容、切换状态并保存证据。
