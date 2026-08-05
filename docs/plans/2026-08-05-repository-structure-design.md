# IslandNotes 仓库结构设计

## 目标

将仓库根目录收敛为两个主要入口：`IslandNotes/` 承载可编译、可测试的 iOS 项目，`docs/` 承载产品、决策、研究、计划、验收、原型与审计资料。根目录不再散落源码目标或长文档。

## 项目结构

`IslandNotes/` 是具体项目目录，内部保留 `IslandNotes.xcodeproj` 和 `Configuration/`，并用 `Sources/` 与 `Tests/` 区分生产源码和测试代码。三个生产 Target 继续使用已有名称：`IslandNotes`、`IslandNotesShared`和 `IslandNotesWidget`；两个测试 Target 放入 `Tests/`。

Xcode 工程使用文件系统同步组，所以物理移动后必须同步更新 `project.pbxproj` 中五个根组路径。Info.plist 仍位于工程目录内的 `Configuration/`，因此 Build Settings 中的相对路径无需改变。

## 文档结构

`docs/README.md` 是文档导航与权威性索引。当前 MVP 规格放入 `product/`，过程票据和已确认决策分别放入 `decisions/tickets/` 与 `decisions/records/`，ActivityKit 调研放入 `research/`，已过时的实施计划放入 `plans/archive/`。所有可运行的 Web 原型统一放入 `docs/prototypes/`，审计报告与截图放入 `docs/audits/`。

## 迁移原则

- 不删除产品、原型或审计内容，只移动并分类。
- 文件名使用稳定的 kebab-case，文档内部中文标题保持不变。
- 把文档间引用改为可移植的相对路径，移除指向本机用户目录的绝对路径。
- 发布前检查目录形状、Markdown 本地链接、Xcode 工程解析、构建和测试。

