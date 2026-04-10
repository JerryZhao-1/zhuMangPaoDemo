## Context
志愿者地图页当前采用 `Stack + 固定高度 Container` 叠加订单菜单，地图底图是原生高德 `PlatformView`。本次改动只需要调整地图页订单面板交互，不修改行程页、不改业务数据流。

## Goals
- 让志愿者地图页的订单菜单支持下收、默认、全展开三档吸附
- 保持默认进入地图页时的视觉状态不变
- 在下收态隐藏订单列表，扩大地图可视面积

## Non-Goals
- 不改志愿者行程详情页
- 不改接单业务逻辑、地图 marker 渲染或地图默认中心点
- 不做连续自由停靠，只支持固定三档吸附

## Decisions
### 1. 使用 DraggableScrollableSheet 承载订单面板
- 使用 `DraggableScrollableSheet` 实现底部菜单
- `snap: true`，`expand: false`
- 档位固定为 `0.16`、`0.56`、`0.92`

### 2. 用 sheet extent 驱动内容显隐
- 通过 `DraggableScrollableNotification` 追踪当前 extent
- 当面板处于下收态时，只显示拖拽条与“附近需求(x)”标题
- 非下收态显示当前行程卡片、待接单列表与接单按钮

### 3. 保持地图和面板手势边界简单
- 地图区域继续使用原生高德地图手势
- 只有面板覆盖区域接管纵向拖拽
- 使用 `DraggableScrollableSheet` 提供的 `ScrollController` 驱动订单列表，保证全展开后继续滚动列表而不是卡死在面板尺寸变化上

## Risks
- `PlatformView` 地图与 sheet 拖拽同时存在时，边界区域手势行为可能不直观
- 测试环境下无法验证真实地图手势，只能验证 sheet 的 widget 行为

## Mitigations
- 不对地图 wrapper 增加额外交互改造，降低手势冲突面
- 为 sheet 根节点和标题区域增加稳定 key，确保 widget test 可以稳定断言面板位置和内容显隐
