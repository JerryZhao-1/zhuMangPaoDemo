import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/models/run_status.dart';
import 'package:aidrun_demo/core/theme/app_theme.dart';
import 'package:aidrun_demo/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BlindDashboardPage extends ConsumerStatefulWidget {
  const BlindDashboardPage({super.key});

  @override
  ConsumerState<BlindDashboardPage> createState() => _BlindDashboardPageState();
}

class _BlindDashboardPageState extends ConsumerState<BlindDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(speechServiceProvider).speak('欢迎来到助盲跑，您可以点击屏幕中央的大按钮发起预约。');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateControllerProvider);
    final controller = ref.read(appStateControllerProvider.notifier);
    final activeRun = state.runs
        .where((run) => run.blindRunnerId == controller.currentUser?.id)
        .where(
          (run) => [
            RunStatus.pending,
            RunStatus.accepted,
            RunStatus.arrived,
            RunStatus.running,
          ].contains(run.status),
        )
        .firstOrNull;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      controller.logout();
                      context.go('/');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.zinc,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      '切换角色',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: activeRun != null
                    ? LargeActionButton(
                        onPressed: () => context.go('/blind/run/${activeRun.id}'),
                        backgroundColor: AppTheme.emerald,
                        foregroundColor: Colors.black,
                        icon: const Icon(Icons.directions_run, size: 120),
                        title: '查看行程',
                        subtitle: activeRun.status.blindLabel,
                      )
                    : LargeActionButton(
                        onPressed: () => context.go('/blind/request'),
                        backgroundColor: AppTheme.yellow,
                        foregroundColor: Colors.black,
                        icon: const Icon(Icons.navigation, size: 120),
                        title: '发起预约',
                        subtitle: '点击屏幕任意位置开始',
                      ),
              ),
              if (activeRun != null) ...[
                const SizedBox(height: 16),
                SectionCard(
                  color: AppTheme.zinc,
                  child: Row(
                    children: [
                      const Icon(Icons.place, color: AppTheme.yellow),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${activeRun.location} · ${activeRun.timeLabel}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/settings'),
        backgroundColor: AppTheme.zinc,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.settings),
        label: const Text('设置'),
      ),
    );
  }
}
