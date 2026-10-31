import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/settings_cubit.dart';
import '../tools/body_metrics_screen.dart';
import '../tools/exercise_screen.dart';
import '../tools/fasting_screen.dart';
import '../tools/meal_plan_screen.dart';
import '../tools/measurements_screen.dart';
import '../tools/recipes_screen.dart';
import '../screens/food_search_screen.dart';
import '../tools/weight_screen.dart';
import '../widgets/add_food_flow.dart';
import '../widgets/common.dart';
import '../widgets/manual_food_sheet.dart';
import '../../core/utils/meal_types.dart';

class ProTools extends StatelessWidget {
  const ProTools({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void open(Widget screen) => Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

    final tools = <(IconData, String, String, VoidCallback)>[
      (Icons.search_rounded, 'Food search', 'Database with servings', () => open(const FoodSearchScreen())),
      (Icons.menu_book_rounded, 'Recipes', 'Ingredient-based calories', () => open(const RecipesScreen())),
      (Icons.event_note_rounded, 'Meal planner', 'Plan to your goal', () => open(const MealPlanScreen())),
      (Icons.straighten_rounded, 'Measurements', 'Body fat and tape', () => open(const MeasurementsScreen())),
      (Icons.monitor_weight_rounded, 'Weight', 'Log and chart weigh-ins', () => open(const WeightScreen())),
      (Icons.monitor_heart_rounded, 'Body metrics', 'BMI, BMR, targets', () => open(const BodyMetricsScreen())),
      (Icons.directions_run_rounded, 'Exercise', 'Calories burned', () => open(const ExerciseScreen())),
      (Icons.timer_rounded, 'Fasting', 'Intermittent fasting timer', () => open(const FastingScreen())),
      (Icons.bolt_rounded, 'Quick add', 'Log calories fast', () => ManualFoodSheet.show(context, mealType: MealTypes.now(), quick: true)),
      (Icons.edit_note_rounded, 'Manual entry', 'Enter full macros', () => ManualFoodSheet.show(context, mealType: MealTypes.now())),
      (Icons.add_a_photo_rounded, 'Scan / describe', 'Photo, text or voice', () => AddFoodFlow.show(context)),
      (Icons.water_drop_rounded, 'Water goal', 'Change daily target', () => _waterGoal(context)),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Tools'), automaticallyImplyLeading: false, actions: const [ModeToggleButton()]),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.35,
        children: [
          for (final t in tools)
            AppCard(
              onTap: t.$4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(t.$1, size: 28, color: theme.colorScheme.primary),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.$2, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    Text(t.$3, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ]),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Future<void> _waterGoal(BuildContext context) => editWaterGoal(context);
}

Future<void> editWaterGoal(BuildContext context) async {
  final cubit = context.read<SettingsCubit>();
  final metric = cubit.state.metric;
  final controller = TextEditingController(text: (metric ? cubit.state.waterGoalMl : cubit.state.waterGoalMl / 29.5735).round().toString());
  final ml = await showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Daily water goal'),
      content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: metric ? 'Millilitres' : 'Fluid ounces')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final v = double.tryParse(controller.text);
            if (v == null || v < 100) return;
            Navigator.pop(ctx, (metric ? v : v * 29.5735).round());
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (ml != null) cubit.setWaterGoal(ml);
}
