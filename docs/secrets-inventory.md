# Secrets Inventory

## Active Runtime Config

| Service | Scope | Current Source | Git Status | Notes |
| --- | --- | --- | --- | --- |
| Firebase Web config | `src/` Vite reference app | root `.env` `VITE_FIREBASE_*` | ignored | Replaced tracked `firebase-applet-config.json` |
| AMap Android key | Flutter app and scripts | root `.env` `AMAP_ANDROID_KEY` or `--dart-define` | ignored when stored in `.env` | Main app already injected through Gradle and scripts |
| AMap iOS key | Flutter iOS native shell | root `.env` via `ios/Flutter/*.xcconfig` include chain | ignored | Injected into Info.plist at build time |
| AMap Web key | Flutter place search | root `.env` `AMAP_WEB_KEY` or `--dart-define` | ignored when stored in `.env` | Used by search fallback path |

## Removed From Repository

| Service | Previous Location | Action |
| --- | --- | --- |
| Firebase Web API key | `firebase-applet-config.json` | Migrated to root `.env` and file is now ignored |
| AMap example Android/iOS keys | `third_party/amap_flutter_location/example/lib/main.dart` | Replaced with `String.fromEnvironment(...)` |
| AMap example Android/iOS keys | `third_party/amap_flutter_map/example/lib/const_config.dart` | Replaced with `String.fromEnvironment(...)` |
| AMap example iOS key | `third_party/amap_flutter_map/example/ios/Runner/AppDelegate.m` | Removed hardcoded native assignment |
| AMap example Android key comment | `third_party/amap_flutter_map/example/android/app/src/main/AndroidManifest.xml` | Removed literal sample key |
