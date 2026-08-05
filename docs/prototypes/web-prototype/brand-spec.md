# Island Notes 视觉规范

参考来源：`IMG_4988.PNG`–`IMG_5002.PNG`。截图的主色采样集中在浅色模式 `#f6f6f6` / `#ffffff`，深色模式 `#1a1a1a` / `#242424`。本规范吸收其克制的 iOS 视觉语言，但不复制 Mononote 品牌资产。

## 色彩 tokens

```css
:root {
  --bg: oklch(97.3% 0 0);
  --surface: oklch(100% 0 0);
  --fg: oklch(17.8% 0 0);
  --muted: oklch(65.5% 0.007 286);
  --border: oklch(91.8% 0.002 286);
  --accent: oklch(17.8% 0 0);
}
```

语义状态色不参与日常装饰：Live 仅使用低饱和绿色 `oklch(54% 0.13 145)`，危险操作仅使用系统红色。

## 字体

- Display：`-apple-system, BlinkMacSystemFont, "SF Pro Display", system-ui, sans-serif`
- Body：`-apple-system, BlinkMacSystemFont, "SF Pro Text", system-ui, sans-serif`
- Mono：`ui-monospace, "SF Mono", Menlo, monospace`

## 姿态规则

1. 主界面保持大量空白，只突出当前便签，不添加次要信息卡。
2. 控件采用大圆角、细白描边与柔和扩散阴影；主操作使用近黑实底。
3. 底部操作保持三点结构：归档、Live、删除；Live 是唯一可出现状态色的常规控件。
4. 设置与归档使用大分组卡片和清晰分隔线，信息层级优先于装饰。
5. 深色模式使用纯黑背景与深灰表面，不使用蓝紫渐变、暖黄色纸张或彩色图标组。
