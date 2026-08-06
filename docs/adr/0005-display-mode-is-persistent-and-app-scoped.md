# 显示模式持久化且只作用于 App

Settings 中的 Automatic、Light 和 Dark 是实际产品功能并跨启动持久化：Automatic 实时跟随系统，Light 与 Dark 分别覆盖系统选择并强制 App 内界面使用对应外观。该偏好覆盖 Workbench、Note Library、Settings、菜单和确认界面，但不试图控制 Dynamic Island 或 Lock Screen 等系统托管的 Live Activity 表面；后者继续服从系统外观。这避免为系统表面建立一套可能与 iOS 行为冲突的自定义主题同步机制。
