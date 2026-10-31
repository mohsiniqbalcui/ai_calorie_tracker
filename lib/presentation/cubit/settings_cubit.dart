import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/calorie_calculator.dart';
import '../../data/local/preference_manager.dart';
import '../../data/models/user_data.dart';

enum UiMode { simple, pro }

class AppSettings {
  final UiMode uiMode;
  final ThemeMode themeMode;
  final bool metric;
  final int waterGoalMl;
  final UserData? user;
  final Set<String> diet;

  const AppSettings({
    this.uiMode = UiMode.simple,
    this.themeMode = ThemeMode.system,
    this.metric = true,
    this.waterGoalMl = 2500,
    this.user,
    this.diet = const {},
  });

  bool get isPro => uiMode == UiMode.pro;
  int get calorieGoal => user?.estimatedCalories ?? 2000;
  int get proteinGoal => user?.proteinGoal ?? 120;
  int get carbsGoal => user?.carbsGoal ?? 250;
  int get fatGoal => user?.fatGoal ?? 65;

  AppSettings copyWith({
    UiMode? uiMode,
    ThemeMode? themeMode,
    bool? metric,
    int? waterGoalMl,
    UserData? user,
    Set<String>? diet,
  }) =>
      AppSettings(
        uiMode: uiMode ?? this.uiMode,
        themeMode: themeMode ?? this.themeMode,
        metric: metric ?? this.metric,
        waterGoalMl: waterGoalMl ?? this.waterGoalMl,
        user: user ?? this.user,
        diet: diet ?? this.diet,
      );
}

class SettingsCubit extends Cubit<AppSettings> {
  final SharedPreferences _prefs;
  late final PreferenceManager _prefManager = PreferenceManager(_prefs);

  SettingsCubit(this._prefs) : super(const AppSettings()) {
    reload();
  }

  void reload() {
    final user = _prefManager.getUserData();
    emit(AppSettings(
      uiMode: _prefs.getString('ui_mode') == 'pro' ? UiMode.pro : UiMode.simple,
      themeMode: switch (_prefs.getString('theme_mode')) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      metric: _prefs.getBool('use_metric') ?? true,
      waterGoalMl: _prefs.getInt('water_goal_ml') ??
          (user == null
              ? 2500
              : CalorieCalculator.calculateWaterIntake(weight: user.weight, activityLevel: user.activityLevel)),
      user: user,
      diet: (_prefs.getStringList('diet_prefs') ?? const []).toSet(),
    ));
  }

  void reloadUser() => emit(state.copyWith(user: _prefManager.getUserData()));

  Future<void> setUiMode(UiMode mode) async {
    emit(state.copyWith(uiMode: mode));
    await _prefs.setString('ui_mode', mode.name);
  }

  Future<void> toggleUiMode() => setUiMode(state.isPro ? UiMode.simple : UiMode.pro);

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    await _prefs.setString('theme_mode', mode.name);
  }

  Future<void> setMetric(bool metric) async {
    emit(state.copyWith(metric: metric));
    await _prefs.setBool('use_metric', metric);
  }

  Future<void> toggleDiet(String key) async {
    final next = {...state.diet};
    if (!next.add(key)) next.remove(key);
    // Vegan food is also vegetarian and dairy-free, so keep the choices consistent.
    emit(state.copyWith(diet: next));
    await _prefs.setStringList('diet_prefs', next.toList());
  }

  Future<void> setWaterGoal(int ml) async {
    emit(state.copyWith(waterGoalMl: ml));
    await _prefs.setInt('water_goal_ml', ml);
  }

  /// Recomputes calories and macros from body stats, like onboarding does.
  Future<void> saveProfile({
    required double weight,
    required double height,
    required int age,
    required String activityLevel,
    required String gender,
    required String goal,
  }) async {
    final maintenance = CalorieCalculator.fallbackEstimateCalories(
      weight: weight,
      height: height,
      age: age,
      activityLevel: activityLevel,
      gender: gender,
    );
    final calories = CalorieCalculator.calculateCaloriesBasedOnGoal(maintenanceCalories: maintenance, goal: goal);
    final macros = CalorieCalculator.calculateMacroGoals(calories: calories, goal: goal);
    final user = UserData(
      weight: weight,
      height: height,
      age: age,
      activityLevel: activityLevel,
      gender: gender,
      goal: goal,
      estimatedCalories: calories,
      proteinGoal: macros['proteinGoal']!,
      fatGoal: macros['fatGoal']!,
      carbsGoal: macros['carbsGoal']!,
    );
    await _prefManager.saveUserData(user);
    await _prefs.setBool('onboarding_complete', true);
    emit(state.copyWith(user: user));
  }

  /// Overrides the daily calorie goal and rescales macros to match.
  Future<void> setCalorieGoal(int calories) async {
    final user = state.user;
    if (user == null) return;
    final macros = CalorieCalculator.calculateMacroGoals(calories: calories, goal: user.goal);
    final updated = user.copyWith(
      estimatedCalories: calories,
      proteinGoal: macros['proteinGoal'],
      fatGoal: macros['fatGoal'],
      carbsGoal: macros['carbsGoal'],
    );
    await _prefManager.saveUserData(updated);
    emit(state.copyWith(user: updated));
  }

  Future<void> setMacroGoals({required int protein, required int carbs, required int fat}) async {
    final user = state.user;
    if (user == null) return;
    final updated = user.copyWith(proteinGoal: protein, carbsGoal: carbs, fatGoal: fat);
    await _prefManager.saveUserData(updated);
    emit(state.copyWith(user: updated));
  }
}
