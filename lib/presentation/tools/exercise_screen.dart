import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/units.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/tracker_cubit.dart';
import '../widgets/common.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  static const _activities = {
    'Walking': 3.5,
    'Running': 9.8,
    'Cycling': 7.5,
    'Swimming': 8.0,
    'Strength': 5.0,
    'HIIT': 8.0,
    'Yoga': 2.5,
    'Other': 4.0,
  };

  Future<void> _add(BuildContext context) async {
    final tracker = context.read<TrackerCubit>();
    final weight = context.read<SettingsCubit>().state.user?.weight ?? 70;
    var activity = 'Walking';
    final minutes = TextEditingController(text: '30');
    final kcal = TextEditingController();

    double estimate() => (_activities[activity]! *
        weight *
        (int.tryParse(minutes.text) ?? 0) /
        60);

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        if (kcal.text.isEmpty) kcal.text = estimate().round().toString();
        return AlertDialog(
          title: const Text('Log exercise'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final a in _activities.keys)
                      ChoiceChip(
                        label: Text(a),
                        selected: activity == a,
                        onSelected: (_) => setState(() {
                          activity = a;
                          kcal.text = estimate().round().toString();
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: minutes,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Duration (minutes)'),
                  onChanged: (_) =>
                      setState(() => kcal.text = estimate().round().toString()),
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: kcal,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Calories burned (kcal)',
                        helperText:
                            'Estimated from your weight. Edit if you know better.')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final m = int.tryParse(minutes.text) ?? 0;
                final k = double.tryParse(kcal.text) ?? 0;
                if (m <= 0) return;
                tracker.addExercise(activity, m, k);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = context.watch<TrackerCubit>().state;
    return Scaffold(
      appBar: AppBar(title: const Text('Exercise')),
      floatingActionButton: FloatingActionButton.extended(
          heroTag: null,
          onPressed: () => _add(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Log exercise')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${DateFmt.relative(t.date)} · ${DateFmt.short(t.date)}',
              style: theme.textTheme.labelLarge),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: AppCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Colors.deepOrange),
                    const SizedBox(height: 6),
                    Text('${t.caloriesBurned.round()}',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const Text('kcal burned')
                  ]))),
              const SizedBox(width: 12),
              Expanded(
                  child: AppCard(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                    const Icon(Icons.timer_rounded, color: Colors.blue),
                    const SizedBox(height: 6),
                    Text('${t.exerciseMinutes}',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const Text('minutes active')
                  ]))),
            ],
          ),
          const SectionTitle('Activities'),
          if (t.exercises.isEmpty)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No exercise logged for this day.'))),
          for (final e in t.exercises)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
                child: Row(
                  children: [
                    const Icon(Icons.directions_run_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text('${e.name} · ${e.minutes} min',
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700))),
                    Text('${e.calories.round()} kcal',
                        style: theme.textTheme.labelLarge),
                    IconButton(
                        onPressed: () =>
                            context.read<TrackerCubit>().deleteExercise(e.id),
                        icon: const Icon(Icons.delete_outline_rounded)),
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
