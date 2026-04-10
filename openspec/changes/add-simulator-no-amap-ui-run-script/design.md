## Context
当前工程已经具备“缺少 key 时降级”的能力，但运行模式仍然隐式依赖 key 是否为空。这样会把 demo 行为和生产接入行为耦合在一起，后续如果某个页面只检查 key 或者某个服务改成默认尝试联网，请求路径就可能重新触发 AMap 相关逻辑。

## Goals
- 提供一个稳定的模拟器 UI 联调入口，不依赖任何高德 key
- 用统一配置对象显式识别 no-AMap demo mode
- 保证地图、定位、地点搜索在 demo mode 下都直接走降级能力

## Non-Goals
- 不解决 Apple Silicon 上 iOS 模拟器对 `amap_flutter_map` Pod 的架构兼容问题
- 不在 demo mode 中验证真实地图、真实定位或真实 POI 搜索

## Decisions
### 1. 单独脚本启动 demo mode
- 新增 `scripts/flutter_run_ui_demo.sh`
- 脚本注入 `--dart-define=DISABLE_AMAP=true`
- 脚本同时清空 `AMAP_ANDROID_KEY`、`AMAP_IOS_KEY`、`AMAP_WEB_KEY`
- 脚本透传额外的 `flutter run` 参数，优先支持 Android 模拟器

### 2. 统一配置入口识别 demo mode
- 在 `AMapConfig` 中增加布尔开关 `disableAMap`
- `supportsNativeMap`、`hasWebKey`、`apiKey` 等能力判断优先受该开关约束
- 页面与服务只依赖配置对象，不直接判断脚本来源

### 3. 统一 fallback 行为
- 地图组件在 demo mode 下始终渲染 fallback 占位
- 定位服务在 demo mode 下直接返回 `null`
- 地点搜索服务在 demo mode 下直接返回本地演示候选，不发起网络请求

## Risks
- 如果 demo mode 仅改脚本、不改统一配置入口，后续代码容易绕过约束重新访问 AMap
- iOS 平台仍可能因为第三方 Pod 架构问题无法完成模拟器联调

## Mitigations
- 用 `DISABLE_AMAP` 作为单一控制入口，并在配置对象层集中收口
- README 明确 Android 模拟器是当前保障目标，并注明 iOS 模拟器限制
