# Change: add-volunteer-map-order-sheet-drag-states

## Why
当前志愿者地图页的接单菜单固定占据约 56% 的屏幕高度，地图可视面积被锁定，无法在“看地图”和“看订单”之间切换重心。需要让菜单支持拖拽，在不改变默认进入状态的前提下补上下收与全展开能力。

## What Changes
- 志愿者地图页的接单菜单改为可拖拽的底部面板
- 支持三档吸附：下收 `0.16`、默认 `0.56`、全展开 `0.92`
- 下收态只保留拖拽条和“附近需求(x)”标题
- 全展开允许覆盖顶部“在线 - 正在寻找附近需求”状态卡
- 默认进入地图页或重新进入地图 tab 时，面板回到当前默认高度

## Impact
- Affected specs: `map-experience`
- Affected code: `lib/features/volunteer/volunteer_dashboard_page.dart`, `test/widget_test.dart`
