import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/meal_types.dart';
import '../cubit/food_log_cubit.dart';
import '../cubit/settings_cubit.dart';
import '../widgets/add_food_flow.dart';
import '../widgets/common.dart';
import '../widgets/home_widgets.dart';
import '../widgets/insight_card.dart';
import '../widgets/meal_tile.dart';

/// Day-by-day food diary. Pro adds search, a meal filter and a macro table.
class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  String _query = '';
  String? _type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final food = context.watch<FoodLogCubit>().state;
    final s = context.watch<SettingsCubit>().state;
    final gutter = Spacing.pageGutter(MediaQuery.of(context).size.width);

    Widget cell(String text,
            {bool bold = false,
            Color? color,
            TextAlign align = TextAlign.center,
            int flex = 1}) =>
        Expanded(
          flex: flex,
          child: Text(text,
              textAlign: align,
              style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: bold ? FontWeight.w800 : null, color: color)),
        );

    final table = AppCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      child: Column(
        children: [
          Row(children: [
            cell('Meal', bold: true, align: TextAlign.left, flex: 2),
            cell('kcal', bold: true),
            cell('P', bold: true, color: MacroColors.protein),
            cell('C', bold: true, color: MacroColors.carbs),
            cell('F', bold: true, color: MacroColors.fat),
          ]),
          const Divider(height: 18),
          for (final t in MealTypes.all)
            Builder(builder: (_) {
              final items = food.meals.where((m) => m.mealType == t.key);
              double sum(double Function(dynamic) f) =>
                  items.fold(0.0, (acc, m) => acc + f(m));
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  cell(t.label, align: TextAlign.left, flex: 2),
                  cell('${sum((m) => m.calories).round()}'),
                  cell('${sum((m) => m.protein).round()}'),
                  cell('${sum((m) => m.carbs).round()}'),
                  cell('${sum((m) => m.fat).round()}'),
                ]),
              );
            }),
        ],
      ),
    );

    final daySummary = AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${food.totalCalories.round()} / ${s.calorieGoal} kcal',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      food.totalCalories > s.calorieGoal
                          ? '${(food.totalCalories - s.calorieGoal).round()} kcal over'
                          : '${(s.calorieGoal - food.totalCalories).round()} kcal left',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Text(
                  '${food.meals.length} ${food.meals.length == 1 ? 'entry' : 'entries'}',
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: s.calorieGoal > 0
                  ? (food.totalCalories / s.calorieGoal).clamp(0.0, 1.0)
                  : 0,
              minHeight: 10,
              color: food.totalCalories > s.calorieGoal
                  ? theme.colorScheme.error
                  : MacroColors.calories,
              backgroundColor: MacroColors.calories.withValues(alpha: 0.15),
            ),
          ),
          const SizedBox(height: 16),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diary'),
        actions: [
          IconButton(
            tooltip: "Copy yesterday's meals",
            onPressed: () => context.read<FoodLogCubit>().copyMealsFrom(
                food.selectedDate.subtract(const Duration(days: 1))),
            icon: const Icon(Icons.copy_all_rounded),
          ),
          const ModeToggleButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<FoodLogCubit>().loadDailyLog(),
        child: ListView(
          padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 120),
          children: [
            const DateNavigator(),
            const SizedBox(height: 12),
            const StatusBanner(),
            if (food.isLoading && food.meals.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()))
            else ...[
              daySummary,
              const SizedBox(height: 16),
              if (s.isPro) ...[
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search this day',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(() => _query = '')),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                              label: const Text('All'),
                              selected: _type == null,
                              onSelected: (_) => setState(() => _type = null))),
                      for (final t in MealTypes.all)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                              avatar: Icon(t.icon, size: 18),
                              label: Text(t.label),
                              selected: _type == t.key,
                              onSelected: (_) => setState(
                                  () => _type = _type == t.key ? null : t.key)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                table,
                const SizedBox(height: 16),
              ],
              if (food.meals.isEmpty)
                AppCard(
                  child: EmptyState(
                    icon: Icons.restaurant_menu_rounded,
                    title: food.isToday
                        ? 'Nothing logged yet'
                        : 'No meals on this day',
                    message:
                        'Search a food, scan a barcode or snap a photo to start your diary.',
                    actionLabel: 'Add food',
                    onAction: () => AddFoodFlow.show(context, mealType: _type),
                  ),
                )
              else
                MealList(
                    meals: food.meals,
                    detailed: s.isPro,
                    query: _query,
                    onlyType: _type),
              if (s.isPro) ...[const SizedBox(height: 4), const InsightCard()],
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddFoodFlow.show(context, mealType: _type),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add food'),
      ),
    );
  }
}
