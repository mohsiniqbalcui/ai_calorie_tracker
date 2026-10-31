import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/units.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/tracker_cubit.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';

class WeightScreen extends StatelessWidget {
  const WeightScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final settings = context.read<SettingsCubit>().state;
    final tracker = context.read<TrackerCubit>();
    final controller = TextEditingController();
    final kg = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log weight'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'Weight (${Units.weightUnit(settings.metric)})'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim());
              if (v == null || v <= 0) return;
              Navigator.pop(ctx, settings.metric ? v : Units.lbToKg(v));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (kg != null) tracker.addWeight(kg);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weights = context.watch<TrackerCubit>().state.weights;
    final settings = context.watch<SettingsCubit>().state;
    final metric = settings.metric;
    final latest = weights.isEmpty ? settings.user?.weight : weights.last.kg;
    final change = weights.length >= 2 ? weights.last.kg - weights.first.kg : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Weight tracker')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _add(context), icon: const Icon(Icons.add_rounded), label: const Text('Log weight')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Current', style: theme.textTheme.labelMedium),
                      Text(latest == null ? '—' : Units.weight(latest, metric), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Change', style: theme.textTheme.labelMedium),
                      Text(
                        '${change > 0 ? '+' : ''}${(metric ? change : Units.kgToLb(change)).toStringAsFixed(1)} ${Units.weightUnit(metric)}',
                        style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: change == 0 ? null : (change < 0 ? Colors.green : Colors.orange)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(child: WeightChart(entries: weights, metric: metric)),
          const SectionTitle('History'),
          if (weights.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No weigh-ins yet.'))),
          for (final w in weights.reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
                child: Row(
                  children: [
                    Expanded(child: Text(Units.weight(w.kg, metric), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700))),
                    Text(DateFmt.short(w.date), style: theme.textTheme.labelMedium),
                    IconButton(onPressed: () => context.read<TrackerCubit>().deleteWeight(w), icon: const Icon(Icons.delete_outline_rounded)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
