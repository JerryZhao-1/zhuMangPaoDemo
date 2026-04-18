import 'dart:io';

import 'package:aidrun_demo/core/services/native_runtime_service.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:flutter/foundation.dart';

class AMapConfig {
  const AMapConfig({
    required this.androidKey,
    required this.iosKey,
    required this.webKey,
  });

  static TargetPlatform? debugTargetPlatformOverride;
  static bool debugIgnoreFlutterTestEnvironment = false;

  factory AMapConfig.fromEnvironment() {
    return const AMapConfig(
      androidKey: String.fromEnvironment('AMAP_ANDROID_KEY'),
      iosKey: '',
      webKey: String.fromEnvironment('AMAP_WEB_KEY'),
    );
  }

  final String androidKey;
  final String iosKey;
  final String webKey;

  bool get hasAndroidKey => androidKey.isNotEmpty;
  bool get hasIosKey => iosKey.isNotEmpty;
  bool get hasNativeKeys => hasAndroidKey || hasIosKey;
  bool get hasWebKey => webKey.isNotEmpty;
  bool get isAndroidPlatform =>
      !kIsWeb &&
      (debugTargetPlatformOverride ?? defaultTargetPlatform) ==
          TargetPlatform.android;
  bool get isIosPlatform =>
      !kIsWeb &&
      (debugTargetPlatformOverride ?? defaultTargetPlatform) ==
          TargetPlatform.iOS;

  bool get supportsNativeMap {
    if (kIsWeb) {
      return false;
    }
    if (!debugIgnoreFlutterTestEnvironment &&
        Platform.environment.containsKey('FLUTTER_TEST')) {
      return false;
    }
    if (isAndroidPlatform) {
      return hasAndroidKey;
    }
    if (isIosPlatform) {
      return true;
    }
    return false;
  }

  AMapApiKey? get apiKey {
    if (!supportsNativeMap) {
      return null;
    }
    return AMapApiKey(
      androidKey: hasAndroidKey ? androidKey : null,
      iosKey: hasIosKey ? iosKey : null,
    );
  }

  Future<AMapApiKey?> resolveNativeApiKey() async {
    if (!supportsNativeMap) {
      return null;
    }

    if (isAndroidPlatform) {
      if (!hasAndroidKey) {
        return null;
      }
      return AMapApiKey(androidKey: androidKey);
    }

    if (isIosPlatform) {
      final runtimeConfig = await NativeRuntimeService.getIosRuntimeConfig();
      if (!runtimeConfig.hasAmapIosKey) {
        return null;
      }
      return AMapApiKey(iosKey: runtimeConfig.amapIosKey);
    }

    return null;
  }

  static const privacyStatement = AMapPrivacyStatement(
    hasAgree: true,
    hasContains: true,
    hasShow: true,
  );
}
