# Change: stabilize-ios-device-launch-with-attach

## Why
在 Flutter 3.41.5 下，iOS `flutter run` 会触发 `ProjectBaseConfigurationMigration`，并且在真机路径上仍可能出现“一运行就白屏”的问题。当前仓库虽然已经提供了 `PBXProject "Runner"` base configuration 的修复脚本，但那只能在 Flutter CLI 退出后恢复 Xcode 配置，无法保证本次真机启动就成功。因此需要提供一条稳定的 iOS 真机调试入口，绕开 Flutter iOS `run` 的原生启动链。

## What Changes
- 新增 iOS 真机稳定调试脚本：`xcodebuild/devicectl` 启动 + `flutter attach`
- 脚本先执行 `flutter build ios --config-only` 生成 Flutter/iOS 构建配置，再修复 `pbxproj`，然后构建、安装、启动并附加调试
- README 更新为把 iOS 真机主入口改成新脚本，`flutter run` 明确降级为非推荐路径
- OpenSpec 新增 iOS 调试工作流要求，明确仓库提供稳定真机启动命令

## Impact
- Affected specs: `ios-debug-workflow`
- Affected code: `scripts/run_ios_device_with_attach.sh`, `README.md`
