## Context
当前项目已经修复了 iOS AMap key 的来源分叉，也提供了 `repair_ios_project_base_config.rb` 来恢复 Flutter 改坏的 Xcode project-level config。但这些修复都无法保证 `flutter run` 在真机上的本次启动就稳定成功。用户已经验证，手动把 Xcode config 改回完整后，通过 Xcode 启动可以正常打开 App，这说明稳定入口应当切换到 Xcode 驱动的构建/启动链，再由 Flutter attach 接回调试能力。

## Goals
- 提供一条稳定、可重复的 iOS 真机调试入口
- 保留 Flutter 的 config-only 产物生成与 Dart define 支持
- 避免依赖 Flutter iOS `run` 的原生启动路径

## Non-Goals
- 不修改 Flutter SDK 或 fork `flutter_tools`
- 不改变现有 AMap 业务配置模型
- 不移除现有 `flutter_run_with_amap.sh`

## Decisions
### 1. 真机启动链切换为 build + install + launch + attach
- 用 `flutter build ios --config-only` 生成 `Generated.xcconfig`、ephemeral 文件和 Dart define
- 立刻运行 `repair_ios_project_base_config.rb`，消除 Flutter 对 `PBXProject "Runner"` 的漂移
- 用 `xcodebuild install` 进行 Debug 真机构建与安装
- 用 `xcrun devicectl` 清理旧进程并拉起 App
- 用 `flutter attach` 接回热重载和日志

### 2. iOS key 继续只走原生配置
- 新脚本不传 `AMAP_IOS_KEY` 的 Dart define
- 若命令行传入 `--dart-define=AMAP_IOS_KEY=...`，脚本仅告警，不把它作为 iOS 真值
- 若 `.env.amap.local` 存在且未显式传入 `AMAP_WEB_KEY`，脚本默认补上 Web Service key

## Risks
- `xcodebuild` 在某些本机环境可能要求额外签名或 workspace 清理
- `flutter attach` 若未在 App 启动后及时发现 VM Service，可能需要等待或手动重试

## Mitigations
- 脚本暴露 `--device-timeout` 和 `--attach-arg`，保留 attach 调参空间
- 脚本提供 `--dry-run` 和 `--no-attach`，方便先验证构建/安装/启动链
- 脚本会在 attach 前等待设备重新出现在 `flutter devices` 中；若自动 attach 仍失败，会打印可直接重试的 attach 命令
- README 记录新脚本的推荐流程与 `flutter run` 的非推荐状态
