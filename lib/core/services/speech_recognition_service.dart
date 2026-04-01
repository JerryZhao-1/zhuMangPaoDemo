import 'dart:async';

import 'package:aidrun_demo/core/models/place_suggestion.dart';
import 'package:aidrun_demo/core/models/run_request_input.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

abstract class SpeechRecognitionService {
  Future<RunRequestInput> listenForRunRequest();
  Future<String> listenForTranscript({
    Duration listenFor = const Duration(seconds: 6),
    Duration pauseFor = const Duration(seconds: 2),
  });
  String parseTimeLabel(String transcript);
}

class DeviceSpeechRecognitionService implements SpeechRecognitionService {
  DeviceSpeechRecognitionService() : _speechToText = SpeechToText();

  final SpeechToText _speechToText;

  @override
  Future<RunRequestInput> listenForRunRequest() async {
    final transcript = await listenForTranscript();
    if (transcript.trim().isEmpty) {
      return _fallback();
    }
    return _parseTranscript(transcript);
  }

  @override
  Future<String> listenForTranscript({
    Duration listenFor = const Duration(seconds: 6),
    Duration pauseFor = const Duration(seconds: 2),
  }) async {
    try {
      final available = await _speechToText.initialize();
      if (!available) {
        return '';
      }

      final completer = Completer<String>();
      var latestTranscript = '';

      await _speechToText.listen(
        localeId: 'zh_CN',
        listenFor: listenFor,
        pauseFor: pauseFor,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
        ),
        onResult: (SpeechRecognitionResult result) {
          latestTranscript = result.recognizedWords;
          if (result.finalResult && !completer.isCompleted) {
            completer.complete(latestTranscript);
          }
        },
      );

      final transcript = await completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () => latestTranscript,
      );

      await _speechToText.stop();
      if (transcript.trim().isEmpty) {
        return '';
      }
      return transcript;
    } catch (_) {
      try {
        await _speechToText.stop();
      } catch (_) {}
      return '';
    }
  }

  RunRequestInput _parseTranscript(String transcript) {
    var place = const PlaceSuggestion(
      name: '朝阳公园',
      address: '北京市朝阳区朝阳公园南路1号',
      latitude: 39.9435,
      longitude: 116.4830,
    );
    if (transcript.contains('奥森')) {
      place = const PlaceSuggestion(
        name: '奥森公园',
        address: '北京市朝阳区科荟路33号',
        latitude: 40.0150,
        longitude: 116.3900,
      );
    } else if (transcript.contains('天坛')) {
      place = const PlaceSuggestion(
        name: '天坛公园',
        address: '北京市东城区天坛东里甲1号',
        latitude: 39.8837,
        longitude: 116.4128,
      );
    } else if (transcript.contains('小区')) {
      place = const PlaceSuggestion(
        name: '小区跑道',
        address: '社区内部健身步道',
        latitude: 39.9100,
        longitude: 116.4100,
      );
    }

    return RunRequestInput(
      place: place,
      timeLabel: parseTimeLabel(transcript),
      transcript: transcript,
      usedFallback: false,
    );
  }

  @override
  String parseTimeLabel(String transcript) {
    var timeLabel = '现在出发';
    if (transcript.contains('半小时') || transcript.contains('30分')) {
      timeLabel = '30分钟后';
    } else if (transcript.contains('明天')) {
      timeLabel = '明天上午';
    } else if (transcript.contains('今天晚上')) {
      timeLabel = '今天晚上';
    } else if (transcript.trim().isNotEmpty) {
      timeLabel = transcript.trim();
    }
    return timeLabel;
  }

  RunRequestInput _fallback() {
    return const RunRequestInput(
      place: PlaceSuggestion(
        name: '朝阳公园',
        address: '北京市朝阳区朝阳公园南路1号',
        latitude: 39.9435,
        longitude: 116.4830,
      ),
      timeLabel: '现在出发',
      transcript: '',
      usedFallback: true,
    );
  }
}
