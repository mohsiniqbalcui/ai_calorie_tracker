import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../cubit/food_log_cubit.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/tracker_cubit.dart';
import '../tools/exercise_screen.dart';
import '../tools/fasting_screen.dart';
import '../widgets/add_food_flow.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/insight_card.dart';
import '../widgets/meal_tile.dart';
import '../screens/food_search_screen.dart';

class ProDashboard extends StatelessWidget {
  const ProDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final food = context.watch<FoodLogCubit>().state;
    final settings = context.watch<SettingsCubit>().state;
    final tracker = context.watch<TrackerCubit>().state;
    final burned = tracker.caloriesBurned;
    final net = food.totalCalories - burned;
    final remaining = settings.calorieGoal + burned - food.totalCalories;
    final recent = (List.of(food.meals)..sort((a, b) => b.timestamp.compareTo(a.timestamp))).take(4).toList();

    Widget kpi(String label, String value, Color color, IconData icon) => Expanded(
          child: AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(height: 8),
                Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        );

    Widget quick(IconData icon, String label, VoidCallback onTap) => Expanded(
          child: AppCard(
            onTap: onTap,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(children: [Icon(icon, color: theme.colorScheme.primary), const SizedBox(height: 4), Text(label, style: theme.textTheme.labelSmall)]),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        actions: const [ModeToggleButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          const DateNavigator(),
          const SizedBox(height: 10),
          const SearchFoodBar(),
          const SizedBox(height: 10),
          const StatusBanner(),
          Row(children: [
            kpi('Consumed', '${food.totalCalories.round()}', MacroColors.calories, Icons.restaurant_rounded),
            const SizedBox(width: 8),
            kpi('Burned', '${burned.round()}', MacroColors.protein, Icons.local_fire_department_rounded),
            const SizedBox(width: 8),
            kpi('Net', '${net.round()}', theme.colorScheme.primary, Icons.balance_rounded),
            const SizedBox(width: 8),
            kpi(remaining < 0 ? 'Over' : 'Remaining', '${remaining.abs().round()}', remaining < 0 ? theme.colorScheme.error : Colors.teal, Icons.flag_rounded),
          ]),
          const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: AppCard(
                    child: Center(child: CalorieRing(consumed: food.totalCalories, goal: settings.calorieGoal, burned: burned, radius: 62)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppCard(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        MacroPie(protein: food.totalProtein, carbs: food.totalCarbs, fat: food.totalFat, size: 96),
                        const SizedBox(height: 10),
                        MacroLegend(protein: food.totalProtein, carbs: food.totalCarbs, fat: food.totalFat),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Row(
              children: [
                Expanded(child: MacroBar(label: 'Protein', value: food.totalProtein, goal: settings.proteinGoal.toDouble(), color: MacroColors.protein)),
                const SizedBox(width: 12),
                Expanded(child: MacroBar(label: 'Carbs', value: food.totalCarbs, goal: settings.carbsGoal.toDouble(), color: MacroColors.carbs)),
                const SizedBox(width: 12),
                Expanded(child: MacroBar(label: 'Fat', value: food.totalFat, goal: settings.fatGoal.toDouble(), color: MacroColors.fat)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nutrition details', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: MacroBar(label: 'Fiber', value: food.totalFiber, goal: 28, color: Colors.teal)),
                  const SizedBox(width: 12),
                  Expanded(child: MacroBar(label: 'Sugar', value: food.totalSugar, goal: 50, color: Colors.pink)),
                  const SizedBox(width: 12),
                  Expanded(child: MacroBar(label: 'Sodium mg', value: food.totalSodium, goal: 2300, color: Colors.blueGrey)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const InsightCard(),
          const SizedBox(height: 10),
          Row(children: [
            quick(Icons.add_a_photo_rounded, 'Log food', () => AddFoodFlow.show(context)),
            const SizedBox(width: 8),
            quick(Icons.water_drop_rounded, '+ Water', () => context.read<TrackerCubit>().addWater(settings.metric ? 250 : 237)),
            const SizedBox(width: 8),
            quick(Icons.directions_run_rounded, 'Exercise', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExerciseScreen()))),
            const SizedBox(width: 8),
            quick(Icons.copy_rounded, 'Yesterday', () => context.read<FoodLogCubit>().copyMealsFrom(food.selectedDate.subtract(const Duration(days: 1)))),
          ]),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: WaterCard(compact: true)),
              const SizedBox(width: 10),
              const Expanded(child: _FastingMini()),
            ],
          ),
          const SectionTitle('Latest entries'),
          if (recent.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('No entries yet for this day.')))
          else
            for (final m in recent) Padding(padding: const EdgeInsets.only(bottom: 8), child: MealTile(meal: m, detailed: true)),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => AddFoodFlow.show(context), child: const Icon(Icons.add_rounded)),
    );
  }
}

class _FastingMini extends StatefulWidget {
  const _FastingMini();

  @override
  State<_FastingMini> createState() => _FastingMiniState();
}

class _FastingMiniState extends State<_FastingMini> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => mounted ? setState(() {}) : null);
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
    final elapsed = t.fastStart == null ? Duration.zero : DateTime.now().difference(t.fastStart!);
    final pct = t.isFasting ? (elapsed.inMinutes / (t.fastGoalHours * 60)).clamp(0.0, 1.0) : 0.0;
    return AppCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FastingScreen())),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.timer_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('Fasting', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: pct, minHeight: 10),
          ),
          const SizedBox(height: 8),
          Text(t.isFasting ? '${elapsed.inHours}h ${elapsed.inMinutes % 60}m / ${t.fastGoalHours}h' : 'Not fasting · tap to start', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
