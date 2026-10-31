import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/units.dart';
import '../cubit/food_log_cubit.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/tracker_cubit.dart';
import '../screens/food_search_screen.dart';
import '../screens/reminders_screen.dart';
import '../tools/meal_plan_screen.dart';
import '../tools/weight_screen.dart';
import 'common.dart';

/// Greeting, date and profile avatar at the top of Home.
class HomeHeader extends StatelessWidget {
  final VoidCallback? onAvatarTap;
  final List<Widget> actions;
  const HomeHeader({super.key, this.onAvatarTap, this.actions = const []});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = context.select((FoodLogCubit c) => c.state.selectedDate);
    final isToday = DateFmt.sameDay(date, DateTime.now());
    final goal = context.select((SettingsCubit c) => c.state.user?.goal);

    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Profile',
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onAvatarTap,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              child:
                  Icon(Icons.person_rounded, color: theme.colorScheme.primary),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting(),
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(
                isToday
                    ? '${DateFmt.weekday(date)}, ${DateFmt.short(date)}${goal != null ? ' · $goal' : ''}'
                    : '${DateFmt.relative(date)}, ${DateFmt.short(date)}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Reminders',
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RemindersScreen())),
        ),
        ...actions,
      ],
    );
  }
}

/// Shown when Home is looking at another day, so it is never mistaken for today.
class BackToTodayChip extends StatelessWidget {
  const BackToTodayChip({super.key});

  @override
  Widget build(BuildContext context) {
    final isToday = context.select((FoodLogCubit c) => c.state.isToday);
    if (isToday) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ActionChip(
          avatar: const Icon(Icons.today_rounded, size: 18),
          label: const Text('Back to today'),
          onPressed: () => selectDay(context, DateTime.now()),
        ),
      ),
    );
  }
}

/// Calorie ring with eaten / goal / burned, and the three macro bars.
class CalorieSummaryCard extends StatelessWidget {
  const CalorieSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final food = context.watch<FoodLogCubit>().state;
    final s = context.watch<SettingsCubit>().state;
    final burned = context.select((TrackerCubit c) => c.state.caloriesBurned);

    Widget stat(String label, String value, Color color) => Row(
          children: [
            Container(
                width: 4,
                height: 34,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        );

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Semantics(
                label:
                    '${(s.calorieGoal + burned - food.totalCalories).round()} calories remaining',
                child: CalorieRing(
                    consumed: food.totalCalories,
                    goal: s.calorieGoal,
                    burned: burned,
                    radius: (MediaQuery.of(context).size.width * 0.19)
                        .clamp(52.0, 72.0)),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    stat('Eaten', '${food.totalCalories.round()} kcal',
                        MacroColors.calories),
                    const SizedBox(height: 12),
                    stat('Daily target', '${s.calorieGoal} kcal',
                        theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    stat('Burned', '${burned.round()} kcal',
                        MacroColors.protein),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: MacroBar(
                      label: 'Protein',
                      value: food.totalProtein,
                      goal: s.proteinGoal.toDouble(),
                      color: MacroColors.protein)),
              const SizedBox(width: 12),
              Expanded(
                  child: MacroBar(
                      label: 'Carbs',
                      value: food.totalCarbs,
                      goal: s.carbsGoal.toDouble(),
                      color: MacroColors.carbs)),
              const SizedBox(width: 12),
              Expanded(
                  child: MacroBar(
                      label: 'Fat',
                      value: food.totalFat,
                      goal: s.fatGoal.toDouble(),
                      color: MacroColors.fat)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Row of shortcut tiles: scan barcode, meal planner, water, and more.
class QuickActions extends StatelessWidget {
  final List<QuickAction> actions;
  const QuickActions({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              button: true,
              label: actions[i].label,
              child: AppCard(
                onTap: actions[i].onTap,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                child: Column(
                  children: [
                    Icon(actions[i].icon,
                        color: theme.colorScheme.primary, size: IconSizes.lg),
                    const SizedBox(height: 6),
                    Text(actions[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class QuickAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const QuickAction(this.icon, this.label, this.onTap);
}

/// The usual Home shortcuts, shared by Simple and Pro.
List<QuickAction> homeQuickActions(BuildContext context) => [
      QuickAction(
          Icons.qr_code_scanner_rounded, 'Scan', () => scanAndLog(context)),
      QuickAction(
          Icons.event_note_rounded,
          'Planner',
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MealPlanScreen()))),
      QuickAction(Icons.water_drop_outlined, '+ Water', () {
        final metric = context.read<SettingsCubit>().state.metric;
        context.read<TrackerCubit>().addWater(metric ? 250 : 237);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              duration: const Duration(seconds: 2),
              content: Text(
                  'Added ${Units.volume(metric ? 250 : 237, metric)} of water')));
      }),
    ];

/// Latest weight, change over the last week, and a tiny trend line.
class WeightSummaryCard extends StatelessWidget {
  const WeightSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weights = context.watch<TrackerCubit>().state.weights;
    final metric = context.select((SettingsCubit c) => c.state.metric);
    void open() => Navigator.push(
        context, MaterialPageRoute(builder: (_) => const WeightScreen()));

    if (weights.isEmpty) {
      return AppCard(
        onTap: open,
        child: Row(
          children: [
            Icon(Icons.monitor_weight_outlined,
                color: theme.colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Track your weight',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Text('Log a weigh-in to see your weekly trend here.',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      );
    }

    final latest = weights.last;
    final weekAgo = latest.date.subtract(const Duration(days: 7));
    final past = weights.where((w) => !w.date.isAfter(weekAgo)).toList();
    final reference = past.isNotEmpty ? past.last : weights.first;
    final delta = latest.kg - reference.kg;
    final recent =
        weights.length > 14 ? weights.sublist(weights.length - 14) : weights;
    final deltaColor = delta.abs() < 0.05
        ? theme.colorScheme.onSurfaceVariant
        : (delta < 0 ? MacroColors.protein : MacroColors.carbs);

    return AppCard(
      onTap: open,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weight',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(Units.weight(latest.kg, metric),
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(
                  weights.length < 2
                      ? 'First weigh-in'
                      : '${delta >= 0 ? '+' : ''}${(metric ? delta : Units.kgToLb(delta)).toStringAsFixed(1)} ${Units.weightUnit(metric)} this week',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: deltaColor, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (recent.length >= 2)
            SizedBox(
              width: 120,
              height: 56,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < recent.length; i++)
                          FlSpot(i.toDouble(), recent[i].kg)
                      ],
                      isCurved: true,
                      barWidth: 3,
                      color: theme.colorScheme.primary,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                          show: true,
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.12)),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

/// Friendly placeholder for lists with nothing in them yet.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState(
      {super.key,
      required this.icon,
      required this.title,
      required this.message,
      this.actionLabel,
      this.onAction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      child: Column(
        children: [
          CircleAvatar(
              radius: 30,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(icon, size: 28, color: theme.colorScheme.primary)),
          const SizedBox(height: 14),
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
