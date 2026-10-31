import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/tracker_cubit.dart';
import 'common.dart';

/// Calorie ring plus macro bars for the selected day.
class DailyTracker extends StatelessWidget {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const DailyTracker({
    super.key,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = context.watch<SettingsCubit>().state;
    final burned = context.select((TrackerCubit c) => c.state.caloriesBurned);

    Widget stat(String label, String value, IconData icon, Color color) => Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
            Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        );

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              CalorieRing(consumed: calories, goal: s.calorieGoal, burned: burned),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    stat('Eaten', '${calories.round()}', Icons.restaurant_rounded, MacroColors.calories),
                    const SizedBox(height: 10),
                    stat('Goal', '${s.calorieGoal}', Icons.flag_rounded, theme.colorScheme.primary),
                    const SizedBox(height: 10),
                    stat('Burned', '${burned.round()}', Icons.directions_run_rounded, MacroColors.protein),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: MacroBar(label: 'Protein', value: protein, goal: s.proteinGoal.toDouble(), color: MacroColors.protein)),
              const SizedBox(width: 14),
              Expanded(child: MacroBar(label: 'Carbs', value: carbs, goal: s.carbsGoal.toDouble(), color: MacroColors.carbs)),
              const SizedBox(width: 14),
              Expanded(child: MacroBar(label: 'Fat', value: fat, goal: s.fatGoal.toDouble(), color: MacroColors.fat)),
            ],
          ),
        ],
      ),
    );
  }
}
