import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../cubit/food_log_cubit.dart';
import '../cubit/tracker_cubit.dart';
import '../tools/exercise_screen.dart';
import '../tools/fasting_screen.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/insight_card.dart';

/// Extra Home sections that only appear in Pro mode.
class ProHomeExtras extends StatelessWidget {
  const ProHomeExtras({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final food = context.watch<FoodLogCubit>().state;
    final tracker = context.watch<TrackerCubit>().state;
    final net = food.totalCalories - tracker.caloriesBurned;

    Widget kpi(String label, String value, IconData icon, Color color) =>
        Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20, color: color),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InsightCard(),
        const SizedBox(height: 12),
        Row(children: [
          kpi('Net calories', '${net.round()}', Icons.balance_rounded,
              theme.colorScheme.primary),
          const SizedBox(width: 12),
          kpi('Exercise', '${tracker.exerciseMinutes} min',
              Icons.directions_run_rounded, MacroColors.protein),
          const SizedBox(width: 12),
          kpi('Streak', '${food.streak} d', Icons.local_fire_department_rounded,
              Colors.deepOrange),
        ]),
        const SizedBox(height: 12),
        AppCard(
          child: Row(
            children: [
              MacroPie(
                  protein: food.totalProtein,
                  carbs: food.totalCarbs,
                  fat: food.totalFat,
                  size: 96),
              const SizedBox(width: 20),
              Expanded(
                  child: MacroLegend(
                      protein: food.totalProtein,
                      carbs: food.totalCarbs,
                      fat: food.totalFat)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nutrition details',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: MacroBar(
                        label: 'Fiber',
                        value: food.totalFiber,
                        goal: 28,
                        color: Colors.teal)),
                const SizedBox(width: 12),
                Expanded(
                    child: MacroBar(
                        label: 'Sugar',
                        value: food.totalSugar,
                        goal: 50,
                        color: Colors.pink)),
                const SizedBox(width: 12),
                Expanded(
                    child: MacroBar(
                        label: 'Sodium mg',
                        value: food.totalSodium,
                        goal: 2300,
                        color: Colors.blueGrey)),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: FastingMini()),
            const SizedBox(width: 12),
            Expanded(
              child: AppCard(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ExerciseScreen())),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.directions_run_rounded,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Exercise',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 10),
                    Text('${tracker.caloriesBurned.round()} kcal burned',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                        tracker.exercises.isEmpty
                            ? 'Tap to log a workout'
                            : '${tracker.exercises.length} logged',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class FastingMini extends StatefulWidget {
  const FastingMini();

  @override
  State<FastingMini> createState() => FastingMiniState();
}

class FastingMiniState extends State<FastingMini> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
        const Duration(seconds: 30), (_) => mounted ? setState(() {}) : null);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.watch<TrackerCubit>().state;
    final elapsed = t.fastStart == null
        ? Duration.zero
        : DateTime.now().difference(t.fastStart!);
    final pct = t.isFasting
        ? (elapsed.inMinutes / (t.fastGoalHours * 60)).clamp(0.0, 1.0)
        : 0.0;
    return AppCard(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const FastingScreen())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.timer_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('Fasting',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: pct, minHeight: 10),
          ),
          const SizedBox(height: 8),
          Text(
              t.isFasting
                  ? '${elapsed.inHours}h ${elapsed.inMinutes % 60}m / ${t.fastGoalHours}h'
                  : 'Not fasting · tap to start',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
