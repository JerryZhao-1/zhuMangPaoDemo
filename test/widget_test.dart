import 'package:aidrun_demo/app/aidrun_app.dart';
import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/app/state/app_state_controller.dart';
import 'package:aidrun_demo/core/models/place_suggestion.dart';
import 'package:aidrun_demo/core/models/run_request_input.dart';
import 'package:aidrun_demo/core/services/amap_config.dart';
import 'package:aidrun_demo/core/services/amap_location_service.dart';
import 'package:aidrun_demo/core/services/place_search_service.dart';
import 'package:aidrun_demo/core/services/speech_service.dart';
import 'package:aidrun_demo/core/theme/app_theme.dart';
import 'package:aidrun_demo/features/blind/place_search_page.dart';
import 'package:aidrun_demo/features/blind/blind_active_run_page.dart';
import 'package:aidrun_demo/features/volunteer/volunteer_dashboard_page.dart';
import 'package:aidrun_demo/core/models/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows role selection on first launch', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const AidRunApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('我是盲人跑者'), findsOneWidget);
    expect(find.text('我是志愿者'), findsOneWidget);
  });

  testWidgets('app stays in light theme regardless of system theme', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const AidRunApp(),
      ),
    );

    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.light);
  });

  testWidgets('light theme uses brand black as default text foreground', (
    tester,
  ) async {
    Color? bodyColor;
    Color? titleColor;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) {
            final textTheme = Theme.of(context).textTheme;
            bodyColor = textTheme.bodyMedium?.color;
            titleColor = textTheme.headlineMedium?.color;
            return const Scaffold(body: Text('主题默认黑字'));
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(bodyColor, AppTheme.black);
    expect(titleColor, AppTheme.black);
  });

  testWidgets('restores blind session route', (tester) async {
    SharedPreferences.setMockInitialValues({
      'aidrun_role': UserRole.blind.name,
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const AidRunApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('发起预约'), findsOneWidget);
  });

  testWidgets(
    'blind active run page refreshes after simulated volunteer accept',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: BlindActiveRunPage(runId: 'mock-1')),
        ),
      );

      expect(find.text('[测试] 模拟志愿者接单'), findsOneWidget);
      expect(find.text('正在匹配志愿者'), findsOneWidget);

      await tester.tap(find.text('[测试] 模拟志愿者接单'));
      await tester.pump();

      expect(find.text('志愿者已接单'), findsOneWidget);
      expect(find.text('联系志愿者'), findsOneWidget);
    },
  );

  testWidgets(
    'volunteer dashboard refreshes pending and active sections after accept',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({
        'aidrun_role': UserRole.volunteer.name,
      });
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: VolunteerDashboardPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('附近需求 (3)'), findsOneWidget);
      expect(find.text('当前行程进行中'), findsNothing);

      container.read(appStateControllerProvider.notifier).acceptRun('mock-1');
      await tester.pumpAndSettle();

      expect(find.text('附近需求 (2)'), findsOneWidget);
      expect(find.text('当前行程进行中'), findsOneWidget);
    },
  );

  testWidgets(
    'volunteer dashboard sheet supports collapsed and expanded snap states',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({
        'aidrun_role': UserRole.volunteer.name,
      });
      final preferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: const MaterialApp(home: VolunteerDashboardPage()),
        ),
      );
      await tester.pumpAndSettle();

      final sheetFinder = find.byKey(const Key('volunteer-order-sheet'));
      final headerFinder = find.byKey(
        const Key('volunteer-order-sheet-header'),
      );

      final defaultTop = tester.getTopLeft(sheetFinder).dy;
      expect(find.text('附近需求 (3)'), findsOneWidget);
      expect(find.text('奥林匹克森林公园南园'), findsOneWidget);

      await tester.drag(headerFinder, const Offset(0, 400));
      await tester.pumpAndSettle();

      final collapsedTop = tester.getTopLeft(sheetFinder).dy;
      expect(collapsedTop, greaterThan(defaultTop));
      expect(find.text('附近需求 (3)'), findsOneWidget);
      expect(find.text('奥林匹克森林公园南园'), findsNothing);
      expect(find.text('当前行程进行中'), findsNothing);

      await tester.drag(headerFinder, const Offset(0, -520));
      await tester.pumpAndSettle();

      final expandedTop = tester.getTopLeft(sheetFinder).dy;
      expect(expandedTop, lessThan(defaultTop));
      expect(find.text('奥林匹克森林公园南园'), findsOneWidget);
    },
  );

  testWidgets(
    'expanded volunteer dashboard sheet scrolls content and keeps accept flow',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({
        'aidrun_role': UserRole.volunteer.name,
      });
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);

      for (var index = 0; index < 6; index++) {
        container
            .read(appStateControllerProvider.notifier)
            .createBlindRun(
              RunRequestInput(
                place: PlaceSuggestion(
                  name: '附加测试地点 $index',
                  address: '测试地址 $index',
                  latitude: 39.90 + index,
                  longitude: 116.40 + index,
                ),
                timeLabel: '测试时间 $index',
              ),
            );
      }

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: VolunteerDashboardPage()),
        ),
      );
      await tester.pumpAndSettle();

      final headerFinder = find.byKey(
        const Key('volunteer-order-sheet-header'),
      );
      final scrollFinder = find.descendant(
        of: find.byKey(const Key('volunteer-order-sheet-scroll')),
        matching: find.byType(Scrollable),
      );

      await tester.drag(headerFinder, const Offset(0, -520));
      await tester.pumpAndSettle();

      expect(find.text('附近需求 (9)'), findsOneWidget);
      expect(find.text('天坛公园北门'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('天坛公园北门'),
        240,
        scrollable: scrollFinder,
      );
      await tester.pumpAndSettle();

      expect(find.text('天坛公园北门'), findsOneWidget);
      expect(find.text('立即接单'), findsWidgets);

      container.read(appStateControllerProvider.notifier).acceptRun('mock-1');
      await tester.pumpAndSettle();

      expect(
        container.read(appStateControllerProvider.notifier).pendingRuns.length,
        8,
      );
      expect(
        container
            .read(appStateControllerProvider.notifier)
            .volunteerActiveRun
            ?.id,
        'mock-1',
      );
    },
  );

  testWidgets(
    'volunteer history tab renders status labels without runtime errors',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({
        'aidrun_role': UserRole.volunteer.name,
      });
      final preferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: const MaterialApp(home: VolunteerDashboardPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('历史'));
      await tester.pumpAndSettle();

      expect(find.text('上周六 07:00 · 已完成'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'volunteer profile tab renders initials without characters crash',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({
        'aidrun_role': UserRole.volunteer.name,
      });
      final preferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
          child: const MaterialApp(home: VolunteerDashboardPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('我的'));
      await tester.pumpAndSettle();

      expect(find.text('爱'), findsWidgets);
      expect(find.text('爱心志愿者'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('volunteer store tab stays stable on narrow screens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'aidrun_role': UserRole.volunteer.name,
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: const MaterialApp(home: VolunteerDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('商城'));
    await tester.pumpAndSettle();

    expect(find.text('速干排汗T恤'), findsOneWidget);
    expect(find.text('兑换'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test(
    'place search falls back to local demo data when web key is missing',
    () async {
      final service = AMapPlaceSearchService(
        const AMapConfig(androidKey: '', iosKey: '', webKey: ''),
      );

      final results = await service.search('朝阳');

      expect(results, isNotEmpty);
      expect(
        results.any(
          (item) => item.name.contains('朝阳') || item.address.contains('朝阳'),
        ),
        isTrue,
      );
    },
  );

  test('amap config disables capabilities in no-amap demo mode', () {
    const config = AMapConfig(
      androidKey: 'android-key',
      iosKey: 'ios-key',
      webKey: 'web-key',
      disableAMap: true,
    );

    expect(config.isNoAMapDemoMode, isTrue);
    expect(config.hasNativeKeys, isFalse);
    expect(config.hasWebKey, isFalse);
    expect(config.apiKey, isNull);
  });

  test(
    'place search uses local demo data when no-amap demo mode is enabled',
    () async {
      final service = AMapPlaceSearchService(
        const AMapConfig(
          androidKey: 'android-key',
          iosKey: 'ios-key',
          webKey: 'web-key',
          disableAMap: true,
        ),
      );

      final results = await service.search('天坛');

      expect(results, isNotEmpty);
      expect(results.first.name, contains('天坛'));
    },
  );

  testWidgets('volunteer map falls back in no-amap demo mode', (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      'aidrun_role': UserRole.volunteer.name,
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          aMapConfigProvider.overrideWithValue(
            const AMapConfig(
              androidKey: 'android-key',
              iosKey: 'ios-key',
              webKey: 'web-key',
              disableAMap: true,
            ),
          ),
        ],
        child: const MaterialApp(home: VolunteerDashboardPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('当前处于 no-AMap 演示模式，地图区域已降级，附近需求列表仍可正常交互。'),
      findsOneWidget,
    );
    expect(find.text('附近需求 (3)'), findsOneWidget);
    expect(find.text('立即接单'), findsWidgets);
  });

  testWidgets(
    'blind place search uses local suggestions in no-amap demo mode',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(preferences),
            aMapConfigProvider.overrideWithValue(
              const AMapConfig(
                androidKey: 'android-key',
                iosKey: 'ios-key',
                webKey: 'web-key',
                disableAMap: true,
              ),
            ),
            speechServiceProvider.overrideWithValue(_FakeSpeechService()),
            appLocationServiceProvider.overrideWithValue(
              _FakeLocationService(),
            ),
          ],
          child: const MaterialApp(home: BlindPlaceSearchPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('当前处于 no-AMap 演示模式，地点候选将使用本地演示数据。'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '朝阳');
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('朝阳公园东门'), findsOneWidget);
      expect(find.text('选择'), findsWidgets);
    },
  );

  test('blind run stores selected place coordinates', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(container.dispose);

    final run = container
        .read(appStateControllerProvider.notifier)
        .createBlindRun(
          const RunRequestInput(
            place: PlaceSuggestion(
              name: '测试地点',
              address: '测试地址',
              latitude: 31.2304,
              longitude: 121.4737,
            ),
            timeLabel: '今天晚上',
          ),
        );

    expect(run.location, '测试地点');
    expect(run.address, '测试地址');
    expect(run.latitude, 31.2304);
    expect(run.longitude, 121.4737);
  });
}

class _FakeSpeechService implements SpeechService {
  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}

class _FakeLocationService implements AppLocationService {
  @override
  Future<DeviceLocation?> locateOnce() async => null;
}
