import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/meal_types.dart';
import '../../data/food_database.dart';
import '../cubit/food_log_cubit.dart';
import '../cubit/settings_cubit.dart';
import '../widgets/common.dart';

/// What the user picked in the serving sheet.
class ServingResult {
  final FoodEntry entry;
  final double grams;
  final String mealType;
  const ServingResult(this.entry, this.grams, this.mealType);
  FoodPortion get portion => entry.portion(grams);
}

/// Search the built-in food database. In [pick] mode it returns the chosen
/// food and amount instead of logging it (used by recipes and the planner).
class FoodSearchScreen extends StatefulWidget {
  final bool pick;
  final String? mealType;
  const FoodSearchScreen({super.key, this.pick = false, this.mealType});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  String _query = '';
  String? _category;

  Future<void> _select(FoodEntry entry) async {
    final result = await ServingSheet.show(context, entry, mealType: widget.mealType ?? MealTypes.now(), pick: widget.pick);
    if (result == null || !mounted) return;
    if (widget.pick) {
      Navigator.pop(context, result);
      return;
    }
    final p = result.portion;
    context.read<FoodLogCubit>().addManual(
          name: entry.name,
          calories: p.kcal,
          protein: p.protein,
          carbs: p.carbs,
          fat: p.fat,
          quantity: p.grams,
          mealType: result.mealType,
          fiber: p.fiber,
          sugar: p.sugar,
          sodium: p.sodium,
        );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Added ${entry.name} · ${p.kcal.round()} kcal')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diet = context.watch<SettingsCubit>().state.diet;
    final results = FoodDatabase.search(_query, category: _category, diet: diet);

    return Scaffold(
      appBar: AppBar(title: Text(widget.pick ? 'Pick an ingredient' : 'Search food')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(hintText: 'Search e.g. "chicken", "rice", "apple"', prefixIcon: Icon(Icons.search_rounded)),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: const Text('All'), selected: _category == null, onSelected: (_) => setState(() => _category = null))),
                for (final c in FoodDatabase.categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(label: Text(c), selected: _category == c, onSelected: (_) => setState(() => _category = _category == c ? null : c)),
                  ),
              ],
            ),
          ),
          if (diet.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(children: [
                Icon(Icons.filter_alt_rounded, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(child: Text('Filtering: ${FoodDatabase.diets.where((d) => diet.contains(d.key)).map((d) => d.label).join(', ')}', style: theme.textTheme.labelMedium)),
              ]),
            ),
          Expanded(
            child: results.isEmpty
                ? Center(child: Padding(padding: const EdgeInsets.all(32), child: Text('No foods found.\nTry another word, or add it manually.', textAlign: TextAlign.center, style: theme.textTheme.bodyMedium)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final f = results[i];
                      final serving = f.portion(f.servingG);
                      return AppCard(
                        onTap: () => _select(f),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(f.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 2),
                                  Text('${f.servingLabel} · ${f.servingG.round()} g', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${serving.kcal.round()} kcal', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                                Text('P ${serving.protein.round()} · C ${serving.carbs.round()} · F ${serving.fat.round()}', style: theme.textTheme.labelSmall),
                              ],
                            ),
                            const SizedBox(width: 6),
                            Icon(widget.pick ? Icons.add_circle_outline_rounded : Icons.chevron_right_rounded),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Choose how much of a food: servings or exact grams, with live nutrition.
class ServingSheet extends StatefulWidget {
  final FoodEntry entry;
  final String mealType;
  final bool pick;
  const ServingSheet({super.key, required this.entry, required this.mealType, required this.pick});

  static Future<ServingResult?> show(BuildContext context, FoodEntry entry, {required String mealType, bool pick = false}) {
    return showModalBottomSheet<ServingResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ServingSheet(entry: entry, mealType: mealType, pick: pick),
    );
  }

  @override
  State<ServingSheet> createState() => _ServingSheetState();
}

class _ServingSheetState extends State<ServingSheet> {
  late double _servings = 1;
  late final _grams = TextEditingController(text: widget.entry.servingG.round().toString());
  late String _mealType = widget.mealType;

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  double get _g => double.tryParse(_grams.text.trim()) ?? 0;

  void _setServings(double s) {
    if (s < 0.25) return;
    setState(() {
      _servings = s;
      _grams.text = (widget.entry.servingG * s).round().toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = widget.entry;
    final p = e.portion(_g);

    Widget nutrient(String label, String value, Color color) => Expanded(
          child: Column(children: [
            Text(value, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: color)),
            Text(label, style: theme.textTheme.labelSmall),
          ]),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(e.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text('1 serving = ${e.servingLabel} (${e.servingG.round()} g)', style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton.outlined(onPressed: () => _setServings(_servings - 0.5), icon: const Icon(Icons.remove_rounded)),
                Expanded(child: Center(child: Text('${_servings == _servings.roundToDouble() ? _servings.toInt() : _servings} serving${_servings == 1 ? '' : 's'}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)))),
                IconButton.outlined(onPressed: () => _setServings(_servings + 0.5), icon: const Icon(Icons.add_rounded)),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _grams,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount (grams)', suffixText: 'g'),
              onChanged: (v) => setState(() => _servings = (double.tryParse(v) ?? 0) / e.servingG),
            ),
            const SizedBox(height: 16),
            AppCard(
              color: theme.colorScheme.primary.withValues(alpha: 0.06),
              child: Column(children: [
                Text('${p.kcal.round()} kcal', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Row(children: [
                  nutrient('Protein', '${p.protein.toStringAsFixed(1)} g', MacroColors.protein),
                  nutrient('Carbs', '${p.carbs.toStringAsFixed(1)} g', MacroColors.carbs),
                  nutrient('Fat', '${p.fat.toStringAsFixed(1)} g', MacroColors.fat),
                ]),
                const Divider(height: 20),
                Row(children: [
                  nutrient('Fiber', '${p.fiber.toStringAsFixed(1)} g', theme.colorScheme.onSurface),
                  nutrient('Sugar', '${p.sugar.toStringAsFixed(1)} g', theme.colorScheme.onSurface),
                  nutrient('Sodium', '${p.sodium.round()} mg', theme.colorScheme.onSurface),
                ]),
              ]),
            ),
            if (!widget.pick) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: [
                  for (final m in MealTypes.all)
                    ChoiceChip(avatar: Icon(m.icon, size: 16), label: Text(m.label), selected: _mealType == m.key, onSelected: (_) => setState(() => _mealType = m.key)),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _g > 0 ? () => Navigator.pop(context, ServingResult(e, _g, _mealType)) : null,
                child: Text(widget.pick ? 'Add ingredient' : 'Add to diary'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tappable search field that opens [FoodSearchScreen].
class SearchFoodBar extends StatelessWidget {
  const SearchFoodBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodSearchScreen())),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Text('Search food by name', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
          Icon(Icons.tune_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
