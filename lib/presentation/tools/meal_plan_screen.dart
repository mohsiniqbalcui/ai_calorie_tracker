import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/meal_types.dart';
import '../../core/utils/units.dart';
import '../../data/food_database.dart';
import '../../data/local/tracker_store.dart';
import '../../data/models/tracker_models.dart';
import '../cubit/food_log_cubit.dart';
import '../cubit/settings_cubit.dart';
import '../screens/food_search_screen.dart';
import '../widgets/common.dart';
import 'recipes_screen.dart';

/// Plan the next seven days against your calorie target, then log in one tap.
class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  late final TrackerStore _store = context.read<TrackerStore>();
  late DateTime _day = DateFmt.dateOnly(DateTime.now());
  late List<PlannedItem> _items = _store.getPlan(_day);

  void _select(DateTime d) => setState(() {
        _day = d;
        _items = _store.getPlan(d);
      });

  Future<void> _save(List<PlannedItem> items) async {
    await _store.setPlan(_day, items);
    setState(() => _items = items);
  }

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  Future<void> _addFood(String mealType) async {
    final r = await Navigator.push<ServingResult>(context, MaterialPageRoute(builder: (_) => FoodSearchScreen(pick: true, mealType: mealType)));
    if (r == null) return;
    final p = r.portion;
    await _save([..._items, PlannedItem(id: _id(), mealType: mealType, name: r.entry.name, grams: p.grams, kcal: p.kcal, protein: p.protein, carbs: p.carbs, fat: p.fat)]);
  }

  Future<void> _addRecipe(String mealType) async {
    final r = await Navigator.push<Recipe>(context, MaterialPageRoute(builder: (_) => const RecipesScreen(pick: true)));
    if (r == null) return;
    await _save([..._items, PlannedItem(id: _id(), mealType: mealType, name: r.name, grams: r.gramsPerServing, kcal: r.kcalPerServing, protein: r.proteinPerServing, carbs: r.carbsPerServing, fat: r.fatPerServing)]);
  }

  void _addMenu(String mealType) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.search_rounded), title: const Text('Search food'), onTap: () { Navigator.pop(ctx); _addFood(mealType); }),
          ListTile(leading: const Icon(Icons.menu_book_rounded), title: const Text('From my recipes'), onTap: () { Navigator.pop(ctx); _addRecipe(mealType); }),
        ]),
      ),
    );
  }

  void _generate() {
    final s = context.read<SettingsCubit>().state;
    final generated = PlanGenerator.day(goal: s.calorieGoal, diet: s.diet, seed: _day.difference(DateTime(2020)).inDays);
    _save(generated);
  }

  void _log(PlannedItem i) {
    selectDay(context, _day);
    context.read<FoodLogCubit>().addManual(
          name: i.name,
          calories: i.kcal,
          protein: i.protein,
          carbs: i.carbs,
          fat: i.fat,
          quantity: i.grams,
          mealType: i.mealType,
        );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logged ${i.name} to ${DateFmt.relative(_day).toLowerCase()}')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal = context.watch<SettingsCubit>().state.calorieGoal;
    final planned = _items.fold(0.0, (s, i) => s + i.kcal);
    final days = List.generate(7, (i) => DateFmt.dateOnly(DateTime.now()).add(Duration(days: i)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal planner'),
        actions: [
          TextButton.icon(onPressed: _generate, icon: const Icon(Icons.auto_awesome_rounded, size: 18), label: const Text('Auto-plan')),
          if (_items.isNotEmpty) IconButton(tooltip: 'Clear day', onPressed: () => _save([]), icon: const Icon(Icons.delete_sweep_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final d = days[i];
                final sel = DateFmt.sameDay(d, _day);
                final has = _store.getPlan(d).isNotEmpty;
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _select(d),
                  child: Container(
                    width: 56,
                    decoration: BoxDecoration(
                      color: sel ? theme.colorScheme.primary : theme.colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFmt.weekday(d), style: theme.textTheme.labelSmall?.copyWith(color: sel ? theme.colorScheme.onPrimary : null)),
                        Text('${d.day}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: sel ? theme.colorScheme.onPrimary : null)),
                        Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: has ? (sel ? theme.colorScheme.onPrimary : theme.colorScheme.primary) : Colors.transparent)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('${planned.round()}', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: MacroColors.calories)),
                  Text(' / $goal kcal planned', style: theme.textTheme.bodyMedium),
                ]),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(value: goal > 0 ? (planned / goal).clamp(0.0, 1.0) : 0, minHeight: 8, color: planned > goal * 1.1 ? theme.colorScheme.error : MacroColors.calories, backgroundColor: MacroColors.calories.withValues(alpha: 0.15)),
                ),
                const SizedBox(height: 8),
                Text('P ${_items.fold(0.0, (s, i) => s + i.protein).round()} g · C ${_items.fold(0.0, (s, i) => s + i.carbs).round()} g · F ${_items.fold(0.0, (s, i) => s + i.fat).round()} g', style: theme.textTheme.labelMedium),
              ],
            ),
          ),
          for (final type in MealTypes.all) ...[
            Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 6),
              child: Row(children: [
                Icon(type.icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(type.label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(visualDensity: VisualDensity.compact, onPressed: () => _addMenu(type.key), icon: const Icon(Icons.add_circle_outline_rounded)),
              ]),
            ),
            for (final i in _items.where((x) => x.mealType == type.key))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(i.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      Text('${i.grams.round()} g · ${i.kcal.round()} kcal', style: theme.textTheme.labelSmall),
                    ])),
                    IconButton(tooltip: 'Log to diary', onPressed: () => _log(i), icon: const Icon(Icons.check_circle_outline_rounded)),
                    IconButton(onPressed: () => _save(_items.where((x) => x.id != i.id).toList()), icon: const Icon(Icons.close_rounded)),
                  ]),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Builds a balanced day of eating around a calorie goal and diet choice.
class PlanGenerator {
  static const _split = {'breakfast': .25, 'lunch': .35, 'dinner': .30, 'snack': .10};

  static const _pools = <String, List<List<String>>>{
    'breakfast': [
      ['Oats (rolled, dry)', 'Whole wheat bread', 'Chapati'],
      ['Egg, boiled', 'Greek yogurt', 'Tofu', 'Milk, whole', 'Peanut butter'],
      ['Banana', 'Blueberries', 'Apple', 'Strawberries', 'Orange'],
    ],
    'lunch': [
      ['Chicken breast, cooked', 'Lentils, cooked', 'Chickpeas, cooked', 'Salmon, cooked', 'Tofu', 'Paneer', 'Black beans, cooked'],
      ['White rice, cooked', 'Brown rice, cooked', 'Quinoa, cooked', 'Pasta, cooked', 'Sweet potato, baked'],
      ['Broccoli', 'Spinach', 'Carrot', 'Green beans', 'Cauliflower', 'Bell pepper'],
    ],
    'dinner': [
      ['Salmon, cooked', 'Tofu', 'Chicken breast, cooked', 'Tempeh', 'Lentils, cooked', 'Paneer', 'Kidney beans, cooked'],
      ['Quinoa, cooked', 'Brown rice, cooked', 'Sweet potato, baked', 'Potato, boiled', 'White rice, cooked'],
      ['Cauliflower', 'Green beans', 'Broccoli', 'Mushrooms', 'Spinach', 'Tomato'],
    ],
    'snack': [
      ['Apple', 'Banana', 'Orange', 'Grapes', 'Strawberries'],
      ['Almonds', 'Walnuts', 'Hummus', 'Greek yogurt', 'Cashews'],
    ],
  };

  /// Largest sensible amount, in servings, for a food in one meal.
  static double _maxServings(FoodEntry f, bool main) => switch (f.category) {
        'Vegetables' => 3,
        'Fruit' || 'Drinks' => 2,
        _ => main ? 5 : 3,
      };

  static List<PlannedItem> day({required int goal, required Set<String> diet, required int seed}) {
    final items = <PlannedItem>[];
    var n = 0;
    for (final type in MealTypes.all) {
      final target = goal * _split[type.key]!;
      final slots = _pools[type.key]!;
      final shares = switch (type.key) {
        'breakfast' => [.45, .35, .20],
        'snack' => [.55, .45],
        _ => [.45, .45, .10],
      };

      // Pick one food per slot that matches the diet.
      final foods = <FoodEntry?>[];
      for (var s = 0; s < slots.length; s++) {
        final options = slots[s].map(FoodDatabase.byName).whereType<FoodEntry>().where((f) => f.matchesDiet(diet)).toList();
        foods.add(options.isEmpty ? null : options[(seed + n * 3 + s) % options.length]);
      }

      // Allocate calories, capping each food at a realistic portion.
      final grams = List<double>.filled(slots.length, 0);
      for (var s = 0; s < slots.length; s++) {
        final f = foods[s];
        if (f == null) continue;
        final wanted = target * shares[s] / f.kcal * 100;
        grams[s] = wanted.clamp(0, f.servingG * _maxServings(f, s == 0));
      }
      // Hand any shortfall to the main items, still within their caps.
      var missing = target - [for (var s = 0; s < slots.length; s++) if (foods[s] != null) foods[s]!.portion(grams[s]).kcal].fold(0.0, (a, b) => a + b);
      for (var s = 0; s < slots.length && missing > 5; s++) {
        final f = foods[s];
        if (f == null) continue;
        final room = f.servingG * (_maxServings(f, true) + 1) - grams[s];
        final add = (missing / f.kcal * 100).clamp(0, room < 0 ? 0 : room);
        grams[s] += add;
        missing -= add * f.kcal / 100;
      }

      for (var s = 0; s < slots.length; s++) {
        final f = foods[s];
        if (f == null) continue;
        final g = (grams[s] / 5).round() * 5.0;
        if (g < 10) continue;
        final p = f.portion(g);
        items.add(PlannedItem(id: '${DateTime.now().microsecondsSinceEpoch}_${n}_$s', mealType: type.key, name: f.name, grams: g, kcal: p.kcal, protein: p.protein, carbs: p.carbs, fat: p.fat));
      }
      n++;
    }
    return items;
  }
}
