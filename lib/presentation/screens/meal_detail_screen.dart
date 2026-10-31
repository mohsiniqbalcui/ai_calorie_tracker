import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/meal_types.dart';
import '../../data/models/food_item.dart';
import '../cubit/food_log_cubit.dart';
import '../cubit/tracker_cubit.dart';
import '../widgets/common.dart';
import 'edit_meal_screen.dart';

class MealDetailScreen extends StatelessWidget {
  final FoodItem meal;
  const MealDetailScreen({super.key, required this.meal});

  Future<void> _delete(BuildContext context) async {
    final cubit = context.read<FoodLogCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete meal?'),
        content: Text('"${meal.name}" will be removed from your diary.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      cubit.deleteMeal(meal);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFav = context.select((TrackerCubit c) => c.state.isFavorite(meal.name));
    final type = MealTypes.byKey(meal.mealType);
    final kcalFromMacros = meal.protein * 4 + meal.carbs * 4 + meal.fat * 9;
    double share(double kcal) => kcalFromMacros > 0 ? kcal / kcalFromMacros : 0;
    final time = TimeOfDay.fromDateTime(meal.timestamp).format(context);

    Widget row(IconData icon, String label, String value, Color color) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
              Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(meal.name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Favorite',
            onPressed: () => context.read<TrackerCubit>().toggleFavorite(meal),
            icon: Icon(isFav ? Icons.star_rounded : Icons.star_outline_rounded, color: isFav ? Colors.amber : null),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditMealScreen(meal: meal))).then((_) {
              if (context.mounted) Navigator.pop(context);
            }),
          ),
          IconButton(icon: Icon(Icons.delete_rounded, color: theme.colorScheme.error), onPressed: () => _delete(context)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (meal.imageUrl != null && meal.imageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: meal.imageUrl!.startsWith('http')
                    ? Image.network(meal.imageUrl!, height: 200, width: double.infinity, fit: BoxFit.cover)
                    : Image.file(File(meal.imageUrl!), height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
          AppCard(
            child: Column(
              children: [
                Text('${meal.calories.round()}', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, color: MacroColors.calories)),
                Text('kcal', style: theme.textTheme.labelLarge),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      Expanded(flex: (share(meal.protein * 4) * 1000).round().clamp(1, 1000), child: Container(height: 10, color: MacroColors.protein)),
                      Expanded(flex: (share(meal.carbs * 4) * 1000).round().clamp(1, 1000), child: Container(height: 10, color: MacroColors.carbs)),
                      Expanded(flex: (share(meal.fat * 9) * 1000).round().clamp(1, 1000), child: Container(height: 10, color: MacroColors.fat)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                row(Icons.fitness_center_rounded, 'Protein', '${meal.protein.toStringAsFixed(1)} g', MacroColors.protein),
                row(Icons.grain_rounded, 'Carbs', '${meal.carbs.toStringAsFixed(1)} g', MacroColors.carbs),
                row(Icons.opacity_rounded, 'Fat', '${meal.fat.toStringAsFixed(1)} g', MacroColors.fat),
                if (meal.fiber > 0) row(Icons.grass_rounded, 'Fiber', '${meal.fiber.toStringAsFixed(1)} g', Colors.teal),
                if (meal.sugar > 0) row(Icons.cake_rounded, 'Sugar', '${meal.sugar.toStringAsFixed(1)} g', Colors.pink),
                if (meal.sodium > 0) row(Icons.grain_rounded, 'Sodium', '${meal.sodium.round()} mg', Colors.blueGrey),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                row(type.icon, 'Meal', type.label, theme.colorScheme.primary),
                row(Icons.scale_rounded, 'Quantity', '${meal.quantity.toStringAsFixed(0)} g', theme.colorScheme.primary),
                row(Icons.access_time_rounded, 'Logged', '${meal.timestamp.day}/${meal.timestamp.month}  $time', theme.colorScheme.primary),
                if (meal.note != null && meal.note!.isNotEmpty) ...[
                  const Divider(),
                  Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(top: 10), child: Text(meal.note!))),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              final selected = context.read<FoodLogCubit>().state.selectedDate;
              context.read<FoodLogCubit>().addFromTemplate(meal, mealType: meal.mealType);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logged again on ${selected.day}/${selected.month}')));
              Navigator.pop(context);
            },
            icon: const Icon(Icons.replay_rounded),
            label: const Text('Log again'),
          ),
        ],
      ),
    );
  }
}
