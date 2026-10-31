import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../core/utils/units.dart';
import '../cubit/tracker_cubit.dart';
import '../widgets/common.dart';

class FastingScreen extends StatefulWidget {
  const FastingScreen({super.key});

  @override
  State<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends State<FastingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.watch<TrackerCubit>().state;
    final cubit = context.read<TrackerCubit>();
    final goal = Duration(hours: t.fastGoalHours);
    final elapsed = t.fastStart == null
        ? Duration.zero
        : DateTime.now().difference(t.fastStart!);
    final done = elapsed >= goal;

    return Scaffold(
      appBar: AppBar(title: const Text('Intermittent fasting')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                CircularPercentIndicator(
                  radius: 100,
                  lineWidth: 14,
                  circularStrokeCap: CircularStrokeCap.round,
                  percent: t.isFasting
                      ? (elapsed.inSeconds / goal.inSeconds).clamp(0.0, 1.0)
                      : 0,
                  progressColor:
                      done ? Colors.green : theme.colorScheme.primary,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.12),
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          t.isFasting
                              ? _fmt(elapsed)
                              : '${t.fastGoalHours}:00:00',
                          style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ])),
                      Text(
                          !t.isFasting
                              ? 'ready to start'
                              : (done
                                  ? 'goal reached 🎉'
                                  : '${_fmt(goal - elapsed)} to go'),
                          style: theme.textTheme.labelMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final h in [12, 14, 16, 18, 20])
                      ChoiceChip(
                          label: Text('$h:${24 - h}'),
                          selected: t.fastGoalHours == h,
                          onSelected:
                              t.isFasting ? null : (_) => cubit.setFastGoal(h)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: t.isFasting
                      ? FilledButton.tonalIcon(
                          onPressed: cubit.endFast,
                          icon: const Icon(Icons.stop_rounded),
                          label: const Text('End fast'))
                      : FilledButton.icon(
                          onPressed: cubit.startFast,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Start fast')),
                ),
              ],
            ),
          ),
          const SectionTitle('History'),
          if (t.fastHistory.isEmpty)
            const Padding(
                padding: EdgeInsets.all(24),
                child:
                    Center(child: Text('Completed fasts will show up here.'))),
          for (final f in t.fastHistory)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                        f.completed
                            ? Icons.check_circle_rounded
                            : Icons.timelapse_rounded,
                        color: f.completed ? Colors.green : Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(
                            '${f.duration.inHours}h ${f.duration.inMinutes % 60}m  of  ${f.goalHours}h',
                            style: theme.textTheme.titleSmall)),
                    Text(DateFmt.short(f.start),
                        style: theme.textTheme.labelMedium),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
