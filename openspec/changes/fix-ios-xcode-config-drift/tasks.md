## 1. OpenSpec
- [x] 1.1 新增 `fix-ios-xcode-config-drift` proposal、tasks、design 与 spec delta

## 2. iOS Runtime Configuration
- [x] 2.1 新增原生运行时配置读取接口，向 Flutter 暴露 iOS AMap key
- [x] 2.2 调整 AMap Flutter 侧配置解析，iOS 改为读取原生运行时 key
- [x] 2.3 保持 Android / Web 现有 key 注入逻辑不变

## 3. Xcode Config Drift Recovery
- [x] 3.1 新增幂等修复脚本，恢复 `PBXProject "Runner"` 的 project-level base configuration
- [x] 3.2 更新 `flutter_run_with_amap.sh`，在脚本退出时自动尝试修复 iOS Xcode 配置

## 4. Documentation and Coverage
- [x] 4.1 更新 README，说明 iOS key 单一来源和 Flutter 3.41.5 的配置漂移修复方式
- [x] 4.2 补充测试，覆盖 iOS 原生运行时 key 读取与 Flutter 侧解析

## 5. Validation
- [x] 5.1 通过 `openspec validate fix-ios-xcode-config-drift --strict --no-interactive`
- [x] 5.2 通过 `flutter analyze`
- [x] 5.3 通过 `flutter test`
- [x] 5.4 通过 `flutter build ios --simulator --debug --no-codesign`
- [x] 5.5 验证修复脚本可将漂移后的 project-level 配置恢复为 `3 Configurations Set`
