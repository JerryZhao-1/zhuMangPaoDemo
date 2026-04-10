## Context
- 当前应用在 Material 层定义了 light/dark 两套主题，并通过 `ThemeMode.system` 自动跟随设备系统主题。
- 多数页面没有给所有文本逐一指定 `color`，因此它们依赖 `ThemeData.textTheme` 的默认前景色。
- Android 当前联调环境表现为浅色主题，而 iOS 用户设备存在深色模式，导致默认字体颜色在双端不一致。

## Goals
- 让默认文本在 Android 与 iOS 上稳定保持同一组黑色前景
- 保留已有页面内显式定义的深色卡片、浅色按钮与品牌配色
- 用自动化测试锁定全局主题模式和默认文本色，防止回归

## Non-Goals
- 不重做单个页面的视觉设计
- 不调整已经显式写死的白字、彩色字或深色卡片样式

## Decision
- 使用固定浅色 `ThemeMode.light` 作为应用默认模式。
- 在 `AppTheme.lightTheme` 中对 `textTheme` 使用 `bodyColor` 与 `displayColor` 显式设置为 `AppTheme.black`，避免依赖 Material 默认生成色。

## Risks
- 若后续产品明确要求系统级深色模式，需要重新引入 dark theme 策略并单独设计跨端验收标准。
