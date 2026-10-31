import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/food_log_cubit.dart';
import '../widgets/add_food_flow.dart';
import '../widgets/common.dart';
import '../widgets/daily_tracker.dart';
import '../widgets/insight_card.dart';
import '../widgets/meal_tile.dart';
import 'food_search_screen.dart';

/// Simple mode home: one calm screen with everything for today.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_greeting()),
        automaticallyImplyLeading: false,
        actions: const [ModeToggleButton()],
      ),
      body: SafeArea(
        child: BlocBuilder<FoodLogCubit, FoodLogState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
              children: [
                const DateNavigator(),
                const SizedBox(height: 8),
                const SearchFoodBar(),
                const SizedBox(height: 8),
                const Align(alignment: Alignment.centerLeft, child: StreakChip()),
                const SizedBox(height: 8),
                const StatusBanner(),
                if (state.isLoading && state.meals.isEmpty)
                  const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
                else ...[
                  DailyTracker(calories: state.totalCalories, protein: state.totalProtein, carbs: state.totalCarbs, fat: state.totalFat),
                  const SizedBox(height: 12),
                  const InsightCard(),
                  const SizedBox(height: 12),
                  const WaterCard(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: Text('Meals', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
                      if (state.meals.isEmpty)
                        TextButton.icon(
                          onPressed: () => context.read<FoodLogCubit>().copyMealsFrom(state.selectedDate.subtract(const Duration(days: 1))),
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Copy yesterday'),
                        ),
                    ],
                  ),
                  MealList(meals: state.meals),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddFoodFlow.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add food'),
      ),
    );
  }
}
