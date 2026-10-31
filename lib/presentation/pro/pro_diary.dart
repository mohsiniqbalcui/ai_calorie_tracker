import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/meal_types.dart';
import '../cubit/food_log_cubit.dart';
import '../widgets/add_food_flow.dart';
import '../widgets/common.dart';
import '../widgets/insight_card.dart';
import '../widgets/meal_tile.dart';

/// Pro diary: search, filter by meal, per-meal macros and a day summary table.
class ProDiary extends StatefulWidget {
  const ProDiary({super.key});

  @override
  State<ProDiary> createState() => _ProDiaryState();
}

class _ProDiaryState extends State<ProDiary> {
  String _query = '';
  String? _type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final food = context.watch<FoodLogCubit>().state;

    Widget cell(String text, {bool bold = false, Color? color}) => Expanded(
          child: Text(text, textAlign: TextAlign.center, style: theme.textTheme.labelMedium?.copyWith(fontWeight: bold ? FontWeight.w800 : null, color: color)),
        );

    final summary = AppCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Row(children: [cell('Meal', bold: true), cell('kcal', bold: true), cell('P', bold: true, color: MacroColors.protein), cell('C', bold: true, color: MacroColors.carbs), cell('F', bold: true, color: MacroColors.fat)]),
          const Divider(height: 14),
          for (final t in MealTypes.all)
            Builder(builder: (_) {
              final items = food.meals.where((m) => m.mealType == t.key);
              double sum(double Function(dynamic) f) => items.fold(0.0, (s, m) => s + f(m));
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  cell(t.label),
                  cell('${sum((m) => m.calories).round()}'),
                  cell('${sum((m) => m.protein).round()}'),
                  cell('${sum((m) => m.carbs).round()}'),
                  cell('${sum((m) => m.fat).round()}'),
                ]),
              );
            }),
          const Divider(height: 14),
          Row(children: [
            cell('Total', bold: true),
            cell('${food.totalCalories.round()}', bold: true),
            cell('${food.totalProtein.round()}', bold: true),
            cell('${food.totalCarbs.round()}', bold: true),
            cell('${food.totalFat.round()}', bold: true),
          ]),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diary'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Copy yesterday\'s meals',
            onPressed: () => context.read<FoodLogCubit>().copyMealsFrom(food.selectedDate.subtract(const Duration(days: 1))),
            icon: const Icon(Icons.copy_all_rounded),
          ),
          const ModeToggleButton(),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          const DateNavigator(),
          const SizedBox(height: 10),
          const StatusBanner(),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search foods',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isEmpty ? null : IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => _query = '')),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: const Text('All'), selected: _type == null, onSelected: (_) => setState(() => _type = null))),
                for (final t in MealTypes.all)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(avatar: Icon(t.icon, size: 16), label: Text(t.label), selected: _type == t.key, onSelected: (_) => setState(() => _type = _type == t.key ? null : t.key)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          summary,
          const SizedBox(height: 4),
          MealList(meals: food.meals, detailed: true, query: _query, onlyType: _type),
          const SizedBox(height: 12),
          const InsightCard(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddFoodFlow.show(context, mealType: _type),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
    );
  }
}
