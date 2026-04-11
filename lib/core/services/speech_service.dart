import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract class SpeechService {
  Future<void> speak(String text);
  Future<void> stop();
}

class DeviceSpeechService implements SpeechService {
  static const MethodChannel _channel = MethodChannel('aidrun/speech');
  static const String _language = 'zh-CN';
  static const double _rate = 0.48;
  static const double _pitch = 1.0;

  Future<void>? _setupFuture;
  bool _enabled = _supportsPlatform;

  static bool get _supportsPlatform {
    if (kIsWeb) {
      return false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS && kDebugMode) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  Future<void> _ensureSetup() {
    if (!_enabled) {
      return Future.value();
    }
    return _setupFuture ??= () async {
      try {
        await _channel.invokeMethod<void>('configure', <String, dynamic>{
          'language': _language,
          'rate': _rate,
          'pitch': _pitch,
        });
      } catch (_) {
        _enabled = false;
      }
    }();
  }

  @override
  Future<void> speak(String text) async {
    if (!_enabled) {
      return;
    }
    try {
      await _ensureSetup();
      if (!_enabled) {
        return;
      }
      await _channel.invokeMethod<void>('stop');
      await _channel.invokeMethod<void>('speak', <String, dynamic>{
        'text': text,
      });
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    if (!_enabled) {
      return;
    }
    try {
      await _ensureSetup();
      if (!_enabled) {
        return;
      }
      await _channel.invokeMethod<void>('stop');
    } catch (_) {}
  }
}
