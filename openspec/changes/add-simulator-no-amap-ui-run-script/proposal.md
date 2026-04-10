# Change: add-simulator-no-amap-ui-run-script

## Why
当前真机上的 AMap 启动链路不稳定，iOS 模拟器又受原生 Pod 架构限制，缺少一个稳定的 UI 联调入口。为了让地图相关页面和预约流程可以在模拟器上持续联调，需要一个不依赖任何 AMap key 或 AMap Web Service 的显式 demo 模式。

## What Changes
- 新增一个无 AMap 的模拟器运行脚本
- 新增一个显式的 no-AMap 运行模式开关
- 在 no-AMap 模式下，地图、定位、地点搜索统一走现有 fallback
- README 增加模拟器 UI 联调说明

## Impact
- Affected specs: `flutter-frontend-migration`
- Affected code: `scripts/`, `lib/core/services/amap_config.dart`, `lib/core/services/amap_location_service.dart`, `lib/core/services/place_search_service.dart`, `lib/core/widgets/amap_map_view.dart`, `lib/features/blind/place_search_page.dart`, `lib/features/volunteer/`, `README.md`
