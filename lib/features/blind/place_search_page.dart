import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/models/place_suggestion.dart';
import 'package:aidrun_demo/core/services/amap_config.dart';
import 'package:aidrun_demo/core/services/amap_location_service.dart';
import 'package:aidrun_demo/core/theme/app_theme.dart';
import 'package:aidrun_demo/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BlindPlaceSearchPage extends ConsumerStatefulWidget {
  const BlindPlaceSearchPage({super.key});

  @override
  ConsumerState<BlindPlaceSearchPage> createState() => _BlindPlaceSearchPageState();
}

class _BlindPlaceSearchPageState extends ConsumerState<BlindPlaceSearchPage> {
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _queryFocusNode = FocusNode();

  bool _loading = false;
  List<PlaceSuggestion> _results = const [];
  DeviceLocation? _currentLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(speechServiceProvider).speak(
            '地点搜索页面。你可以输入文字，或者点击语音按钮搜索地点。',
          );
      final location = await ref.read(appLocationServiceProvider).locateOnce();
      if (!mounted) {
        return;
      }
      setState(() => _currentLocation = location);
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    _queryFocusNode.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      return;
    }
    setState(() => _loading = true);
    final results = await ref.read(placeSearchServiceProvider).search(
          query,
          near: _currentLocation,
        );
    if (!mounted) {
      return;
    }
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  Future<void> _searchByVoice() async {
    await ref.read(speechServiceProvider).speak('请说出想去的地点名称。');
    final transcript = await ref.read(speechRecognitionServiceProvider).listenForTranscript();
    if (!mounted || transcript.trim().isEmpty) {
      return;
    }
    _queryController.text = transcript.trim();
    await _search();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(aMapConfigProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: AppTheme.yellow,
        title: const Text('搜索地点'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!config.hasWebKey)
            const SectionCard(
              color: Color(0xFF1F2937),
              child: Text(
                '当前未配置高德 Web Service Key，地点候选将回退为本地演示数据。',
                style: TextStyle(color: Colors.white),
              ),
            ),
          if (!config.hasWebKey) const SizedBox(height: 12),
          SectionCard(
            child: Column(
              children: [
                TextField(
                  controller: _queryController,
                  focusNode: _queryFocusNode,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: '输入公园、小区、地标名称',
                    suffixIcon: IconButton(
                      onPressed: _search,
                      icon: const Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _searchByVoice,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.yellow,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    icon: const Icon(Icons.mic),
                    label: const Text(
                      '语音搜索地点',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_results.isEmpty)
            const SectionCard(
              color: AppTheme.zinc,
              child: Text(
                '还没有搜索结果。请输入关键词，或使用语音搜索。',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          else
            ..._results.map(
              (place) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SectionCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(child: Icon(Icons.place)),
                    title: Text(
                      place.name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(place.address.isEmpty ? '未提供详细地址' : place.address),
                    ),
                    trailing: FilledButton(
                      onPressed: () => context.pop(place),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('选择'),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
