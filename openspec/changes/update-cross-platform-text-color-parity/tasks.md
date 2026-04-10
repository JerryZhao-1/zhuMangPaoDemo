## 1. OpenSpec
- [x] 1.1 新增 `update-cross-platform-text-color-parity` proposal、design、tasks 与 spec delta
- [x] 1.2 通过 `openspec validate update-cross-platform-text-color-parity --strict --no-interactive`

## 2. Theme Fix
- [x] 2.1 将应用主题模式固定为浅色，避免 iOS 跟随系统主题改变默认字体颜色
- [x] 2.2 在全局 light theme 中显式设置默认标题色与正文色为品牌黑

## 3. Validation
- [x] 3.1 补充主题模式与默认文本颜色测试
- [x] 3.2 运行 `flutter test`
- [x] 3.3 完成 Android no-AMap demo 端到端验证
- [x] 3.4 记录 iOS 模拟器与无线真机联调阻塞，并补充替代验证证据

## Validation Notes
- Android: `./scripts/flutter_run_ui_demo.sh -d emulator-5554` 可正常启动，截图确认共享页面文本为黑色。
- iOS Simulator: `AMapFoundation` 缺少 Apple Silicon iOS 26 模拟器所需的 `arm64-simulator` slice，且 `Runner` 未匹配到目标 simulator destination，无法完成模拟器 UI 验证。
- iOS Device: `./scripts/flutter_run_ui_demo.sh -d 00008120-00045C500138201E` 可完成构建与安装，但无线调试阶段因设备侧 Local Network/Xcode Automation 授权未完成，无法抓取 Flutter 截图作为最终视觉证据。
