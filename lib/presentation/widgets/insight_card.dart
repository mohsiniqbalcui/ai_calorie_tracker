import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/insights.dart';
import '../cubit/food_log_cubit.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/tracker_cubit.dart';
import 'common.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    final food = context.watch<FoodLogCubit>().state;
    final settings = context.watch<SettingsCubit>().state;
    final tracker = context.watch<TrackerCubit>().state;
    final insight = InsightEngine.daily(
      calories: food.totalCalories,
      calorieGoal: settings.calorieGoal,
      protein: food.totalProtein,
      proteinGoal: settings.proteinGoal,
      waterMl: tracker.waterMl,
      waterGoalMl: settings.waterGoalMl,
      streak: food.streak,
      mealCount: food.meals.length,
      isToday: food.isToday,
    );
    final color = insight.color ?? Theme.of(context).colorScheme.primary;
    return AppCard(
      color: insight.color == null
          ? Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.6)
          : color.withValues(alpha: 0.10),
      child: Row(
        children: [
          Icon(insight.icon, color: color),
          const SizedBox(width: 12),
          Expanded(
              child: Text(insight.text,
                  style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class StreakChip extends StatelessWidget {
  const StreakChip({super.key});

  @override
  Widget build(BuildContext context) {
    final streak = context.select((FoodLogCubit c) => c.state.streak);
    return Chip(
      avatar: Icon(Icons.local_fire_department_rounded,
          size: 18, color: streak > 0 ? Colors.deepOrange : null),
      label: Text(streak == 1 ? '1 day streak' : '$streak day streak'),
    );
  }
}

/// Success and error banner driven by the food log cubit. Success messages
/// dismiss themselves after a few seconds; errors stay until closed.
class StatusBanner extends StatefulWidget {
  const StatusBanner({super.key});

  @override
  State<StatusBanner> createState() => _StatusBannerState();
}

class _StatusBannerState extends State<StatusBanner> {
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FoodLogCubit, FoodLogState>(
      listenWhen: (a, b) =>
          a.successMessage != b.successMessage && b.successMessage != null,
      listener: (context, state) {
        _timer?.cancel();
        _timer = Timer(const Duration(seconds: 3), () {
          if (mounted) context.read<FoodLogCubit>().clearMessages();
        });
      },
      child: Builder(builder: (context) {
        final state = context.watch<FoodLogCubit>().state;
        if (state.error == null && state.successMessage == null)
          return const SizedBox.shrink();
        final isError = state.error != null;
        final theme = Theme.of(context);
        final color =
            isError ? theme.colorScheme.error : const Color(0xFF22A06B);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            color: color.withValues(alpha: 0.10),
            padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
            child: Row(
              children: [
                Icon(isError ? Icons.error_rounded : Icons.check_circle_rounded,
                    color: color),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(state.error ?? state.successMessage ?? '')),
                IconButton(
                    tooltip: 'Dismiss',
                    onPressed: () =>
                        context.read<FoodLogCubit>().clearMessages(),
                    icon: const Icon(Icons.close_rounded)),
              ],
            ),
          ),
        );
      }),
    );
  }
}
