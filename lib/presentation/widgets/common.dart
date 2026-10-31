import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/units.dart';
import '../cubit/food_log_cubit.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/tracker_cubit.dart';

/// Card with the theme's surface style. Tappable when [onTap] is set.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class MacroBar extends StatelessWidget {
  final String label;
  final double value;
  final double goal;
  final Color color;

  const MacroBar({super.key, required this.label, required this.value, required this.goal, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            color: color,
            backgroundColor: color.withValues(alpha: 0.16),
          ),
        ),
        const SizedBox(height: 4),
        Text('${value.round()} / ${goal.round()} g',
            style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class CalorieRing extends StatelessWidget {
  final double consumed;
  final double burned;
  final int goal;
  final double radius;

  const CalorieRing({super.key, required this.consumed, required this.goal, this.burned = 0, this.radius = 78});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budget = goal + burned;
    final remaining = budget - consumed;
    final over = remaining < 0;
    final color = over ? theme.colorScheme.error : MacroColors.calories;
    return CircularPercentIndicator(
      radius: radius,
      lineWidth: 11,
      animation: true,
      animateFromLastPercent: true,
      circularStrokeCap: CircularStrokeCap.round,
      percent: budget > 0 ? (consumed / budget).clamp(0.0, 1.0) : 0,
      progressColor: color,
      backgroundColor: color.withValues(alpha: 0.15),
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${remaining.abs().round()}',
            style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: over ? color : null),
          ),
          Text(over ? 'kcal over' : 'kcal left',
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class ModeToggleButton extends StatelessWidget {
  const ModeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isPro = context.select((SettingsCubit c) => c.state.isPro);
    return Tooltip(
      message: isPro ? 'Switch to Simple mode' : 'Switch to Pro mode',
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ActionChip(
          avatar: Icon(isPro ? Icons.insights_rounded : Icons.spa_rounded, size: 18),
          label: Text(isPro ? 'Pro' : 'Simple'),
          onPressed: () {
            context.read<SettingsCubit>().toggleUiMode();
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                duration: const Duration(seconds: 2),
                content: Text(isPro ? 'Simple mode: clean and focused' : 'Pro mode: full analytics and tools'),
              ));
          },
        ),
      ),
    );
  }
}

/// Previous / next day control shared by both modes.
class DateNavigator extends StatelessWidget {
  const DateNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    final date = context.select((FoodLogCubit c) => c.state.selectedDate);
    final today = DateFmt.dateOnly(DateTime.now());
    final isToday = DateFmt.sameDay(date, today);
    final theme = Theme.of(context);

    Future<void> pick() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: DateTime(2020),
        lastDate: today,
      );
      if (picked != null && context.mounted) selectDay(context, picked);
    }

    return Row(
      children: [
        IconButton.filledTonal(
          onPressed: () => selectDay(context, date.subtract(const Duration(days: 1))),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: pick,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  Text(DateFmt.relative(date), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  Text(DateFmt.short(date), style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ),
        IconButton.filledTonal(
          onPressed: isToday ? null : () => selectDay(context, date.add(const Duration(days: 1))),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

/// Keeps the food log and the water/exercise tracker on the same day.
void selectDay(BuildContext context, DateTime date) {
  final day = DateFmt.dateOnly(date);
  context.read<FoodLogCubit>().selectDate(day);
  context.read<TrackerCubit>().load(date: day);
}

class WaterCard extends StatelessWidget {
  final bool compact;
  const WaterCard({super.key, this.compact = false});

  Future<void> _custom(BuildContext context) async {
    final controller = TextEditingController();
    final metric = context.read<SettingsCubit>().state.metric;
    final tracker = context.read<TrackerCubit>();
    final ml = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add water'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: metric ? 'Amount (ml)' : 'Amount (fl oz)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text);
              Navigator.pop(ctx, v == null ? null : (metric ? v : v * 29.5735).round());
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ml != null && ml > 0) tracker.addWater(ml);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final water = context.select((TrackerCubit c) => c.state.waterMl);
    final goal = context.select((SettingsCubit c) => c.state.waterGoalMl);
    final metric = context.select((SettingsCubit c) => c.state.metric);
    final cubit = context.read<TrackerCubit>();
    final pct = goal > 0 ? (water / goal).clamp(0.0, 1.0) : 0.0;
    final step = metric ? 250 : 237;
    final amount = '${Units.volume(water, metric)} / ${Units.volume(goal, metric)}';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop_rounded, color: MacroColors.water),
              const SizedBox(width: 8),
              Text('Water', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              if (!compact) ...[
                const Spacer(),
                Text(amount, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ],
          ),
          if (compact) ...[
            const SizedBox(height: 6),
            Text(amount, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              color: MacroColors.water,
              backgroundColor: MacroColors.water.withValues(alpha: 0.16),
            ),
          ),
          if (!compact) const SizedBox(height: 12),
          if (!compact)
            Row(
              children: [
                IconButton.outlined(onPressed: () => cubit.addWater(-step), icon: const Icon(Icons.remove_rounded)),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => cubit.addWater(step),
                    icon: const Icon(Icons.local_drink_rounded),
                    label: Text('+ ${Units.volume(step, metric)}'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(onPressed: () => _custom(context), icon: const Icon(Icons.edit_rounded)),
              ],
            ),
        ],
      ),
    );
  }
}
