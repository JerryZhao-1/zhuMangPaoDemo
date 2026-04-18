## MODIFIED Requirements
### Requirement: Volunteer Map Uses AMap
The system SHALL render volunteer-facing map surfaces with AMap on Android and iOS when valid native AMap keys are configured, with iOS runtime key resolution using the same native configuration chain as Xcode.

#### Scenario: iOS Flutter runtime uses native AMap key
- **WHEN** the app runs on iOS and `AMAP_IOS_KEY` is configured through `Amap.local.xcconfig`
- **THEN** AppDelegate initializes the native AMap SDK from `Info.plist`
- **AND** Flutter map and location features read the same iOS key through native runtime configuration instead of `--dart-define`

### Requirement: AMap Degrades Gracefully Without Runtime Configuration
The system SHALL provide a diagnosable fallback when AMap keys, privacy consent, or permissions are unavailable.

#### Scenario: Missing native iOS key at runtime
- **WHEN** the app runs on iOS without a native `AMAP_IOS_KEY`
- **THEN** the app does not attempt to create the native map view
- **AND** one-time location lookup returns no location rather than crashing or showing a blank screen

## ADDED Requirements
### Requirement: Flutter iOS Build Drift Can Be Repaired Explicitly
The system SHALL provide a repository-level recovery path when Flutter removes `PBXProject "Runner"` base configuration references during iOS build or run.

#### Scenario: Manual Flutter build removes project-level base configuration
- **WHEN** a developer runs `flutter run` or `flutter build ios` and Flutter clears the project-level `Debug` / `Release` base configuration
- **THEN** the repository provides a repair command that restores the `PBXProject "Runner"` `Debug` / `Release` / `Profile` base configuration references
- **AND** the command does not modify any target-level configuration references

#### Scenario: Scripted Flutter run auto-recovers Xcode configuration
- **WHEN** a developer launches the app with `./scripts/flutter_run_with_amap.sh`
- **THEN** the script repairs the iOS project-level base configuration when it exits
- **AND** Xcode can be reopened and run with `3 Configurations Set` restored for Debug, Release, and Profile
