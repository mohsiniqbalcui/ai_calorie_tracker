import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/calorie_calculator.dart';
import '../../core/utils/units.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/tracker_cubit.dart';
import '../widgets/common.dart';

/// BMI, BMR, maintenance calories and personalised targets.
class BodyMetricsScreen extends StatelessWidget {
  const BodyMetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsCubit>().state;
    final user = settings.user;
    final latest = context.watch<TrackerCubit>().state.latestWeight;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Body metrics')),
        body: const Center(
            child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Add your profile in Settings to see body metrics.',
                    textAlign: TextAlign.center))),
      );
    }

    final kg = latest?.kg ?? user.weight;
    final bmi = BodyMetrics.bmi(kg, user.height);
    final category = BodyMetrics.bmiCategory(bmi);
    final bmr = BodyMetrics.bmr(user, weightKg: kg);
    final maintenance = CalorieCalculator.fallbackEstimateCalories(
        weight: kg,
        height: user.height,
        age: user.age,
        activityLevel: user.activityLevel,
        gender: user.gender);
    final range = BodyMetrics.healthyWeightRange(user.height);
    final water = CalorieCalculator.calculateWaterIntake(
        weight: kg, activityLevel: user.activityLevel);
    final protein = CalorieCalculator.calculateProteinNeeds(
        weight: kg, activityLevel: user.activityLevel, goal: user.goal);
    final categoryColor = switch (category) {
      'Healthy' => Colors.green,
      'Underweight' => Colors.blue,
      'Overweight' => Colors.orange,
      _ => Colors.red
    };

    Widget tile(String label, String value, IconData icon) => Expanded(
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(height: 8),
                Text(value,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                Text(label,
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Body metrics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(bmi.toStringAsFixed(1),
                        style: theme.textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 12),
                    Chip(
                        label: Text(category),
                        backgroundColor: categoryColor.withValues(alpha: 0.18),
                        labelStyle: TextStyle(
                            color: categoryColor, fontWeight: FontWeight.w800)),
                  ],
                ),
                Text('Body mass index', style: theme.textTheme.labelMedium),
                const SizedBox(height: 14),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Row(children: [
                        Expanded(
                            flex: 185,
                            child: Container(height: 10, color: Colors.blue)),
                        Expanded(
                            flex: 65,
                            child: Container(height: 10, color: Colors.green)),
                        Expanded(
                            flex: 50,
                            child: Container(height: 10, color: Colors.orange)),
                        Expanded(
                            flex: 100,
                            child: Container(height: 10, color: Colors.red)),
                      ]),
                    ),
                    Positioned.fill(
                      child: LayoutBuilder(builder: (context, c) {
                        final x = ((bmi.clamp(10, 40) - 10) / 30) * c.maxWidth;
                        return Stack(clipBehavior: Clip.none, children: [
                          Positioned(
                              left: x - 6,
                              top: -3,
                              child: Container(
                                  width: 12,
                                  height: 16,
                                  decoration: BoxDecoration(
                                      color: theme.colorScheme.onSurface,
                                      borderRadius: BorderRadius.circular(4)))),
                        ]);
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                    'Healthy range for your height: ${Units.weight(range.$1, settings.metric, digits: 0)} – ${Units.weight(range.$2, settings.metric, digits: 0)}',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            tile('BMR (kcal/day)', '${bmr.round()}', Icons.bedtime_rounded),
            const SizedBox(width: 12),
            tile('Maintenance', '$maintenance kcal', Icons.balance_rounded)
          ]),
          const SizedBox(height: 12),
          Row(children: [
            tile('Daily target', '${settings.calorieGoal} kcal',
                Icons.flag_rounded),
            const SizedBox(width: 12),
            tile('Protein target', '$protein g', Icons.fitness_center_rounded)
          ]),
          const SizedBox(height: 12),
          Row(children: [
            tile('Water target', Units.volume(water, settings.metric),
                Icons.water_drop_rounded),
            const SizedBox(width: 12),
            tile('Weight used', Units.weight(kg, settings.metric),
                Icons.monitor_weight_rounded)
          ]),
          const SizedBox(height: 16),
          Text(
              'Estimates use the Mifflin-St Jeor equation and are not medical advice.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
