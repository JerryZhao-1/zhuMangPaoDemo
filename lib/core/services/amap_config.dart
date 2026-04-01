import 'dart:io';

import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:flutter/foundation.dart';

class AMapConfig {
  const AMapConfig({
    required this.androidKey,
    required this.iosKey,
    required this.webKey,
  });

  factory AMapConfig.fromEnvironment() {
    return const AMapConfig(
      androidKey: String.fromEnvironment('AMAP_ANDROID_KEY'),
      iosKey: String.fromEnvironment('AMAP_IOS_KEY'),
      webKey: String.fromEnvironment('AMAP_WEB_KEY'),
    );
  }

  final String androidKey;
  final String iosKey;
  final String webKey;

  bool get hasNativeKeys => androidKey.isNotEmpty && iosKey.isNotEmpty;
  bool get hasWebKey => webKey.isNotEmpty;

  bool get supportsNativeMap {
    if (kIsWeb) {
      return false;
    }
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return false;
    }
    return hasNativeKeys && (Platform.isAndroid || Platform.isIOS);
  }

  AMapApiKey? get apiKey {
    if (!supportsNativeMap) {
      return null;
    }
    return AMapApiKey(
      androidKey: androidKey,
      iosKey: iosKey,
    );
  }

  static const privacyStatement = AMapPrivacyStatement(
    hasAgree: true,
    hasContains: true,
    hasShow: true,
  );
}
