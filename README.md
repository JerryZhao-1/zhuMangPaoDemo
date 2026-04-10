# AidRun 助盲跑 Flutter App

本仓库为 Flutter 双端项目，当前主工程用于构建 Android 与 iOS 前端展示版。

## 技术栈

- Flutter
- Riverpod
- go_router
- amap_flutter_map / amap_flutter_location
- flutter_tts
- speech_to_text
- shared_preferences

## 运行方式

1. 安装 Flutter 依赖
   `flutter pub get`
2. 真实 AMap 运行
   `flutter run --dart-define=AMAP_ANDROID_KEY=你的AndroidKey --dart-define=AMAP_IOS_KEY=你的iOSKey --dart-define=AMAP_WEB_KEY=你的WebServiceKey`
3. 已配置本地 key 后可直接运行
   `./scripts/flutter_run_with_amap.sh`
4. 模拟器 UI Demo 运行
   `./scripts/flutter_run_ui_demo.sh`

## 模拟器 UI Demo 模式

- `./scripts/flutter_run_ui_demo.sh` 会显式注入 `DISABLE_AMAP=true`，同时清空 Android、iOS、Web 的高德 key。
- 当前保障目标是 Android 模拟器 UI 联调，例如：
  `./scripts/flutter_run_ui_demo.sh -d emulator-5554`
- no-AMap demo mode 仅用于 UI 联调与流程演示：
  - 地图区域固定显示降级占位
  - 定位服务直接返回空结果
  - 地点搜索固定使用本地演示候选
- Apple Silicon 上的 iOS 模拟器仍可能受 `amap_flutter_map` Pod 缺少 `arm64-simulator` slice 影响，本模式不承诺解决该三方依赖限制。

## 高德地图配置

- 地图原生 SDK key 通过 `AMAP_ANDROID_KEY` 与 `AMAP_IOS_KEY` 注入
- 地点搜索 Web Service key 通过 `AMAP_WEB_KEY` 注入
- 显式 no-AMap demo mode 通过 `DISABLE_AMAP=true` 注入，优先级高于所有 key 配置
- 未配置 key 时：
  - 志愿者端地图会显示占位提示，不会白屏
  - 盲人端地点搜索会回退到本地演示地点列表
- 高德 SDK 使用前需要满足隐私合规要求，当前工程已在地图 wrapper 和定位服务中按“已展示、已包含、已同意”进行初始化，正式接入时应替换为真实隐私授权流程

## 校验命令

- 静态检查
  `flutter analyze`
- 测试
  `flutter test`
- Android Debug 构建
  `flutter build apk --debug`
- iOS Simulator Debug 构建
  `flutter build ios --simulator --debug --no-codesign`

## 说明

- `lib/` 为当前 Flutter 主代码。
- `android/` 与 `ios/` 为原生工程壳。
- 原 `src/` React 代码保留为迁移参考，不再作为主运行时入口。
