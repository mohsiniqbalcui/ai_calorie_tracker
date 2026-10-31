import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/food_log_cubit.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/tracker_cubit.dart';
import '../tools/body_metrics_screen.dart';
import '../tools/weight_screen.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

/// Simple mode progress: a weekly chart, a few clear numbers and weight.
class GraphScreen extends StatelessWidget {
  const GraphScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final food = context.watch<FoodLogCubit>().state;
    final settings = context.watch<SettingsCubit>().state;
    final tracker = context.watch<TrackerCubit>().state;
    final week = food.history.skip(food.history.length > 7 ? food.history.length - 7 : 0).toList();
    final logged = week.where((d) => d.meals > 0).toList();
    final avg = logged.isEmpty ? 0 : logged.fold(0.0, (s, d) => s + d.calories) / logged.length;
    final onTarget = logged.where((d) => d.calories >= settings.calorieGoal * 0.9 && d.calories <= settings.calorieGoal * 1.1).length;

    Widget stat(String label, String value, IconData icon) => Expanded(
          child: AppCard(
            child: Column(children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 6),
              Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              Text(label, style: theme.textTheme.labelSmall),
            ]),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Your progress'), automaticallyImplyLeading: false, actions: const [ModeToggleButton()]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Last 7 days', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                Text('Dashed line is your daily goal', style: theme.textTheme.bodySmall),
                const SizedBox(height: 16),
                CalorieBarChart(days: week, goal: settings.calorieGoal),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            stat('Daily average', '${avg.round()} kcal', Icons.analytics_rounded),
            const SizedBox(width: 10),
            stat('On target', '$onTarget / ${logged.length} days', Icons.track_changes_rounded),
            const SizedBox(width: 10),
            stat('Streak', '${food.streak} days', Icons.local_fire_department_rounded),
          ]),
          const SizedBox(height: 12),
          AppCard(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WeightScreen())),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('Weight', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded),
                ]),
                const SizedBox(height: 8),
                WeightChart(entries: tracker.weights, metric: settings.metric, height: 150),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BodyMetricsScreen())),
            child: const Row(children: [
              Icon(Icons.monitor_heart_rounded),
              SizedBox(width: 12),
              Expanded(child: Text('BMI and body metrics')),
              Icon(Icons.chevron_right_rounded),
            ]),
          ),
        ],
      ),
    );
  }
}
