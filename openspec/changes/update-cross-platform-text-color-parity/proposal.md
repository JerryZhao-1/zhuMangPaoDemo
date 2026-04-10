# Change: update-cross-platform-text-color-parity

## Why
当前 Flutter 应用在 `ThemeMode.system` 下会跟随设备系统深浅色。iOS 端在系统深色模式下会把未显式指定颜色的文本前景色切到浅色，导致同一页面在 Android 上显示为黑字、在 iOS 上显示为非黑字，破坏双端 UI 一致性。

## What Changes
- 将应用默认主题固定为浅色模式，避免 iOS 跟随系统深浅色后改变默认文本颜色
- 在全局 light theme 中显式声明默认标题色与正文色为品牌黑
- 增加针对主题模式与默认文本色的自动化测试
- 补充 Android/iOS 的端到端验证，确认两端首页文案都保持黑色文本表现

## Impact
- Affected specs: `flutter-frontend-migration`
- Affected code: `lib/app/aidrun_app.dart`, `lib/core/theme/app_theme.dart`, `test/widget_test.dart`
