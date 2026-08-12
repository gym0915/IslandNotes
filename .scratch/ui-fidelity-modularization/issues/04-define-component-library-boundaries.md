# 定义 UI Component Library 的复用边界与状态 API

- Parent: [Island Notes 高保真 UI 一致性与组件化修正地图](../map.md)
- Type: grilling
- Status: open
- Blocked by: 02, 03

## Question

哪些设计职责应分别落在 token、primitive、composite 和 screen-pattern 层，Workbench Action Dock、LiveStatusIndicator、ActionButton、IconButton、NoteSurface、SheetChrome、MenuRow、SettingsRow、LibraryNoteCard 与 DeleteConfirmation 应暴露哪些状态输入，才能避免业务页面拼装视觉细节，同时不把不相关页面强行塞进一个巨型通用组件？
