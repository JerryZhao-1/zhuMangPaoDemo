# Change: fix-ios-xcode-config-drift

## Why
Flutter 3.41.5 在 iOS `build/run` 期间会执行 `ProjectBaseConfigurationMigration`，把 `PBXProject "Runner"` 的 project-level `Debug/Release` base configuration 清掉，导致开发者从 Flutter CLI 切回 Xcode 时配置界面从 `3 Configurations Set` 变成 `2 Configurations Set`，随后出现白屏或无法正常启动。与此同时，iOS 高德 key 还同时存在 `Info.plist/.xcconfig` 与 Flutter `--dart-define` 两条来源链路，会继续放大 CLI 与 Xcode 路径的状态分叉。

## What Changes
- 新增显式修复脚本，恢复 `PBXProject "Runner"` 的 `Debug/Release/Profile` base configuration
- 更新 Flutter 启动脚本，在退出后自动尝试修复 iOS Xcode project-level 配置
- 收敛 iOS 高德 key 到原生配置链路，Flutter 运行时改为读取同一份原生值
- 更新 README，记录 Flutter 3.41.5 的已知配置漂移行为与修复命令

## Impact
- Affected specs: `map-experience`
- Affected code: `ios/Runner/AppDelegate.swift`, `lib/core/services/amap_config.dart`, `lib/core/services/native_runtime_service.dart`, `scripts/flutter_run_with_amap.sh`, `README.md`
