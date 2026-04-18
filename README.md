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
2. 复制环境变量模板并填写本地 key
   `cp .env.example .env`
3. Android / 通用 Flutter CLI 启动脚本
   `./scripts/flutter_run_with_amap.sh`
4. 如需手动运行，也可直接使用 `dart-define`
   `flutter run --dart-define=AMAP_ANDROID_KEY=你的AndroidKey --dart-define=AMAP_WEB_KEY=你的WebServiceKey`
5. iOS 真机稳定调试脚本
   `./scripts/run_ios_device_with_attach.sh --device <udid-or-name>`
6. iOS 原生 key 从根目录 `.env` 注入到 Xcode 配置
   `AMAP_IOS_KEY=你的iOSKey`

## 环境变量

- 根目录 `.env` 用于保存本地敏感配置，已加入 `.gitignore`
- 可提交模板为 `.env.example`
- React/Vite 参考代码读取 `VITE_FIREBASE_*`
- Flutter 脚本默认读取根目录 `.env`

## 高德地图配置

- Android 原生地图/定位 SDK key 优先读取 `--dart-define=AMAP_ANDROID_KEY=...`，若未提供则回退到进程环境变量 `AMAP_ANDROID_KEY`
- iOS 地图与定位 SDK key 通过 `/.env -> ios/Flutter/*.xcconfig -> Info.plist -> 原生运行时` 注入，Flutter CLI 不再覆盖 iOS key
- 地点搜索 Web Service key 通过 `AMAP_WEB_KEY` 注入
- 未配置 key 时：
  - 志愿者端地图会显示占位提示，不会白屏
  - 盲人端地点搜索会回退到本地演示地点列表
- 高德 SDK 使用前需要满足隐私合规要求，当前工程已在地图 wrapper 和定位服务中按“已展示、已包含、已同意”进行初始化，正式接入时应替换为真实隐私授权流程

## 高德接入校验

- Web Service key 校验
  `curl -s "https://restapi.amap.com/v3/assistant/inputtips?key=$AMAP_WEB_KEY&keywords=天坛&datatype=poi&city=北京&citylimit=false"`
  返回结果应包含 `"status":"1"` 和非空 `tips`
- Android 原生 key 注入校验
  `flutter build apk --debug --dart-define=AMAP_ANDROID_KEY=TEST123 --dart-define=AMAP_IOS_KEY=DUMMY --dart-define=AMAP_WEB_KEY=DUMMY`
  随后检查 `build/app/generated/source/buildConfig/debug/com/aidrun/aidrun_demo/BuildConfig.java` 与 `build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml`，两处都应包含 `TEST123`
- iOS 构建校验
  `flutter build ios --simulator --debug --no-codesign --dart-define=AMAP_ANDROID_KEY=DUMMY --dart-define=AMAP_WEB_KEY=DUMMY`
  当前 Apple Silicon 上的 iOS 26+ simulator 会提示 `AMapFoundation` 缺少 `arm64` 支持，构建可继续，但地图渲染与定位验收必须以真机为准

## 常见排查

- Flutter 运行后 Xcode 配置从 `3 Configurations Set` 变成 `2 Configurations Set`：
  - Flutter 3.41.5 会在 iOS build/run 时移除 `PBXProject "Runner"` 的 project-level base configuration，这是已知行为
  - 若你是通过 `./scripts/flutter_run_with_amap.sh` 启动，脚本退出时会自动尝试修复
  - 若你是手动执行 `flutter run` / `flutter build ios`，请运行 `./scripts/repair_ios_project_base_config.rb`
  - 修复后重新打开 Xcode，确认 Debug / Release / Profile 三栏都回到 `3 Configurations Set`
- iOS 真机调试推荐流程：
  - 先确认根目录 `.env` 中已经配置 `AMAP_IOS_KEY`
  - 再执行 `./scripts/run_ios_device_with_attach.sh --device <udid-or-name>`
  - 脚本会自动完成 `flutter build ios --config-only`、修复 project-level config、`xcodebuild install`、`devicectl` 拉起进程、`flutter attach`
  - 如果 USB 设备枚举切换导致自动 attach 没接上，脚本会打印可直接重试的 `flutter attach` 命令
  - 当前 Flutter 3.41.5 下，iOS 真机不推荐把 `flutter run` 当主入口，因为它可能在本次启动阶段直接白屏
- 地图区域只显示占位提示：
  - 检查是否传入 `AMAP_ANDROID_KEY`
  - 检查根目录 `.env` 中是否配置 `AMAP_IOS_KEY`
  - Android 若使用 `flutter run --dart-define=...`，可按上面的 BuildConfig/manifest 步骤确认原生层也已拿到 key
- 地点搜索只返回演示数据：
  - 检查 `AMAP_WEB_KEY` 是否配置
  - 先执行上面的 `inputtips` 请求，确认高德 Web Service key 返回 `"status":"1"`

## 校验命令

- 静态检查
  `flutter analyze`
- 测试
  `flutter test`
- Android Debug 构建
  `flutter build apk --debug`
- iOS Simulator Debug 构建
  `flutter build ios --simulator --debug --no-codesign`
- 修复 Flutter 漂移后的 Xcode project-level 配置
  `./scripts/repair_ios_project_base_config.rb`
- iOS 真机稳定启动并 attach
  `./scripts/run_ios_device_with_attach.sh --device 00008120-00045C500138201E`

## 说明

- `lib/` 为当前 Flutter 主代码。
- `android/` 与 `ios/` 为原生工程壳。
- 原 `src/` React 代码保留为迁移参考，不再作为主运行时入口。
