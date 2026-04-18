## ADDED Requirements
### Requirement: Repository Provides Stable iOS Device Launch Workflow
The system SHALL provide a repository-level iOS device debug workflow that avoids Flutter iOS `run` as the primary launch path.

#### Scenario: Stable device debug command builds and launches app
- **WHEN** a developer runs the repository's iOS device launch script with a connected device identifier
- **THEN** the script updates Flutter iOS configuration with `flutter build ios --config-only`
- **AND** repairs any `PBXProject "Runner"` project-level base configuration drift
- **AND** performs a Debug device build through Xcode tools
- **AND** installs and launches the app on the selected device

#### Scenario: Stable device debug command reattaches Flutter tooling
- **WHEN** the app has been launched on the selected iOS device through the stable launch script
- **THEN** the script attaches Flutter tooling to the running app
- **AND** the workflow does not require `flutter run` to start the iOS process

### Requirement: iOS flutter run Is Documented As Non-Primary Path
The system SHALL document that `flutter run` on iOS devices is not the recommended primary debug entrypoint for this repository under Flutter 3.41.5.

#### Scenario: README guides developers to stable iOS device workflow
- **WHEN** a developer follows the repository README for iOS real-device debugging
- **THEN** they are directed to the stable launch-and-attach script first
- **AND** the README explains that `flutter run` may still trigger project configuration drift and launch instability on iOS devices
