import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/meal_types.dart';
import '../../data/models/food_item.dart';
import '../cubit/food_log_cubit.dart';
import '../cubit/tracker_cubit.dart';
import '../screens/meal_detail_screen.dart';
import 'add_food_launcher.dart';
import 'common.dart';
import 'food_thumb.dart';

/// One logged meal. Swipe left to delete (with undo), tap for details.
class MealTile extends StatelessWidget {
  final FoodItem meal;
  final bool detailed;
  const MealTile({super.key, required this.meal, this.detailed = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = MealTypes.byKey(meal.mealType);
    final isFav =
        context.select((TrackerCubit c) => c.state.isFavorite(meal.name));
    final time = TimeOfDay.fromDateTime(meal.timestamp).format(context);

    return Dismissible(
      key: ValueKey(meal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
            color: theme.colorScheme.error,
            borderRadius: BorderRadius.circular(Radii.md)),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) {
        final cubit = context.read<FoodLogCubit>();
        cubit.deleteMeal(meal);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text('Deleted "${meal.name}"'),
            action: SnackBarAction(
                label: 'Undo', onPressed: () => cubit.restoreMeal(meal)),
          ));
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.md),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => MealDetailScreen(meal: meal))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              FoodThumb(imageUrl: meal.imageUrl, icon: type.icon, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(meal.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    if (detailed)
                      Text.rich(
                          TextSpan(children: [
                            TextSpan(
                                text: '${meal.quantity.round()} g · $time  '),
                            TextSpan(
                                text: 'P ${meal.protein.round()}  ',
                                style: const TextStyle(
                                    color: MacroColors.protein,
                                    fontWeight: FontWeight.w700)),
                            TextSpan(
                                text: 'C ${meal.carbs.round()}  ',
                                style: const TextStyle(
                                    color: MacroColors.carbs,
                                    fontWeight: FontWeight.w700)),
                            TextSpan(
                                text: 'F ${meal.fat.round()}',
                                style: const TextStyle(
                                    color: MacroColors.fat,
                                    fontWeight: FontWeight.w700)),
                          ]),
                          style: theme.textTheme.labelSmall)
                    else
                      Text('${meal.quantity.round()} g · $time',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    if (meal.note != null && meal.note!.isNotEmpty)
                      Text(meal.note!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Text('${meal.calories.round()}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              Text(' kcal', style: theme.textTheme.labelSmall),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: isFav ? 'Remove favorite' : 'Add to favorites',
                onPressed: () =>
                    context.read<TrackerCubit>().toggleFavorite(meal),
                icon: Icon(
                    isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isFav ? Colors.amber : null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Meals grouped by breakfast/lunch/dinner/snacks, one card per meal with
/// its calorie total and an add button.
class MealList extends StatelessWidget {
  final List<FoodItem> meals;
  final bool detailed;
  final String query;
  final String? onlyType;

  const MealList(
      {super.key,
      required this.meals,
      this.detailed = false,
      this.query = '',
      this.onlyType});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final q = query.trim().toLowerCase();
    final filtered = meals
        .where((m) => q.isEmpty || m.name.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final types =
        MealTypes.all.where((t) => onlyType == null || t.key == onlyType);

    return Column(
      children: [
        for (final type in types)
          Builder(builder: (context) {
            final items =
                filtered.where((m) => m.mealType == type.key).toList();
            if (q.isNotEmpty && items.isEmpty) return const SizedBox.shrink();
            final kcal = items.fold(0.0, (s, m) => s + m.calories);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                            radius: 18,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(type.icon,
                                size: 20, color: theme.colorScheme.primary)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(type.label,
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w800)),
                              Text(
                                items.isEmpty
                                    ? 'Nothing logged'
                                    : '${items.length} ${items.length == 1 ? 'item' : 'items'} · ${kcal.round()} kcal',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Add ${type.label.toLowerCase()}',
                          onPressed: () =>
                              AddFoodFlowLauncher.open(context, type.key),
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                    if (items.isNotEmpty) const SizedBox(height: 10),
                    for (final m in items)
                      Padding(
                          padding: const EdgeInsets.only(right: 8, bottom: 8),
                          child: MealTile(meal: m, detailed: detailed)),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
