## 1. OpenSpec
- [x] 1.1 新增 `add-simulator-no-amap-ui-run-script` proposal、design、tasks 与 spec delta

## 2. Runtime
- [x] 2.1 新增 no-AMap 模拟器运行脚本并支持透传 `flutter run` 参数
- [x] 2.2 在 `AMapConfig` 中增加显式 demo mode 开关
- [x] 2.3 统一地图、定位、地点搜索在 demo mode 下的 fallback 行为

## 3. Docs and Validation
- [x] 3.1 更新 README 中的模拟器 UI 联调说明
- [x] 3.2 补充 no-AMap 模式相关测试
- [x] 3.3 通过 `flutter test`
- [x] 3.4 通过 `openspec validate add-simulator-no-amap-ui-run-script --strict --no-interactive`
