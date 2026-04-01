import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/models/place_suggestion.dart';
import 'package:aidrun_demo/core/models/run_request_input.dart';
import 'package:aidrun_demo/core/theme/app_theme.dart';
import 'package:aidrun_demo/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RequestRunPage extends ConsumerStatefulWidget {
  const RequestRunPage({super.key});

  @override
  ConsumerState<RequestRunPage> createState() => _RequestRunPageState();
}

class _RequestRunPageState extends ConsumerState<RequestRunPage> {
  PlaceSuggestion? _selectedPlace;
  String _timeLabel = '现在出发';
  bool _submitting = false;
  bool _listeningTime = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(speechServiceProvider).speak(
            '预约界面。请先选择地点，再输入出发时间。',
          );
    });
  }

  Future<void> _selectPlace() async {
    final place = await context.push<PlaceSuggestion>('/blind/request/place');
    if (!mounted || place == null) {
      return;
    }
    setState(() => _selectedPlace = place);
    await ref.read(speechServiceProvider).speak(
          '已选择地点${place.name}。接下来请输入或语音说出出发时间。',
        );
  }

  Future<void> _listenForTime() async {
    if (_listeningTime) {
      return;
    }
    setState(() => _listeningTime = true);
    final speech = ref.read(speechServiceProvider);
    await speech.speak('请说出出发时间，例如三十分钟后，或者明天上午。');
    final transcript = await ref.read(speechRecognitionServiceProvider).listenForTranscript(
          listenFor: const Duration(seconds: 5),
        );
    if (!mounted) {
      return;
    }
    setState(() {
      _timeLabel = transcript.trim().isEmpty
          ? '现在出发'
          : ref.read(speechRecognitionServiceProvider).parseTimeLabel(transcript);
      _listeningTime = false;
    });
    await speech.speak('已设置出发时间$_timeLabel。');
  }

  Future<void> _submit() async {
    final place = _selectedPlace;
    if (place == null || _submitting) {
      return;
    }
    setState(() => _submitting = true);
    final run = ref.read(appStateControllerProvider.notifier).createBlindRun(
          RunRequestInput(
            place: place,
            timeLabel: _timeLabel,
          ),
        );
    await ref.read(speechServiceProvider).speak('预约成功，正在为您匹配志愿者。');
    if (!mounted) {
      return;
    }
    context.go('/blind/run/${run.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () => context.go('/blind'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.zinc,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text(
                    '返回首页',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LargeActionButton(
              onPressed: _selectPlace,
              backgroundColor: AppTheme.yellow,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.place, size: 120),
              title: _selectedPlace == null ? '先选择地点' : '重新选择地点',
              subtitle: _selectedPlace?.summary ?? '支持语音搜索和文字搜索',
            ),
            const SizedBox(height: 16),
            SectionCard(
              color: AppTheme.zinc,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '出发时间',
                    style: TextStyle(
                      color: AppTheme.yellow,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _timeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _listenForTime,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      icon: Icon(_listeningTime ? Icons.graphic_eq : Icons.mic),
                      label: Text(
                        _listeningTime ? '正在收听时间...' : '语音输入时间',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final option in const ['现在出发', '30分钟后', '明天上午', '今天晚上'])
                        ChoiceChip(
                          label: Text(option),
                          selected: _timeLabel == option,
                          onSelected: (_) => setState(() => _timeLabel = option),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedPlace == null ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white24,
                  disabledForegroundColor: Colors.white54,
                  padding: const EdgeInsets.symmetric(vertical: 22),
                ),
                child: Text(
                  _selectedPlace == null
                      ? '请先选择地点'
                      : (_submitting ? '正在提交...' : '确认预约'),
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
