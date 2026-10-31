import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_item.dart';
import '../models/tracker_models.dart';

/// Persists everything that is not the food log itself: water, weight,
/// exercise, favorites, recents and fasting. Works the same on Android and iOS.
class TrackerStore {
  final SharedPreferences prefs;

  TrackerStore(this.prefs);

  static String dayKey(DateTime d) => d.toIso8601String().split('T')[0];

  // ---- Water -------------------------------------------------------------
  int getWater(DateTime d) => prefs.getInt('water_${dayKey(d)}') ?? 0;

  Future<void> setWater(DateTime d, int ml) =>
      prefs.setInt('water_${dayKey(d)}', ml < 0 ? 0 : ml);

  // ---- Exercise ----------------------------------------------------------
  List<ExerciseEntry> getExercises(DateTime d) {
    final raw = prefs.getString('exercise_${dayKey(d)}');
    if (raw == null) return [];
    return (json.decode(raw) as List)
        .map((e) => ExerciseEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> setExercises(DateTime d, List<ExerciseEntry> list) =>
      prefs.setString('exercise_${dayKey(d)}', json.encode(list.map((e) => e.toJson()).toList()));

  // ---- Weight ------------------------------------------------------------
  List<WeightEntry> getWeights() {
    final raw = prefs.getString('weight_log');
    if (raw == null) return [];
    final list = (json.decode(raw) as List)
        .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  Future<void> setWeights(List<WeightEntry> list) =>
      prefs.setString('weight_log', json.encode(list.map((e) => e.toJson()).toList()));

  // ---- Favorites & recents ----------------------------------------------
  List<FoodItem> _foods(String key) {
    final raw = prefs.getString(key);
    if (raw == null) return [];
    return (json.decode(raw) as List)
        .map((e) => FoodItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveFoods(String key, List<FoodItem> list) =>
      prefs.setString(key, json.encode(list.map((e) => e.toJson()).toList()));

  List<FoodItem> getFavorites() => _foods('favorite_foods');
  Future<void> setFavorites(List<FoodItem> list) => _saveFoods('favorite_foods', list);

  List<FoodItem> getRecents() => _foods('recent_foods');

  Future<void> addRecent(FoodItem item) async {
    final list = getRecents()..removeWhere((f) => f.name.toLowerCase() == item.name.toLowerCase());
    list.insert(0, item);
    await _saveFoods('recent_foods', list.take(12).toList());
  }

  // ---- Fasting -----------------------------------------------------------
  DateTime? getFastStart() {
    final raw = prefs.getString('fast_start');
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setFastStart(DateTime? start) => start == null
      ? prefs.remove('fast_start')
      : prefs.setString('fast_start', start.toIso8601String());

  int getFastGoalHours() => prefs.getInt('fast_goal_hours') ?? 16;
  Future<void> setFastGoalHours(int h) => prefs.setInt('fast_goal_hours', h);

  List<FastRecord> getFastHistory() {
    final raw = prefs.getString('fast_history');
    if (raw == null) return [];
    return (json.decode(raw) as List)
        .map((e) => FastRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addFastRecord(FastRecord r) {
    final list = getFastHistory()..insert(0, r);
    return prefs.setString(
        'fast_history', json.encode(list.take(20).map((e) => e.toJson()).toList()));
  }

  // ---- Recipes -----------------------------------------------------------
  List<Recipe> getRecipes() {
    final raw = prefs.getString('recipes');
    if (raw == null) return [];
    return (json.decode(raw) as List).map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> setRecipes(List<Recipe> list) =>
      prefs.setString('recipes', json.encode(list.map((e) => e.toJson()).toList()));

  // ---- Meal plan ---------------------------------------------------------
  List<PlannedItem> getPlan(DateTime d) {
    final raw = prefs.getString('meal_plan_${dayKey(d)}');
    if (raw == null) return [];
    return (json.decode(raw) as List).map((e) => PlannedItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> setPlan(DateTime d, List<PlannedItem> list) => list.isEmpty
      ? prefs.remove('meal_plan_${dayKey(d)}')
      : prefs.setString('meal_plan_${dayKey(d)}', json.encode(list.map((e) => e.toJson()).toList()));

  // ---- Measurements ------------------------------------------------------
  List<MeasurementEntry> getMeasurements() {
    final raw = prefs.getString('measurements');
    if (raw == null) return [];
    final list = (json.decode(raw) as List).map((e) => MeasurementEntry.fromJson(e as Map<String, dynamic>)).toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  Future<void> setMeasurements(List<MeasurementEntry> list) =>
      prefs.setString('measurements', json.encode(list.map((e) => e.toJson()).toList()));

  // ---- Backup / export ---------------------------------------------------
  static const _transient = ['onboarding_draft_'];

  String exportJson() {
    final data = <String, Object?>{};
    for (final key in prefs.getKeys()) {
      if (_transient.any(key.startsWith)) continue;
      data[key] = prefs.get(key);
    }
    return const JsonEncoder.withIndent('  ').convert({'app': 'calorie_lens', 'version': 1, 'data': data});
  }

  /// Throws [FormatException] when the text is not a valid backup.
  Future<void> importJson(String text) async {
    final decoded = json.decode(text);
    if (decoded is! Map || decoded['app'] != 'calorie_lens' || decoded['data'] is! Map) {
      throw const FormatException('Not a Calorie Lens backup');
    }
    final data = Map<String, dynamic>.from(decoded['data'] as Map);
    for (final entry in data.entries) {
      final v = entry.value;
      if (v is String) {
        await prefs.setString(entry.key, v);
      } else if (v is bool) {
        await prefs.setBool(entry.key, v);
      } else if (v is int) {
        await prefs.setInt(entry.key, v);
      } else if (v is double) {
        await prefs.setDouble(entry.key, v);
      } else if (v is List) {
        await prefs.setStringList(entry.key, v.map((e) => e.toString()).toList());
      }
    }
  }

  String exportCsv() {
    String q(String v) => '"${v.replaceAll('"', '""')}"';
    final rows = <String>['date,time,meal,name,calories,protein_g,carbs_g,fat_g,fiber_g,sugar_g,sodium_mg,quantity_g,note'];
    final keys = prefs.getKeys().where((k) => k.startsWith('food_log_')).toList()..sort();
    for (final key in keys) {
      final raw = prefs.getString(key);
      if (raw == null) continue;
      for (final e in json.decode(raw) as List) {
        final f = FoodItem.fromJson(e as Map<String, dynamic>);
        final t = f.timestamp;
        final time = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
        rows.add([
          dayKey(t),
          time,
          f.mealType,
          q(f.name),
          f.calories.toStringAsFixed(1),
          f.protein.toStringAsFixed(1),
          f.carbs.toStringAsFixed(1),
          f.fat.toStringAsFixed(1),
          f.fiber.toStringAsFixed(1),
          f.sugar.toStringAsFixed(1),
          f.sodium.toStringAsFixed(0),
          f.quantity.toStringAsFixed(1),
          q(f.note ?? ''),
        ].join(','));
      }
    }
    return rows.join('\n');
  }

  Future<void> resetAll() => prefs.clear();
}
