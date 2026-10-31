import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/meal_types.dart';
import '../../core/utils/units.dart';
import '../../data/food_database.dart';
import '../widgets/common.dart';
import '../widgets/food_thumb.dart';
import 'food_search_screen.dart';

/// Serving calculator for one food: quantity, unit, meal, date and a live
/// nutrition breakdown. Pops a [ServingResult].
class FoodDetailsScreen extends StatefulWidget {
  final FoodEntry entry;
  final String mealType;
  final bool pick;
  const FoodDetailsScreen(
      {super.key,
      required this.entry,
      required this.mealType,
      this.pick = false});

  @override
  State<FoodDetailsScreen> createState() => _FoodDetailsScreenState();
}

enum _Unit { serving, base, ounce }

class _FoodDetailsScreenState extends State<FoodDetailsScreen> {
  static const _maxGrams = 5000.0;

  late final bool _liquid = widget.entry.category == 'Drinks';
  late final _quantity = TextEditingController(text: '1');
  late String _mealType = widget.mealType;
  late DateTime _date = DateFmt.dateOnly(DateTime.now());
  _Unit _unit = _Unit.serving;

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  String get _baseLabel => _liquid ? 'ml' : 'g';

  double? get _amount {
    final v = double.tryParse(_quantity.text.trim().replaceAll(',', '.'));
    return v != null && v > 0 ? v : null;
  }

  /// Quantity expressed in grams (ml are treated as grams).
  double get _grams {
    final a = _amount ?? 0;
    return switch (_unit) {
      _Unit.serving => a * widget.entry.servingG,
      _Unit.base => a,
      _Unit.ounce => a * 28.3495,
    };
  }

  String? get _error {
    if (_quantity.text.trim().isEmpty) return 'Enter an amount';
    if (_amount == null) return 'Enter a number above 0';
    if (_grams > _maxGrams) return 'That is more than ${_maxGrams.round()} g';
    return null;
  }

  void _setUnit(_Unit u) {
    if (u == _unit) return;
    final g = _grams;
    setState(() {
      _unit = u;
      final converted = switch (u) {
        _Unit.serving => g / widget.entry.servingG,
        _Unit.base => g,
        _Unit.ounce => g / 28.3495,
      };
      _quantity.text = converted > 0 ? _fmt(converted) : '1';
    });
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

  void _step(double delta) {
    final next = (_amount ?? 0) + delta;
    if (next <= 0) return;
    setState(() => _quantity.text = _fmt(next));
  }

  Future<void> _pickDate() async {
    final today = DateFmt.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today.add(const Duration(days: 30)),
    );
    if (picked != null) setState(() => _date = DateFmt.dateOnly(picked));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = widget.entry;
    final valid = _error == null;
    final p = e.portion(valid ? _grams : 0);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    Widget macro(String label, double grams, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Radii.md)),
            child: Column(children: [
              Text('${grams.toStringAsFixed(1)} g',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 2),
              Text(label, style: theme.textTheme.labelMedium),
            ]),
          ),
        );

    Widget factRow(String label, String value, {bool bold = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Expanded(
                child: Text(label,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: bold ? FontWeight.w800 : null))),
            Text(value,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ]),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Food details')),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(20, 4, 20, 24 + bottomInset),
        children: [
          Row(
            children: [
              FoodThumb(
                  imageUrl: e.imageUrl,
                  icon: FoodThumb.iconForCategory(e.category),
                  size: 84),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (e.brand != null) e.brand!,
                        '1 serving = ${e.servingLabel}${e.servingLabel == '100 g' ? '' : ' (${e.servingG.round()} g)'}'
                      ].join(' · '),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Amount',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton.outlined(
                tooltip: 'Less',
                onPressed: () => _step(_unit == _Unit.serving
                    ? -0.5
                    : (_unit == _Unit.ounce ? -1 : -10)),
                icon: const Icon(Icons.remove_rounded),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _quantity,
                  textAlign: TextAlign.center,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    LengthLimitingTextInputFormatter(7)
                  ],
                  onChanged: (_) => setState(() {}),
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                  decoration: InputDecoration(
                      errorText:
                          _quantity.text.isEmpty || valid ? null : _error),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.outlined(
                tooltip: 'More',
                onPressed: () => _step(_unit == _Unit.serving
                    ? 0.5
                    : (_unit == _Unit.ounce ? 1 : 10)),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<_Unit>(
              showSelectedIcon: false,
              segments: [
                const ButtonSegment(
                    value: _Unit.serving, label: Text('Serving')),
                ButtonSegment(value: _Unit.base, label: Text(_baseLabel)),
                const ButtonSegment(value: _Unit.ounce, label: Text('oz')),
              ],
              selected: {_unit},
              onSelectionChanged: (s) => _setUnit(s.first),
            ),
          ),
          if (valid)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('= ${_grams.round()} g',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
          const SizedBox(height: 20),
          AppCard(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${p.kcal.round()}',
                        style: theme.textTheme.displaySmall
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(width: 6),
                    Text('kcal', style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                Row(children: [
                  macro('Protein', p.protein, MacroColors.protein),
                  const SizedBox(width: 8),
                  macro('Carbs', p.carbs, MacroColors.carbs),
                  const SizedBox(width: 8),
                  macro('Fat', p.fat, MacroColors.fat),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nutrition facts',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const Divider(height: 16),
                factRow('Calories', '${p.kcal.round()} kcal', bold: true),
                factRow('Protein', '${p.protein.toStringAsFixed(1)} g'),
                factRow('Carbohydrates', '${p.carbs.toStringAsFixed(1)} g'),
                factRow(
                    '   of which sugars', '${p.sugar.toStringAsFixed(1)} g'),
                factRow('Fat', '${p.fat.toStringAsFixed(1)} g'),
                factRow('Fiber', '${p.fiber.toStringAsFixed(1)} g'),
                factRow('Sodium', '${p.sodium.round()} mg'),
                const Divider(height: 16),
                Text(
                    'Values for ${valid ? _grams.round() : 0} g. Per 100 g: ${e.kcal.round()} kcal.',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (!widget.pick) ...[
            const SizedBox(height: 20),
            Text('Add to',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in MealTypes.all)
                  ChoiceChip(
                    avatar: Icon(m.icon, size: 18),
                    label: Text(m.label),
                    selected: _mealType == m.key,
                    onSelected: (_) => setState(() => _mealType = m.key),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AppCard(
              onTap: _pickDate,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Icon(Icons.event_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(
                        '${DateFmt.relative(_date)}, ${DateFmt.short(_date)}',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700))),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: valid
                ? () => Navigator.pop(
                    context, ServingResult(e, _grams, _mealType, _date))
                : null,
            child: Text(widget.pick
                ? 'Add ingredient'
                : 'Add to diary · ${p.kcal.round()} kcal'),
          ),
        ),
      ),
    );
  }
}
