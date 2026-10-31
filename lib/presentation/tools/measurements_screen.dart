import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/units.dart';
import '../../data/models/tracker_models.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/tracker_cubit.dart';
import '../widgets/common.dart';

/// Body fat and tape measurements over time.
class MeasurementsScreen extends StatelessWidget {
  const MeasurementsScreen({super.key});

  Future<void> _add(BuildContext context) async {
    final metric = context.read<SettingsCubit>().state.metric;
    final tracker = context.read<TrackerCubit>();
    final labels = ['Body fat (%)', 'Waist', 'Chest', 'Hips', 'Arm', 'Thigh'];
    final controllers = [for (final _ in labels) TextEditingController()];
    final unit = metric ? 'cm' : 'in';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log measurements'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < labels.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: controllers[i],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: i == 0 ? labels[i] : '${labels[i]} ($unit)'),
                  ),
                ),
              const Text('Fill in only what you measured.', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (saved != true) return;
    double? v(int i, {bool length = true}) {
      final x = double.tryParse(controllers[i].text.trim());
      if (x == null || x <= 0) return null;
      return length && !metric ? x * 2.54 : x;
    }

    final entry = MeasurementEntry(
      date: DateTime.now(),
      bodyFat: v(0, length: false),
      waist: v(1),
      chest: v(2),
      hips: v(3),
      arm: v(4),
      thigh: v(5),
    );
    if ([entry.bodyFat, entry.waist, entry.chest, entry.hips, entry.arm, entry.thigh].every((e) => e == null)) return;
    tracker.addMeasurement(entry);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metric = context.watch<SettingsCubit>().state.metric;
    final list = context.watch<TrackerCubit>().state.measurements;

    String len(double? cm) => cm == null ? '—' : (metric ? '${cm.toStringAsFixed(1)} cm' : '${(cm / 2.54).toStringAsFixed(1)} in');

    // Latest recorded value of each field, with the change from the one before.
    Widget field(String label, double? Function(MeasurementEntry) get, {bool percent = false}) {
      final values = list.map(get).whereType<double>().toList();
      final latest = values.isEmpty ? null : values.last;
      final delta = values.length >= 2 ? values.last - values[values.length - 2] : null;
      return AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Text(latest == null ? '—' : (percent ? '${latest.toStringAsFixed(1)}%' : len(latest)), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            if (delta != null)
              Text(
                '${delta > 0 ? '+' : ''}${(percent || metric ? delta : delta / 2.54).toStringAsFixed(1)}${percent ? '%' : (metric ? ' cm' : ' in')}',
                style: theme.textTheme.labelSmall?.copyWith(color: delta <= 0 ? Colors.green : Colors.orange, fontWeight: FontWeight.w700),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Body measurements')),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _add(context), icon: const Icon(Icons.add_rounded), label: const Text('Log')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.25,
            children: [
              field('Body fat', (m) => m.bodyFat, percent: true),
              field('Waist', (m) => m.waist),
              field('Chest', (m) => m.chest),
              field('Hips', (m) => m.hips),
              field('Arm', (m) => m.arm),
              field('Thigh', (m) => m.thigh),
            ],
          ),
          const SectionTitle('History'),
          if (list.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No measurements yet.'))),
          for (final m in list.reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFmt.short(m.date), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          Text([
                            if (m.bodyFat != null) 'BF ${m.bodyFat!.toStringAsFixed(1)}%',
                            if (m.waist != null) 'Waist ${len(m.waist)}',
                            if (m.chest != null) 'Chest ${len(m.chest)}',
                            if (m.hips != null) 'Hips ${len(m.hips)}',
                            if (m.arm != null) 'Arm ${len(m.arm)}',
                            if (m.thigh != null) 'Thigh ${len(m.thigh)}',
                          ].join('  ·  '), style: theme.textTheme.labelSmall),
                        ],
                      ),
                    ),
                    IconButton(onPressed: () => context.read<TrackerCubit>().deleteMeasurement(m), icon: const Icon(Icons.delete_outline_rounded)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
