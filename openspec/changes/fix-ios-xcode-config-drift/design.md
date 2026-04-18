## Context
当前项目在 iOS 上同时依赖两类配置：一类是 Xcode 原生的 `xcconfig -> Info.plist` 链路，另一类是 Flutter CLI 通过 `DART_DEFINES` 注入的运行时参数。Flutter 3.41.5 在 iOS build/run 时还会主动移除 `PBXProject "Runner"` 的 project-level base configuration，导致开发流程在 Flutter CLI 和 Xcode 之间来回切换时变得不稳定。

## Goals
- 让 `flutter run`/`flutter build ios` 后的 Xcode 工程可恢复到可直接运行状态
- 让 iOS 高德地图与定位 SDK 只依赖原生单一来源 key
- 保持 Android 和 Web 现有 key 注入方式不变

## Non-Goals
- 不修改 Flutter SDK 源码
- 不引入新的密钥管理方案
- 不改变现有 iOS Debug 下地图占位的产品策略

## Decisions
### 1. iOS AMap key 收敛到原生运行时
- `AMAP_IOS_KEY` 继续保留在 `ios/Flutter/Amap.local.xcconfig`
- AppDelegate 继续从 `Info.plist` 初始化 AMap SDK
- Flutter 侧通过 method channel 读取原生运行时配置，不再把 `String.fromEnvironment('AMAP_IOS_KEY')` 作为 iOS 真值

### 2. 漂移修复走仓库脚本而不是改 Flutter SDK
- 新增仓库内脚本，幂等修复 `PBXProject "Runner"` 的 project-level `Debug/Release/Profile` base configuration
- 启动脚本退出时自动触发修复，覆盖最常见的开发路径
- 对手动执行 `flutter run` / `flutter build ios` 的情况，通过 README 暴露显式修复命令

## Risks
- iOS method channel 若未在 Flutter engine 初始化后注册，Dart 侧会读不到原生 key
- 修复脚本若误匹配 target-level 配置，可能破坏现有 Pod 或 Runner target 设置

## Mitigations
- 设备运行时 channel 只绑定已有 `aidrun/device` 通道，并在隐式 Flutter engine 初始化时注册
- 修复脚本只修改 `PBXProject "Runner"` 的 3 个 configuration block，不触碰 target-level 配置
