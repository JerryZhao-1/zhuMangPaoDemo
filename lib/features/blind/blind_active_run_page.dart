import 'package:aidrun_demo/app/providers.dart';
import 'package:aidrun_demo/core/models/run_rating.dart';
import 'package:aidrun_demo/core/models/run_status.dart';
import 'package:aidrun_demo/core/theme/app_theme.dart';
import 'package:aidrun_demo/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BlindActiveRunPage extends ConsumerWidget {
  const BlindActiveRunPage({
    super.key,
    required this.runId,
  });

  final String runId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateControllerProvider);
    final controller = ref.read(appStateControllerProvider.notifier);
    final run = state.runs.where((item) => item.id == runId).firstOrNull;
    if (run == null) {
      return const Scaffold(
        body: Center(child: Text('未找到行程')),
      );
    }

    if (run.status == RunStatus.completed && run.blindRating == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          foregroundColor: AppTheme.yellow,
          title: const Text('行程已结束'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Text(
                '请评价本次志愿服务',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 32),
              for (final rating in RunRating.values) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      controller.rateRun(runId, rating);
                      context.go('/blind');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: switch (rating) {
                        RunRating.good => AppTheme.emerald,
                        RunRating.average => AppTheme.yellow,
                        RunRating.bad => AppTheme.red,
                      },
                      foregroundColor:
                          rating == RunRating.bad ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 28),
                    ),
                    child: Text(
                      rating.label,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Spacer(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SectionCard(
                color: AppTheme.zinc,
                child: Column(
                  children: [
                    Text(
                      run.status.blindLabel,
                      style: const TextStyle(
                        color: AppTheme.yellow,
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      switch (run.status) {
                        RunStatus.pending => '请在原地等待',
                        RunStatus.accepted => '志愿者正在赶来',
                        RunStatus.arrived => '请与志愿者汇合',
                        RunStatus.running => '享受跑步的乐趣吧',
                        RunStatus.completed => '感谢您的使用',
                        RunStatus.cancelled => '本次行程已取消',
                      },
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (run.volunteer != null &&
                  [
                    RunStatus.accepted,
                    RunStatus.arrived,
                    RunStatus.running,
                  ].contains(run.status))
                SectionCard(
                  color: AppTheme.zinc,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.white10,
                        child: Text(
                          run.volunteer!.name.characters.first,
                          style: const TextStyle(fontSize: 32, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              run.volunteer!.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '评分 ${run.volunteer!.rating.toStringAsFixed(1)}',
                              style: const TextStyle(
                                color: AppTheme.yellow,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              SectionCard(
                color: AppTheme.zinc,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(icon: Icons.place, text: run.location),
                    const SizedBox(height: 12),
                    _InfoRow(icon: Icons.schedule, text: run.timeLabel),
                    if (run.notes.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _InfoRow(icon: Icons.notes, text: run.notes),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              if (run.status == RunStatus.pending)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      controller.acceptRun(run.id);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 22),
                    ),
                    child: const Text(
                      '[测试] 模拟志愿者接单',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              if (run.status == RunStatus.accepted) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.emerald,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 22),
                    ),
                    icon: const Icon(Icons.phone),
                    label: const Text(
                      '联系志愿者',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () =>
                        controller.updateRunStatus(run.id, RunStatus.arrived),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text(
                      '[测试] 模拟志愿者到达',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
              if (run.status == RunStatus.arrived)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () =>
                        controller.updateRunStatus(run.id, RunStatus.running),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text(
                      '[测试] 模拟开始跑步',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              if (run.status == RunStatus.running)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () =>
                        controller.updateRunStatus(run.id, RunStatus.completed),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: const Text(
                      '[测试] 模拟结束行程',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              if ([RunStatus.pending, RunStatus.accepted].contains(run.status)) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      controller.cancelRun(run.id);
                      context.go('/blind');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 22),
                    ),
                    icon: const Icon(Icons.cancel),
                    label: const Text(
                      '取消行程',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.yellow),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
