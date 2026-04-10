## ADDED Requirements
### Requirement: Cross-Platform Default Text Color Parity
The system SHALL render default light-theme text with the same black foreground on Android and iOS for shared Flutter screens.

#### Scenario: Launch app on iOS with system dark mode enabled
- **WHEN** the user launches the app on iOS while the device is using dark mode
- **THEN** shared Flutter screens still use the app's light theme
- **AND** text that relies on the global theme renders in brand black instead of a light foreground color

#### Scenario: Launch app on Android and iOS
- **WHEN** the same shared Flutter screen is opened on Android and iOS
- **THEN** default title and body text use the same black foreground color on both platforms
