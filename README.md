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
2. 本地运行
   `flutter run --dart-define=AMAP_ANDROID_KEY=你的AndroidKey --dart-define=AMAP_IOS_KEY=你的iOSKey --dart-define=AMAP_WEB_KEY=你的WebServiceKey`
3. 已配置本地 key 后可直接运行
   `./scripts/flutter_run_with_amap.sh`

## 高德地图配置

- 地图原生 SDK key 通过 `AMAP_ANDROID_KEY` 与 `AMAP_IOS_KEY` 注入
- 地点搜索 Web Service key 通过 `AMAP_WEB_KEY` 注入
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
