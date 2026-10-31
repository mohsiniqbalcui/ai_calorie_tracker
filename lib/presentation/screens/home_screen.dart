import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../cubit/food_log_cubit.dart';
import '../cubit/settings_cubit.dart';
import '../pro/pro_home_extras.dart';
import '../widgets/add_food_flow.dart';
import '../widgets/common.dart';
import '../widgets/home_widgets.dart';
import '../widgets/insight_card.dart';
import '../widgets/meal_tile.dart';
import 'food_search_screen.dart';

/// Home dashboard for both modes. Simple keeps it calm; Pro adds the
/// analytics sections underneath.
class HomeScreen extends StatelessWidget {
  final VoidCallback? onProfileTap;
  const HomeScreen({super.key, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    final isPro = context.select((SettingsCubit c) => c.state.isPro);
    final width = MediaQuery.of(context).size.width;
    final gutter = Spacing.pageGutter(width);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<FoodLogCubit, FoodLogState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () => context.read<FoodLogCubit>().loadDailyLog(),
              child: ListView(
                padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 120),
                children: [
                  HomeHeader(
                      onAvatarTap: onProfileTap,
                      actions: const [ModeToggleButton()]),
                  const BackToTodayChip(),
                  const SizedBox(height: 16),
                  const SearchFoodBar(),
                  const SizedBox(height: 16),
                  const StatusBanner(),
                  if (state.isLoading && state.meals.isEmpty)
                    const Padding(
                        padding: EdgeInsets.all(48),
                        child: Center(child: CircularProgressIndicator()))
                  else ...[
                    const CalorieSummaryCard(),
                    const SizedBox(height: 16),
                    if (isPro) ...[
                      const ProHomeExtras(),
                      const SizedBox(height: 16)
                    ] else ...[
                      const InsightCard(),
                      const SizedBox(height: 16)
                    ],
                    Row(
                      children: [
                        Expanded(
                            child: Text('Meals',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800))),
                        if (state.meals.isEmpty)
                          TextButton.icon(
                            onPressed: () => context
                                .read<FoodLogCubit>()
                                .copyMealsFrom(state.selectedDate
                                    .subtract(const Duration(days: 1))),
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text('Copy yesterday'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    MealList(meals: state.meals, detailed: isPro),
                    const SizedBox(height: 4),
                    QuickActions(actions: homeQuickActions(context)),
                    const SizedBox(height: 16),
                    const WaterCard(),
                    const SizedBox(height: 16),
                    const WeightSummaryCard(),
                  ],
                ],
              ),
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
