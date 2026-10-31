import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/utils/meal_types.dart';
import '../cubit/food_log_cubit.dart';
import '../cubit/tracker_cubit.dart';
import '../screens/food_search_screen.dart';
import '../tools/recipes_screen.dart';
import 'manual_food_sheet.dart';
import 'simple_speech_dialog.dart';
import 'text_input_dialog.dart';

/// The one entry point for adding food in either UI mode.
class AddFoodFlow {
  static Future<void> show(BuildContext context, {String? mealType}) async {
    if (!await _ensurePermissions(context) || !context.mounted) return;
    final foodCubit = context.read<FoodLogCubit>();
    final tracker = context.read<TrackerCubit>()..refreshRecents();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MultiBlocProvider(
        providers: [BlocProvider.value(value: foodCubit), BlocProvider.value(value: tracker)],
        child: _AddFoodSheet(parentContext: context, initialMealType: mealType ?? MealTypes.now()),
      ),
    );
  }

  static Future<bool> _ensurePermissions(BuildContext context) async {
    if (kIsWeb) return true;

    bool needsStoragePermission = false;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      needsStoragePermission = androidInfo.version.sdkInt < 33;
    }

    final permissionsToRequest = [
      Permission.camera,
      Permission.microphone,
      if (needsStoragePermission) Permission.storage,
    ];

    final current = <Permission, PermissionStatus>{
      for (final p in permissionsToRequest) p: await p.status,
    };
    if (current.values.every((s) => s.isGranted)) return true;

    final statuses = await permissionsToRequest.request();
    final cameraGranted = statuses[Permission.camera]?.isGranted == true;
    final microphoneGranted = statuses[Permission.microphone]?.isGranted == true;

    if (!cameraGranted || !microphoneGranted) {
      final missing = [if (!cameraGranted) 'Camera', if (!microphoneGranted) 'Microphone'];
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please grant ${missing.join(' and ')} permissions in Settings.'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(label: 'Open Settings', onPressed: openAppSettings),
          ),
        );
      }
      return false;
    }
    return true;
  }
}

class _AddFoodSheet extends StatefulWidget {
  final BuildContext parentContext;
  final String initialMealType;
  const _AddFoodSheet({required this.parentContext, required this.initialMealType});

  @override
  State<_AddFoodSheet> createState() => _AddFoodSheetState();
}

class _AddFoodSheetState extends State<_AddFoodSheet> {
  late String _mealType = widget.initialMealType;

  Future<void> _pick(ImageSource source) async {
    final cubit = context.read<FoodLogCubit>();
    final meal = _mealType;
    Navigator.pop(context);
    final file = await ImagePicker().pickImage(source: source, maxWidth: 600);
    if (file != null) cubit.addMealFromImage(File(file.path), mealType: meal);
  }

  void _describe() {
    final cubit = context.read<FoodLogCubit>();
    final meal = _mealType;
    final parent = widget.parentContext;
    Navigator.pop(context);
    showDialog(
      context: parent,
      builder: (_) => TextInputDialog(
        title: 'Describe your food',
        hintText: 'e.g. "Grilled chicken breast with rice"',
        onSubmitted: (text) => cubit.addMealFromText(text, mealType: meal),
      ),
    );
  }

  void _voice() {
    final cubit = context.read<FoodLogCubit>();
    final meal = _mealType;
    final parent = widget.parentContext;
    Navigator.pop(context);
    showDialog(
      context: parent,
      builder: (_) => SimpleSpeechDialog(onSubmitted: (text) => cubit.addMealFromText(text, mealType: meal)),
    );
  }

  void _search() {
    final meal = _mealType;
    final parent = widget.parentContext;
    Navigator.pop(context);
    Navigator.push(parent, MaterialPageRoute(builder: (_) => FoodSearchScreen(mealType: meal)));
  }

  void _recipes() {
    final parent = widget.parentContext;
    Navigator.pop(context);
    Navigator.push(parent, MaterialPageRoute(builder: (_) => const RecipesScreen()));
  }

  void _manual({required bool quick}) {
    final meal = _mealType;
    final parent = widget.parentContext;
    Navigator.pop(context);
    ManualFoodSheet.show(parent, mealType: meal, quick: quick);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tracker = context.watch<TrackerCubit>().state;

    Widget action(IconData icon, String label, VoidCallback? onTap) => InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Opacity(
            opacity: onTap == null ? 0.4 : 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 6),
                Text(label, style: theme.textTheme.labelMedium, textAlign: TextAlign.center),
              ],
            ),
          ),
        );

    Widget foodChips(String title, List foods) {
      if (foods.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: foods.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = foods[i];
                return ActionChip(
                  label: Text('${f.name} · ${f.calories.round()}'),
                  onPressed: () {
                    context.read<FoodLogCubit>().addFromTemplate(f, mealType: _mealType);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add food', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
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
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 8,
              childAspectRatio: 0.95,
              children: [
                action(Icons.search_rounded, 'Search', _search),
                action(Icons.photo_camera_rounded, 'Camera', () => _pick(ImageSource.camera)),
                action(Icons.photo_library_rounded, 'Gallery', () => _pick(ImageSource.gallery)),
                action(Icons.auto_awesome_rounded, 'Describe', _describe),
                action(Icons.mic_rounded, 'Voice', kIsWeb ? null : _voice),
                action(Icons.edit_note_rounded, 'Manual', () => _manual(quick: false)),
                action(Icons.bolt_rounded, 'Quick add', () => _manual(quick: true)),
                action(Icons.menu_book_rounded, 'Recipes', _recipes),
              ],
            ),
            foodChips('Favorites', tracker.favorites),
            foodChips('Recent', tracker.recents),
          ],
        ),
      ),
    );
  }
}
