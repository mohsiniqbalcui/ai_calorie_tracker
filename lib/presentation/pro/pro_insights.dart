import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/units.dart';
import '../../core/utils/insights.dart';
import '../cubit/food_log_cubit.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/tracker_cubit.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

class ProInsights extends StatefulWidget {
  const ProInsights({super.key});

  @override
  State<ProInsights> createState() => _ProInsightsState();
}

class _ProInsightsState extends State<ProInsights> {
  int _range = 7;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final food = context.watch<FoodLogCubit>().state;
    final settings = context.watch<SettingsCubit>().state;
    final tracker = context.watch<TrackerCubit>().state;

    final days = food.history.skip(food.history.length - _range).toList();
    final logged = days.where((d) => d.meals > 0).toList();
    double avg(double Function(dynamic) f) => logged.isEmpty ? 0 : logged.fold(0.0, (s, d) => s + f(d)) / logged.length;
    final goal = settings.calorieGoal;
    final onTarget = logged.where((d) => d.calories >= goal * 0.9 && d.calories <= goal * 1.1).length;
    final adherence = logged.isEmpty ? 0 : (onTarget / logged.length * 100).round();
    final best = logged.isEmpty ? null : logged.reduce((a, b) => (a.calories - goal).abs() < (b.calories - goal).abs() ? a : b);
    final totalDeficit = logged.fold(0.0, (s, d) => s + (goal - d.calories));

    final badges = InsightEngine.badges(
      streak: food.streak,
      lifetimeMeals: food.lifetimeMeals,
      weighIns: tracker.weights.length,
      waterGoalHit: tracker.waterMl >= settings.waterGoalMl && settings.waterGoalMl > 0,
      onTargetToday: food.totalCalories >= goal * 0.9 && food.totalCalories <= goal * 1.1,
      fasts: tracker.completedFasts,
    );

    Widget metric(String label, String value, IconData icon) => Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(height: 6),
              Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              Text(label, style: theme.textTheme.labelSmall),
            ]),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Copy report',
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: () async {
              final first = days.first.date, last = days.last.date;
              final w = tracker.weights;
              final report = StringBuffer()
                ..writeln('Calorie Lens report: ${DateFmt.short(first)} to ${DateFmt.short(last)}')
                ..writeln('Days logged: ${logged.length} of $_range')
                ..writeln('Average calories: ${avg((d) => d.calories).round()} kcal (goal $goal)')
                ..writeln('Average protein/carbs/fat: ${avg((d) => d.protein).round()} / ${avg((d) => d.carbs).round()} / ${avg((d) => d.fat).round()} g')
                ..writeln('Goal adherence: $adherence%')
                ..writeln('Current streak: ${food.streak} days');
              if (w.length >= 2) {
                report.writeln('Weight change: ${(w.last.kg - w.first.kg).toStringAsFixed(1)} kg over ${w.length} weigh-ins');
              }
              await Clipboard.setData(ClipboardData(text: report.toString()));
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report copied to clipboard')));
            },
          ),
          const ModeToggleButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          SegmentedButton<int>(
            segments: const [ButtonSegment(value: 7, label: Text('7 days')), ButtonSegment(value: 14, label: Text('14 days')), ButtonSegment(value: 30, label: Text('30 days'))],
            selected: {_range},
            onSelectionChanged: (s) => setState(() => _range = s.first),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Calories vs goal', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                CalorieBarChart(days: days, goal: goal),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(children: [
            metric('Avg calories', '${avg((d) => d.calories).round()}', Icons.analytics_rounded),
            const SizedBox(width: 8),
            metric('Adherence', '$adherence%', Icons.track_changes_rounded),
            const SizedBox(width: 8),
            metric('Days logged', '${logged.length}/$_range', Icons.event_available_rounded),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            metric('Best day', best == null ? '—' : '${best.date.day}/${best.date.month}', Icons.emoji_events_rounded),
            const SizedBox(width: 8),
            metric(totalDeficit >= 0 ? 'Total deficit' : 'Total surplus', '${totalDeficit.abs().round()}', Icons.balance_rounded),
            const SizedBox(width: 8),
            metric('Streak', '${food.streak} d', Icons.local_fire_department_rounded),
          ]),
          const SizedBox(height: 10),
          AppCard(
            child: Row(
              children: [
                MacroPie(protein: avg((d) => d.protein), carbs: avg((d) => d.carbs), fat: avg((d) => d.fat)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Average macros', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      MacroLegend(protein: avg((d) => d.protein), carbs: avg((d) => d.carbs), fat: avg((d) => d.fat)),
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
                Text('Weight trend', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                WeightChart(entries: tracker.weights, metric: settings.metric),
              ],
            ),
          ),
          const SectionTitle('Achievements'),
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
                          Icon(b.icon, size: 28, color: b.unlocked ? Colors.amber.shade700 : null),
                          const SizedBox(height: 6),
                          Text(b.title, textAlign: TextAlign.center, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${badges.where((b) => b.unlocked).length} of ${badges.length} unlocked', textAlign: TextAlign.center, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}
