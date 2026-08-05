# IslandNotes

IslandNotes 是一个 iOS 17+ 原生便签 App，使用 SwiftUI、SwiftData、ActivityKit 和 WidgetKit，把唯一的当前便签短期展示在灵动岛与锁屏。

## 目录

- `IslandNotes.xcodeproj/`：Xcode 工程与共享 schemes。
- `Configuration/`：App 和 Widget Extension 的 Info.plist。
- `Sources/IslandNotes/`：主 App 源码。
- `Sources/IslandNotesShared/`：App 与 Widget 共用的 Activity 契约。
- `Sources/IslandNotesWidget/`：Widget Extension 源码。
- `Tests/`：功能测试与 UI 测试。
- `../docs/`：产品规格、决策、研究、原型和验收资料。

## 打开项目

```bash
open IslandNotes.xcodeproj
```

## 命令行检查

```bash
xcodebuild -list -project IslandNotes.xcodeproj
xcodebuild -project IslandNotes.xcodeproj \
  -scheme IslandNotes \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  test
```

当前产品与验收事实来源见 [文档导航](../docs/README.md)。
