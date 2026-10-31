import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/meal_types.dart';
import '../../data/models/food_item.dart';
import '../cubit/food_log_cubit.dart';

class EditMealScreen extends StatefulWidget {
  final FoodItem meal;
  const EditMealScreen({super.key, required this.meal});

  @override
  State<EditMealScreen> createState() => _EditMealScreenState();
}

class _EditMealScreenState extends State<EditMealScreen> {
  late final FoodItem _base = widget.meal;
  late final _name = TextEditingController(text: _base.name);
  late final _kcal =
      TextEditingController(text: _base.calories.toStringAsFixed(0));
  late final _protein =
      TextEditingController(text: _base.protein.toStringAsFixed(1));
  late final _carbs =
      TextEditingController(text: _base.carbs.toStringAsFixed(1));
  late final _fat = TextEditingController(text: _base.fat.toStringAsFixed(1));
  late final _qty =
      TextEditingController(text: _base.quantity.toStringAsFixed(0));
  late final _note = TextEditingController(text: _base.note ?? '');
  late String _mealType = _base.mealType;
  double _servings = 1;

  @override
  void dispose() {
    for (final c in [_name, _kcal, _protein, _carbs, _fat, _qty, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyServings(double s) {
    setState(() {
      _servings = s;
      _kcal.text = (_base.calories * s).toStringAsFixed(0);
      _protein.text = (_base.protein * s).toStringAsFixed(1);
      _carbs.text = (_base.carbs * s).toStringAsFixed(1);
      _fat.text = (_base.fat * s).toStringAsFixed(1);
      _qty.text = (_base.quantity * s).toStringAsFixed(0);
    });
  }

  double _n(TextEditingController c, double fallback) =>
      double.tryParse(c.text.trim()) ?? fallback;

  void _save() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    context.read<FoodLogCubit>().updateMeal(_base.copyWith(
          name: name,
          calories: _n(_kcal, _base.calories),
          protein: _n(_protein, _base.protein),
          carbs: _n(_carbs, _base.carbs),
          fat: _n(_fat, _base.fat),
          quantity: _n(_qty, _base.quantity),
          mealType: _mealType,
          note: _note.text.trim(),
        ));
    Navigator.pop(context);
  }

  Widget _num(TextEditingController c, String label) => Expanded(
        child: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit meal'),
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton(onPressed: _save, child: const Text('Save')))
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Meal name')),
          const SizedBox(height: 16),
          Text('Servings',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final s in [0.5, 1.0, 1.5, 2.0, 3.0])
                ChoiceChip(
                    label: Text('${s == s.roundToDouble() ? s.toInt() : s}×'),
                    selected: _servings == s,
                    onSelected: (_) => _applyServings(s)),
            ],
          ),
          const SizedBox(height: 16),
          Row(children: [
            _num(_kcal, 'Calories (kcal)'),
            const SizedBox(width: 10),
            _num(_qty, 'Quantity (g)')
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _num(_protein, 'Protein g'),
            const SizedBox(width: 10),
            _num(_carbs, 'Carbs g'),
            const SizedBox(width: 10),
            _num(_fat, 'Fat g')
          ]),
          const SizedBox(height: 16),
          Text('Meal',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final m in MealTypes.all)
                ChoiceChip(
                    avatar: Icon(m.icon, size: 16),
                    label: Text(m.label),
                    selected: _mealType == m.key,
                    onSelected: (_) => setState(() => _mealType = m.key)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Notes (optional)', alignLabelWithHint: true)),
        ],
      ),
    );
  }
}
