## 1. OpenSpec
- [x] 1.1 新增 `stabilize-ios-device-launch-with-attach` proposal、tasks、design 与 spec delta

## 2. iOS Stable Launch Script
- [x] 2.1 新增 `run_ios_device_with_attach.sh`，实现 config-only、repair、xcodebuild、devicectl、attach 串联
- [x] 2.2 支持 `--device`、`--target`、`--flavor`、`--dart-define`、`--dart-define-from-file`
- [x] 2.3 支持 `--dry-run` 和 `--no-attach`，方便排查

## 3. Documentation
- [x] 3.1 更新 README，把 iOS 真机推荐入口切换到新脚本
- [x] 3.2 明确 `flutter run` 在 iOS 真机上是非推荐路径

## 4. Validation
- [x] 4.1 通过 `openspec validate stabilize-ios-device-launch-with-attach --strict --no-interactive`
- [x] 4.2 通过 `zsh -n scripts/run_ios_device_with_attach.sh`
- [x] 4.3 通过 `./scripts/run_ios_device_with_attach.sh --device <udid-or-name> --dry-run`
- [x] 4.4 通过 `flutter analyze`
- [x] 4.5 通过 `flutter test`
- [x] 4.6 通过 `./scripts/run_ios_device_with_attach.sh --device <udid-or-name> --no-attach` 真机验证稳定安装并拉起
