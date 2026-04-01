import 'package:flutter_tts/flutter_tts.dart';

abstract class SpeechService {
  Future<void> speak(String text);
  Future<void> stop();
}

class DeviceSpeechService implements SpeechService {
  DeviceSpeechService() {
    _tts.setLanguage('zh-CN');
    _tts.setSpeechRate(0.48);
    _tts.setPitch(1.0);
  }

  final FlutterTts _tts = FlutterTts();

  @override
  Future<void> speak(String text) async {
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
