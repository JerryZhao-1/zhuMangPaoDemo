import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class IosRuntimeConfig {
  const IosRuntimeConfig({required this.amapIosKey});

  factory IosRuntimeConfig.fromChannelResult(Map<Object?, Object?>? values) {
    final amapIosKey = values?['amapIosKey'];
    return IosRuntimeConfig(amapIosKey: amapIosKey is String ? amapIosKey : '');
  }

  static const empty = IosRuntimeConfig(amapIosKey: '');

  final String amapIosKey;

  bool get hasAmapIosKey => amapIosKey.isNotEmpty;
}

class NativeRuntimeService {
  NativeRuntimeService._();

  static const MethodChannel _deviceChannel = MethodChannel('aidrun/device');
  static TargetPlatform? debugTargetPlatformOverride;
  static Future<IosRuntimeConfig>? _cachedIosRuntimeConfig;

  static bool get _isIosPlatform =>
      !kIsWeb &&
      (debugTargetPlatformOverride ?? defaultTargetPlatform) ==
          TargetPlatform.iOS;

  static bool get _isAndroidPlatform =>
      !kIsWeb &&
      (debugTargetPlatformOverride ?? defaultTargetPlatform) ==
          TargetPlatform.android;

  static Future<bool> isAndroidEmulator() async {
    if (!_isAndroidPlatform) {
      return false;
    }

    try {
      return await _deviceChannel.invokeMethod<bool>('isAndroidEmulator') ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<IosRuntimeConfig> getIosRuntimeConfig({bool refresh = false}) {
    if (!_isIosPlatform) {
      return Future.value(IosRuntimeConfig.empty);
    }
    if (!refresh && _cachedIosRuntimeConfig != null) {
      return _cachedIosRuntimeConfig!;
    }

    _cachedIosRuntimeConfig = _loadIosRuntimeConfig();
    return _cachedIosRuntimeConfig!;
  }

  static Future<IosRuntimeConfig> _loadIosRuntimeConfig() async {
    try {
      final values = await _deviceChannel.invokeMapMethod<Object?, Object?>(
        'getIosRuntimeConfig',
      );
      return IosRuntimeConfig.fromChannelResult(values);
    } catch (_) {
      return IosRuntimeConfig.empty;
    }
  }

  static void debugReset() {
    debugTargetPlatformOverride = null;
    _cachedIosRuntimeConfig = null;
  }
}
