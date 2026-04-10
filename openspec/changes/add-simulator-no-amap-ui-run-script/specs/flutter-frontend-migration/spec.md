## ADDED Requirements
### Requirement: Simulator UI Demo Mode Without AMap
The system SHALL provide an explicit no-AMap simulator demo mode so developers can run and validate the Flutter UI without supplying any AMap native key or Web Service key.

#### Scenario: Launch app in simulator demo mode
- **WHEN** 开发者使用 no-AMap 模拟器脚本启动应用
- **THEN** 应用可以在模拟器中正常进入 UI
- **AND** 不要求提供任何 AMap key

#### Scenario: Volunteer map falls back in demo mode
- **WHEN** 志愿者进入地图页
- **THEN** 地图区域显示降级占位
- **AND** 订单列表与其余 UI 仍可交互

#### Scenario: Blind place search uses local suggestions in demo mode
- **WHEN** 盲人跑者进入地点搜索流程
- **THEN** 搜索结果来自本地演示数据
- **AND** 预约流程仍可完成
