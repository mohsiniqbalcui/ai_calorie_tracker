import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/meal_types.dart';
import '../../data/models/tracker_models.dart';
import '../cubit/food_log_cubit.dart';
import '../cubit/tracker_cubit.dart';
import '../screens/food_search_screen.dart';
import '../widgets/common.dart';

/// Logs [servings] of a recipe as a single diary entry.
void logRecipe(BuildContext context, Recipe r, double servings, String mealType) {
  context.read<FoodLogCubit>().addManual(
        name: r.name,
        calories: r.kcalPerServing * servings,
        protein: r.proteinPerServing * servings,
        carbs: r.carbsPerServing * servings,
        fat: r.fatPerServing * servings,
        quantity: r.gramsPerServing * servings,
        mealType: mealType,
        fiber: r.fiberPerServing * servings,
        sugar: r.sugarPerServing * servings,
        sodium: r.sodiumPerServing * servings,
        note: servings == 1 ? null : '${servings == servings.roundToDouble() ? servings.toInt() : servings} servings',
      );
}

class RecipesScreen extends StatelessWidget {
  /// When set, tapping a recipe returns it instead of opening the log sheet.
  final bool pick;
  const RecipesScreen({super.key, this.pick = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipes = context.watch<TrackerCubit>().state.recipes;

    return Scaffold(
      appBar: AppBar(title: Text(pick ? 'Pick a recipe' : 'My recipes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeEditorScreen())),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New recipe'),
      ),
      body: recipes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_rounded, size: 48, color: theme.colorScheme.primary),
                    const SizedBox(height: 12),
                    Text('No recipes yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('Combine ingredients and we will work out the calories and macros per serving.', textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: recipes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final r = recipes[i];
                return Dismissible(
                  key: ValueKey(r.id),
                  direction: pick ? DismissDirection.none : DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.delete_rounded, color: Colors.white),
                  ),
                  onDismissed: (_) => context.read<TrackerCubit>().deleteRecipe(r.id),
                  child: AppCard(
                    onTap: () {
                      if (pick) {
                        Navigator.pop(context, r);
                      } else {
                        showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => _RecipeSheet(recipe: r, parent: context));
                      }
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 2),
                              Text('${r.ingredients.length} ingredients · ${r.servings} servings', style: theme.textTheme.labelSmall),
                              const SizedBox(height: 6),
                              Text('P ${r.proteinPerServing.round()}  C ${r.carbsPerServing.round()}  F ${r.fatPerServing.round()}  per serving', style: theme.textTheme.labelSmall),
                            ],
                          ),
                        ),
                        Column(children: [
                          Text('${r.kcalPerServing.round()}', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: MacroColors.calories)),
                          Text('kcal / serving', style: theme.textTheme.labelSmall),
                        ]),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _RecipeSheet extends StatefulWidget {
  final Recipe recipe;
  final BuildContext parent;
  const _RecipeSheet({required this.recipe, required this.parent});

  @override
  State<_RecipeSheet> createState() => _RecipeSheetState();
}

class _RecipeSheetState extends State<_RecipeSheet> {
  double _servings = 1;
  String _mealType = MealTypes.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = widget.recipe;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(r.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            for (final i in r.ingredients)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(children: [Expanded(child: Text(i.name)), Text('${i.grams.round()} g · ${i.kcal.round()} kcal', style: theme.textTheme.labelMedium)]),
              ),
            const Divider(height: 24),
            Row(
              children: [
                IconButton.outlined(onPressed: () => setState(() => _servings = (_servings - 0.5).clamp(0.5, 20)), icon: const Icon(Icons.remove_rounded)),
                Expanded(child: Center(child: Text('${_servings == _servings.roundToDouble() ? _servings.toInt() : _servings} serving(s) · ${(r.kcalPerServing * _servings).round()} kcal', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)))),
                IconButton.outlined(onPressed: () => setState(() => _servings = (_servings + 0.5).clamp(0.5, 20)), icon: const Icon(Icons.add_rounded)),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                for (final m in MealTypes.all)
                  ChoiceChip(avatar: Icon(m.icon, size: 16), label: Text(m.label), selected: _mealType == m.key, onSelected: (_) => setState(() => _mealType = m.key)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(widget.parent, MaterialPageRoute(builder: (_) => RecipeEditorScreen(existing: r)));
                    },
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () {
                      logRecipe(widget.parent, r, _servings, _mealType);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(widget.parent).showSnackBar(SnackBar(content: Text('Logged ${r.name}')));
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Log to diary'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeEditorScreen extends StatefulWidget {
  final Recipe? existing;
  const RecipeEditorScreen({super.key, this.existing});

  @override
  State<RecipeEditorScreen> createState() => _RecipeEditorScreenState();
}

class _RecipeEditorScreenState extends State<RecipeEditorScreen> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late int _servings = widget.existing?.servings ?? 2;
  late final List<RecipeIngredient> _ingredients = [...?widget.existing?.ingredients];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Recipe get _draft => Recipe(
        id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        servings: _servings,
        ingredients: _ingredients,
      );

  Future<void> _addIngredient() async {
    final result = await Navigator.push<ServingResult>(context, MaterialPageRoute(builder: (_) => const FoodSearchScreen(pick: true)));
    if (result == null) return;
    final p = result.portion;
    setState(() => _ingredients.add(RecipeIngredient(
          name: result.entry.name,
          grams: p.grams,
          kcal: p.kcal,
          protein: p.protein,
          carbs: p.carbs,
          fat: p.fat,
          fiber: p.fiber,
          sugar: p.sugar,
          sodium: p.sodium,
        )));
  }

  void _save() {
    if (_name.text.trim().isEmpty || _ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a name and at least one ingredient.')));
      return;
    }
    context.read<TrackerCubit>().saveRecipe(_draft);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = _draft;
    Widget stat(String l, String v, Color c) => Expanded(child: Column(children: [Text(v, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: c)), Text(l, style: theme.textTheme.labelSmall)]));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New recipe' : 'Edit recipe'),
        actions: [Padding(padding: const EdgeInsets.only(right: 8), child: FilledButton(onPressed: _save, child: const Text('Save')))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _name, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Recipe name'), onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('Makes', style: theme.textTheme.titleSmall)),
              IconButton.outlined(onPressed: _servings > 1 ? () => setState(() => _servings--) : null, icon: const Icon(Icons.remove_rounded)),
              SizedBox(width: 70, child: Center(child: Text('$_servings servings', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)))),
              IconButton.outlined(onPressed: () => setState(() => _servings++), icon: const Icon(Icons.add_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            color: theme.colorScheme.primary.withValues(alpha: 0.06),
            child: Column(children: [
              Text('${r.kcalPerServing.round()} kcal per serving', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Row(children: [
                stat('Protein', '${r.proteinPerServing.toStringAsFixed(1)} g', MacroColors.protein),
                stat('Carbs', '${r.carbsPerServing.toStringAsFixed(1)} g', MacroColors.carbs),
                stat('Fat', '${r.fatPerServing.toStringAsFixed(1)} g', MacroColors.fat),
              ]),
            ]),
          ),
          const SectionTitle('Ingredients'),
          if (_ingredients.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Center(child: Text('No ingredients yet.'))),
          for (var i = 0; i < _ingredients.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
                child: Row(
                  children: [
                    Expanded(child: Text('${_ingredients[i].name}  ·  ${_ingredients[i].grams.round()} g')),
                    Text('${_ingredients[i].kcal.round()} kcal', style: theme.textTheme.labelLarge),
                    IconButton(onPressed: () => setState(() => _ingredients.removeAt(i)), icon: const Icon(Icons.close_rounded)),
                  ],
                ),
              ),
            ),
          OutlinedButton.icon(onPressed: _addIngredient, icon: const Icon(Icons.add_rounded), label: const Text('Add ingredient')),
        ],
      ),
    );
  }
}
