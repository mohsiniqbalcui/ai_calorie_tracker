import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/units.dart';
import '../../data/local/tracker_store.dart';
import '../cubit/food_log_cubit.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/tracker_cubit.dart';
import '../pro/pro_tools.dart' show editWaterGoal;
import '../tools/body_metrics_screen.dart';
import '../tools/exercise_screen.dart';
import '../tools/fasting_screen.dart';
import '../tools/weight_screen.dart';
import '../../data/food_database.dart';
import '../tools/meal_plan_screen.dart';
import '../tools/measurements_screen.dart';
import '../tools/recipes_screen.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _open(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  Future<void> _editProfile(BuildContext context) async {
    final cubit = context.read<SettingsCubit>();
    final s = cubit.state;
    final user = s.user;
    final weight = TextEditingController(text: user == null ? '' : (s.metric ? user.weight : Units.kgToLb(user.weight)).toStringAsFixed(1));
    final height = TextEditingController(text: user == null ? '' : user.height.toStringAsFixed(0));
    final age = TextEditingController(text: user?.age.toString() ?? '');
    var activity = user?.activityLevel ?? 'Moderate';
    var gender = user?.gender ?? 'Male';
    var goal = user?.goal ?? 'Maintenance';
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        Widget drop(String label, String value, List<String> items, ValueChanged<String> onChanged) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: DropdownButtonFormField<String>(
                initialValue: value,
                decoration: InputDecoration(labelText: label),
                items: [for (final i in items) DropdownMenuItem(value: i, child: Text(i))],
                onChanged: (v) => setState(() => onChanged(v!)),
              ),
            );
        return AlertDialog(
          title: const Text('Edit profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Weight (${Units.weightUnit(s.metric)})')),
                const SizedBox(height: 10),
                TextField(controller: height, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Height (cm)')),
                const SizedBox(height: 10),
                TextField(controller: age, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age')),
                drop('Activity level', activity, const ['Sedentary', 'Light', 'Moderate', 'Active', 'Very Active'], (v) => activity = v),
                drop('Gender', gender, const ['Male', 'Female', 'Other'], (v) => gender = v),
                drop('Goal', goal, const ['Weight Loss', 'Maintenance', 'Muscle Gain'], (v) => goal = v),
                if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final w = double.tryParse(weight.text.trim());
                final h = double.tryParse(height.text.trim());
                final a = int.tryParse(age.text.trim());
                if (w == null || h == null || a == null || w <= 0 || h <= 0 || a <= 0) {
                  setState(() => error = 'Please enter valid numbers.');
                  return;
                }
                cubit.saveProfile(weight: s.metric ? w : Units.lbToKg(w), height: h, age: a, activityLevel: activity, gender: gender, goal: goal);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _editCalories(BuildContext context) async {
    final cubit = context.read<SettingsCubit>();
    final controller = TextEditingController(text: cubit.state.calorieGoal.toString());
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Daily calorie goal'),
        content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Calories (kcal)', helperText: 'Macro goals are rescaled to match.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(controller.text);
              if (v == null || v < 800 || v > 8000) return;
              Navigator.pop(ctx, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (value != null) cubit.setCalorieGoal(value);
  }

  Future<void> _editMacros(BuildContext context) async {
    final cubit = context.read<SettingsCubit>();
    final s = cubit.state;
    final p = TextEditingController(text: '${s.proteinGoal}');
    final c = TextEditingController(text: '${s.carbsGoal}');
    final f = TextEditingController(text: '${s.fatGoal}');
    Widget field(TextEditingController ctl, String label) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(controller: ctl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: label)),
        );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Macro goals'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [field(p, 'Protein (g)'), field(c, 'Carbs (g)'), field(f, 'Fat (g)')]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) {
      cubit.setMacroGoals(
        protein: int.tryParse(p.text) ?? s.proteinGoal,
        carbs: int.tryParse(c.text) ?? s.carbsGoal,
        fat: int.tryParse(f.text) ?? s.fatGoal,
      );
    }
  }

  void _reloadAll(BuildContext context) {
    context.read<SettingsCubit>().reload();
    context.read<FoodLogCubit>().loadDailyLog();
    context.read<TrackerCubit>().load();
  }

  Future<void> _copy(BuildContext context, String text, String what) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$what copied to clipboard')));
    }
  }

  Future<void> _import(BuildContext context, TrackerStore store) async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore backup'),
        content: TextField(controller: controller, maxLines: 8, decoration: const InputDecoration(hintText: 'Paste backup JSON here')),
        actions: [
          TextButton(
            onPressed: () async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);
              controller.text = data?.text ?? '';
            },
            child: const Text('Paste'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Restore')),
        ],
      ),
    );
    if (text == null || text.trim().isEmpty) return;
    try {
      await store.importJson(text);
      if (context.mounted) _reloadAll(context);
      messenger.showSnackBar(const SnackBar(content: Text('Backup restored')));
    } on FormatException {
      messenger.showSnackBar(const SnackBar(content: Text('That is not a valid Calorie Lens backup')));
    }
  }

  Future<void> _reset(BuildContext context, TrackerStore store) async {
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erase all data?'),
        content: const Text('This deletes your profile, meals, water, weight and settings from this device. It cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Erase'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await store.resetAll();
    if (!context.mounted) return;
    _reloadAll(context);
    navigator.pushNamedAndRemoveUntil('/onboarding', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = context.watch<SettingsCubit>().state;
    final cubit = context.read<SettingsCubit>();
    final store = context.read<TrackerStore>();
    final user = s.user;

    Widget group(String title, List<Widget> children) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(title),
            AppCard(padding: EdgeInsets.zero, child: Column(children: children)),
            const SizedBox(height: 8),
          ],
        );

    Widget tile(IconData icon, String title, {String? subtitle, VoidCallback? onTap, Widget? trailing}) => ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle),
          trailing: trailing ?? (onTap == null ? null : const Icon(Icons.chevron_right_rounded)),
          onTap: onTap,
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), automaticallyImplyLeading: false, actions: const [ModeToggleButton()]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          group('Interface', [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<UiMode>(
                    segments: const [
                      ButtonSegment(value: UiMode.simple, icon: Icon(Icons.spa_rounded), label: Text('Simple')),
                      ButtonSegment(value: UiMode.pro, icon: Icon(Icons.insights_rounded), label: Text('Pro')),
                    ],
                    selected: {s.uiMode},
                    onSelectionChanged: (v) => cubit.setUiMode(v.first),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.isPro ? 'Pro: dashboard, diary, insights, charts and a full toolbox.' : 'Simple: one clean screen to log food, water and weight.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_rounded), label: Text('Auto')),
                      ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_rounded), label: Text('Light')),
                      ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_rounded), label: Text('Dark')),
                    ],
                    selected: {s.themeMode},
                    onSelectionChanged: (v) => cubit.setThemeMode(v.first),
                  ),
                ],
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.straighten_rounded),
              title: const Text('Metric units'),
              subtitle: Text(s.metric ? 'kg, cm, ml' : 'lb, ft, fl oz'),
              value: s.metric,
              onChanged: cubit.setMetric,
            ),
          ]),
          group('Profile and goals', [
            tile(Icons.person_rounded, 'Edit profile', subtitle: user == null ? 'Not set up yet' : '${Units.weight(user.weight, s.metric)} · ${Units.height(user.height, s.metric)} · ${user.age} yrs · ${user.goal}', onTap: () => _editProfile(context)),
            tile(Icons.local_fire_department_rounded, 'Calorie goal', subtitle: '${s.calorieGoal} kcal per day', onTap: user == null ? null : () => _editCalories(context)),
            tile(Icons.pie_chart_rounded, 'Macro goals', subtitle: 'P ${s.proteinGoal} g · C ${s.carbsGoal} g · F ${s.fatGoal} g', onTap: user == null ? null : () => _editMacros(context)),
            tile(Icons.water_drop_rounded, 'Water goal', subtitle: Units.volume(s.waterGoalMl, s.metric), onTap: () => editWaterGoal(context)),
            tile(Icons.restart_alt_rounded, 'Redo onboarding', onTap: () => Navigator.pushReplacementNamed(context, '/onboarding')),
          ]),
          group('Diet preferences', [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final d in FoodDatabase.diets)
                        FilterChip(label: Text(d.label), selected: s.diet.contains(d.key), onSelected: (_) => cubit.toggleDiet(d.key)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Food search and meal plans only show foods that match.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ]),
          group('Health tools', [
            tile(Icons.menu_book_rounded, 'My recipes', onTap: () => _open(context, const RecipesScreen())),
            tile(Icons.monitor_weight_rounded, 'Weight tracker', onTap: () => _open(context, const WeightScreen())),
            tile(Icons.monitor_heart_rounded, 'BMI and body metrics', onTap: () => _open(context, const BodyMetricsScreen())),
            if (s.isPro) ...[
              tile(Icons.event_note_rounded, 'Meal planner', onTap: () => _open(context, const MealPlanScreen())),
              tile(Icons.straighten_rounded, 'Body measurements', onTap: () => _open(context, const MeasurementsScreen())),
              tile(Icons.directions_run_rounded, 'Exercise log', onTap: () => _open(context, const ExerciseScreen())),
              tile(Icons.timer_rounded, 'Fasting timer', onTap: () => _open(context, const FastingScreen())),
            ],
          ]),
          group('Your data', [
            tile(Icons.data_object_rounded, 'Copy backup (JSON)', subtitle: 'Everything, ready to restore', onTap: () => _copy(context, store.exportJson(), 'Backup')),
            tile(Icons.table_chart_rounded, 'Copy meals as CSV', subtitle: 'Open in Excel or Sheets', onTap: () => _copy(context, store.exportCsv(), 'CSV')),
            tile(Icons.settings_backup_restore_rounded, 'Restore from backup', onTap: () => _import(context, store)),
            ListTile(
              leading: Icon(Icons.delete_forever_rounded, color: theme.colorScheme.error),
              title: Text('Erase all data', style: TextStyle(color: theme.colorScheme.error)),
              onTap: () => _reset(context, store),
            ),
          ]),
          const SizedBox(height: 8),
          Center(child: Text('Calorie Lens · AI calorie tracker', style: theme.textTheme.labelSmall)),
        ],
      ),
    );
  }
}
