## ADDED Requirements
### Requirement: Volunteer Dashboard Order Sheet Supports Dragging
The system SHALL let the volunteer dashboard order sheet snap between collapsed, default, and expanded states without changing the default entry state.

#### Scenario: Dashboard enters with current default sheet height
- **WHEN** a volunteer opens the dashboard map tab
- **THEN** the order sheet starts at the current default middle height
- **AND** the visible content matches the existing default order list state

#### Scenario: Sheet collapses to header-only state
- **WHEN** the volunteer drags the order sheet downward
- **THEN** the sheet snaps to the collapsed state
- **AND** only the drag handle and `附近需求(x)` title remain visible

#### Scenario: Sheet expands to near full-screen state
- **WHEN** the volunteer drags the order sheet upward
- **THEN** the sheet snaps to the expanded state
- **AND** the sheet may cover the online status card at the top of the map

#### Scenario: Expanded sheet scrolls order content
- **WHEN** the order sheet is expanded and the list content exceeds the visible area
- **THEN** the volunteer can continue scrolling the order list
- **AND** the order accept button behavior remains unchanged
