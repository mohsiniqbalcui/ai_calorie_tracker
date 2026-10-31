import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/units.dart';
import '../../core/utils/insights.dart';
import '../../core/theme/app_theme.dart';
import '../cubit/food_log_cubit.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/tracker_cubit.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

/// Progress for both modes: Simple shows the essentials, Pro adds the extra
/// metrics and achievements.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _range = 7;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final food = context.watch<FoodLogCubit>().state;
    final settings = context.watch<SettingsCubit>().state;
    final tracker = context.watch<TrackerCubit>().state;

    final isPro = settings.isPro;
    final days = food.history
        .skip(food.history.length > _range ? food.history.length - _range : 0)
        .toList();
    final rangeWeights = tracker.weights
        .where((w) => !w.date.isBefore(days.first.date))
        .toList();
    final weightDelta = rangeWeights.length >= 2
        ? rangeWeights.last.kg - rangeWeights.first.kg
        : null;
    final logged = days.where((d) => d.meals > 0).toList();
    double avg(double Function(dynamic) f) => logged.isEmpty
        ? 0
        : logged.fold(0.0, (s, d) => s + f(d)) / logged.length;
    final goal = settings.calorieGoal;
    final onTarget = logged
        .where((d) => d.calories >= goal * 0.9 && d.calories <= goal * 1.1)
        .length;
    final adherence =
        logged.isEmpty ? 0 : (onTarget / logged.length * 100).round();
    final best = logged.isEmpty
        ? null
        : logged.reduce((a, b) =>
            (a.calories - goal).abs() < (b.calories - goal).abs() ? a : b);
    final totalDeficit = logged.fold(0.0, (s, d) => s + (goal - d.calories));

    final badges = InsightEngine.badges(
      streak: food.streak,
      lifetimeMeals: food.lifetimeMeals,
      weighIns: tracker.weights.length,
      waterGoalHit:
          tracker.waterMl >= settings.waterGoalMl && settings.waterGoalMl > 0,
      onTargetToday:
          food.totalCalories >= goal * 0.9 && food.totalCalories <= goal * 1.1,
      fasts: tracker.completedFasts,
    );

    Widget metric(String label, String value, IconData icon) => Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(height: 6),
              Text(value,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text(label, style: theme.textTheme.labelSmall),
            ]),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          IconButton(
            tooltip: 'Copy report',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () async {
              final first = days.first.date, last = days.last.date;
              final w = tracker.weights;
              final report = StringBuffer()
                ..writeln(
                    'Calorie Lens report: ${DateFmt.short(first)} to ${DateFmt.short(last)}')
                ..writeln('Days logged: ${logged.length} of $_range')
                ..writeln(
                    'Average calories: ${avg((d) => d.calories).round()} kcal (goal $goal)')
                ..writeln(
                    'Average protein/carbs/fat: ${avg((d) => d.protein).round()} / ${avg((d) => d.carbs).round()} / ${avg((d) => d.fat).round()} g')
                ..writeln('Goal adherence: $adherence%')
                ..writeln('Current streak: ${food.streak} days');
              if (w.length >= 2) {
                report.writeln(
                    'Weight change: ${(w.last.kg - w.first.kg).toStringAsFixed(1)} kg over ${w.length} weigh-ins');
              }
              await Clipboard.setData(ClipboardData(text: report.toString()));
              if (context.mounted)
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Report copied to clipboard')));
            },
          ),
          const ModeToggleButton(),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            Spacing.pageGutter(MediaQuery.of(context).size.width),
            4,
            Spacing.pageGutter(MediaQuery.of(context).size.width),
            32),
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 7, label: Text('7 days')),
              ButtonSegment(value: 30, label: Text('30 days')),
              ButtonSegment(value: 90, label: Text('90 days'))
            ],
            selected: {_range},
            onSelectionChanged: (s) => setState(() => _range = s.first),
          ),
          const SizedBox(height: 12),
          _GoalProgressCard(
              goalName: settings.user?.goal,
              loggedDays: logged.length,
              onTargetDays: onTarget,
              weightDeltaKg: weightDelta,
              metric: settings.metric),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Calories vs goal',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                CalorieBarChart(days: days, goal: goal),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            metric('Avg calories', '${avg((d) => d.calories).round()}',
                Icons.analytics_rounded),
            const SizedBox(width: 8),
            metric('Adherence', '$adherence%', Icons.track_changes_rounded),
            const SizedBox(width: 8),
            metric('Days logged', '${logged.length}/$_range',
                Icons.event_available_rounded),
          ]),
          if (isPro) const SizedBox(height: 8),
          if (isPro)
            Row(children: [
              metric(
                  'Best day',
                  best == null ? '—' : '${best.date.day}/${best.date.month}',
                  Icons.emoji_events_rounded),
              const SizedBox(width: 8),
              metric(totalDeficit >= 0 ? 'Total deficit' : 'Total surplus',
                  '${totalDeficit.abs().round()}', Icons.balance_rounded),
              const SizedBox(width: 8),
              metric('Streak', '${food.streak} d',
                  Icons.local_fire_department_rounded),
            ]),
          const SizedBox(height: 10),
          AppCard(
            child: Row(
              children: [
                MacroPie(
                    protein: avg((d) => d.protein),
                    carbs: avg((d) => d.carbs),
                    fat: avg((d) => d.fat)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Average macros',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      MacroLegend(
                          protein: avg((d) => d.protein),
                          carbs: avg((d) => d.carbs),
                          fat: avg((d) => d.fat)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weight trend',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                WeightChart(entries: rangeWeights, metric: settings.metric),
              ],
            ),
          ),
          if (isPro) const SectionTitle('Achievements'),
          if (isPro)
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.95,
              children: [
                for (final b in badges)
                  Tooltip(
                    message: b.description,
                    triggerMode: TooltipTriggerMode.tap,
                    child: AppCard(
                      padding: const EdgeInsets.all(8),
                      child: Opacity(
                        opacity: b.unlocked ? 1 : 0.35,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(b.icon,
                                size: 28,
                                color:
                                    b.unlocked ? Colors.amber.shade700 : null),
                            const SizedBox(height: 6),
                            Text(b.title,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          if (isPro) const SizedBox(height: 8),
          if (isPro)
            Text(
                '${badges.where((b) => b.unlocked).length} of ${badges.length} unlocked',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _GoalProgressCard extends StatelessWidget {
  final String? goalName;
  final int loggedDays;
  final int onTargetDays;
  final double? weightDeltaKg;
  final bool metric;
  const _GoalProgressCard(
      {required this.goalName,
      required this.loggedDays,
      required this.onTargetDays,
      required this.weightDeltaKg,
      required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = loggedDays == 0 ? 0.0 : onTargetDays / loggedDays;
    final delta = weightDeltaKg;
    String weightLine;
    if (delta == null) {
      weightLine = 'Log two weigh-ins in this period to track weight change.';
    } else {
      final shown = metric ? delta : Units.kgToLb(delta);
      final unit = Units.weightUnit(metric);
      final onTrack = switch (goalName) {
        'Weight Loss' => delta < 0,
        'Muscle Gain' => delta > 0,
        _ => delta.abs() < 1,
      };
      weightLine =
          '${shown >= 0 ? '+' : ''}${shown.toStringAsFixed(1)} $unit · ${onTrack ? 'on track' : 'off track'} for ${goalName ?? 'your goal'}';
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.flag_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('Goal progress',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            Text(goalName ?? 'No goal set',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ]),
          const SizedBox(height: 14),
          ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: pct, minHeight: 10)),
          const SizedBox(height: 8),
          Text(
              loggedDays == 0
                  ? 'No meals logged in this period yet.'
                  : '$onTargetDays of $loggedDays logged days within 10% of your calorie goal',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text(weightLine,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
