import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/meal_types.dart';
import '../cubit/food_log_cubit.dart';

/// Manual entry form. With [quick] set it only asks for calories.
class ManualFoodSheet extends StatefulWidget {
  final bool quick;
  final String mealType;
  const ManualFoodSheet({super.key, required this.mealType, this.quick = false});

  static Future<void> show(BuildContext context, {required String mealType, bool quick = false}) {
    final cubit = context.read<FoodLogCubit>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(value: cubit, child: ManualFoodSheet(mealType: mealType, quick: quick)),
    );
  }

  @override
  State<ManualFoodSheet> createState() => _ManualFoodSheetState();
}

class _ManualFoodSheetState extends State<ManualFoodSheet> {
  final _name = TextEditingController();
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _qty = TextEditingController(text: '100');
  final _note = TextEditingController();
  final _fiber = TextEditingController();
  final _sugar = TextEditingController();
  final _sodium = TextEditingController();
  late String _mealType = widget.mealType;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _kcal, _protein, _carbs, _fat, _qty, _note, _fiber, _sugar, _sodium]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  void _save() {
    final kcal = double.tryParse(_kcal.text.trim());
    final name = _name.text.trim().isEmpty ? (widget.quick ? 'Quick add' : '') : _name.text.trim();
    if (name.isEmpty || kcal == null || kcal < 0) {
      setState(() => _error = 'Enter a name and valid calories.');
      return;
    }
    context.read<FoodLogCubit>().addManual(
          name: name,
          calories: kcal,
          protein: _num(_protein),
          carbs: _num(_carbs),
          fat: _num(_fat),
          quantity: _num(_qty) > 0 ? _num(_qty) : 100,
          mealType: _mealType,
          note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          fiber: _num(_fiber),
          sugar: _num(_sugar),
          sodium: _num(_sodium),
        );
    Navigator.pop(context);
  }

  Widget _field(TextEditingController c, String label, {bool number = true, int? flex}) => Expanded(
        flex: flex ?? 1,
        child: TextField(
          controller: c,
          keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
          decoration: InputDecoration(labelText: label),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.quick ? 'Quick add calories' : 'Add food manually',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Row(children: [_field(_name, widget.quick ? 'Label (optional)' : 'Food name', number: false)]),
            const SizedBox(height: 10),
            Row(children: [_field(_kcal, 'Calories (kcal)')]),
            if (!widget.quick) ...[
              const SizedBox(height: 10),
              Row(children: [_field(_protein, 'Protein g'), const SizedBox(width: 8), _field(_carbs, 'Carbs g'), const SizedBox(width: 8), _field(_fat, 'Fat g')]),
              const SizedBox(height: 10),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('More nutrients (optional)'),
                  children: [Row(children: [_field(_fiber, 'Fiber g'), const SizedBox(width: 8), _field(_sugar, 'Sugar g'), const SizedBox(width: 8), _field(_sodium, 'Sodium mg')]), const SizedBox(height: 4)],
                ),
              ),
              Row(children: [_field(_qty, 'Quantity (g)', flex: 1), const SizedBox(width: 8), _field(_note, 'Note (optional)', number: false, flex: 2)]),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: [
                for (final m in MealTypes.all)
                  ChoiceChip(
                    avatar: Icon(m.icon, size: 16),
                    label: Text(m.label),
                    selected: _mealType == m.key,
                    onSelected: (_) => setState(() => _mealType = m.key),
                  ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton(onPressed: _save, child: const Text('Add to diary'))),
          ],
        ),
      ),
    );
  }
}
