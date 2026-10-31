import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/units.dart';
import '../../data/local/tracker_store.dart';
import '../../data/models/food_item.dart';
import '../../data/models/tracker_models.dart';

class TrackerState {
  final DateTime date;
  final int waterMl;
  final List<ExerciseEntry> exercises;
  final List<WeightEntry> weights;
  final List<FoodItem> favorites;
  final List<FoodItem> recents;
  final DateTime? fastStart;
  final int fastGoalHours;
  final List<FastRecord> fastHistory;
  final List<Recipe> recipes;
  final List<MeasurementEntry> measurements;

  const TrackerState({
    required this.date,
    this.waterMl = 0,
    this.exercises = const [],
    this.weights = const [],
    this.favorites = const [],
    this.recents = const [],
    this.fastStart,
    this.fastGoalHours = 16,
    this.fastHistory = const [],
    this.recipes = const [],
    this.measurements = const [],
  });

  double get caloriesBurned => exercises.fold(0.0, (s, e) => s + e.calories);
  int get exerciseMinutes => exercises.fold(0, (s, e) => s + e.minutes);
  WeightEntry? get latestWeight => weights.isEmpty ? null : weights.last;
  bool get isFasting => fastStart != null;
  bool isFavorite(String name) =>
      favorites.any((f) => f.name.toLowerCase() == name.toLowerCase());
  int get completedFasts => fastHistory.where((f) => f.completed).length;
}

class TrackerCubit extends Cubit<TrackerState> {
  final TrackerStore _store;

  TrackerCubit(this._store)
      : super(TrackerState(date: DateFmt.dateOnly(DateTime.now()))) {
    load();
  }

  void load({DateTime? date}) {
    final day = DateFmt.dateOnly(date ?? state.date);
    emit(TrackerState(
      date: day,
      waterMl: _store.getWater(day),
      exercises: _store.getExercises(day),
      weights: _store.getWeights(),
      favorites: _store.getFavorites(),
      recents: _store.getRecents(),
      fastStart: _store.getFastStart(),
      fastGoalHours: _store.getFastGoalHours(),
      fastHistory: _store.getFastHistory(),
      recipes: _store.getRecipes(),
      measurements: _store.getMeasurements(),
    ));
  }

  /// Recents change whenever a meal is added elsewhere.
  void refreshRecents() => emit(TrackerState(
        date: state.date,
        waterMl: state.waterMl,
        exercises: state.exercises,
        weights: state.weights,
        favorites: state.favorites,
        recents: _store.getRecents(),
        fastStart: state.fastStart,
        fastGoalHours: state.fastGoalHours,
        fastHistory: state.fastHistory,
        recipes: state.recipes,
        measurements: state.measurements,
      ));

  // ---- Water -------------------------------------------------------------
  Future<void> addWater(int deltaMl) async {
    final next = (state.waterMl + deltaMl).clamp(0, 20000);
    await _store.setWater(state.date, next);
    load();
  }

  // ---- Exercise ----------------------------------------------------------
  Future<void> addExercise(String name, int minutes, double calories) async {
    final list = [
      ...state.exercises,
      ExerciseEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name,
        minutes: minutes,
        calories: calories,
        date: state.date,
      ),
    ];
    await _store.setExercises(state.date, list);
    load();
  }

  Future<void> deleteExercise(String id) async {
    await _store.setExercises(
        state.date, state.exercises.where((e) => e.id != id).toList());
    load();
  }

  // ---- Weight ------------------------------------------------------------
  Future<void> addWeight(double kg, {DateTime? date}) async {
    final day = DateFmt.dateOnly(date ?? DateTime.now());
    final list =
        state.weights.where((w) => !DateFmt.sameDay(w.date, day)).toList()
          ..add(WeightEntry(date: day, kg: kg))
          ..sort((a, b) => a.date.compareTo(b.date));
    await _store.setWeights(list);
    load();
  }

  Future<void> deleteWeight(WeightEntry entry) async {
    await _store
        .setWeights(state.weights.where((w) => w.date != entry.date).toList());
    load();
  }

  // ---- Favorites ---------------------------------------------------------
  Future<void> toggleFavorite(FoodItem meal) async {
    final list = [...state.favorites];
    final i =
        list.indexWhere((f) => f.name.toLowerCase() == meal.name.toLowerCase());
    if (i >= 0) {
      list.removeAt(i);
    } else {
      list.insert(0, meal);
    }
    await _store.setFavorites(list);
    load();
  }

  // ---- Fasting -----------------------------------------------------------
  Future<void> startFast() async {
    await _store.setFastStart(DateTime.now());
    load();
  }

  Future<void> endFast() async {
    final start = state.fastStart;
    if (start == null) return;
    await _store.addFastRecord(FastRecord(
        start: start, end: DateTime.now(), goalHours: state.fastGoalHours));
    await _store.setFastStart(null);
    load();
  }

  Future<void> setFastGoal(int hours) async {
    await _store.setFastGoalHours(hours);
    load();
  }

  // ---- Recipes -----------------------------------------------------------
  Future<void> saveRecipe(Recipe recipe) async {
    final list = [...state.recipes];
    final i = list.indexWhere((r) => r.id == recipe.id);
    if (i >= 0) {
      list[i] = recipe;
    } else {
      list.insert(0, recipe);
    }
    await _store.setRecipes(list);
    load();
  }

  Future<void> deleteRecipe(String id) async {
    await _store.setRecipes(state.recipes.where((r) => r.id != id).toList());
    load();
  }

  // ---- Measurements ------------------------------------------------------
  Future<void> addMeasurement(MeasurementEntry entry) async {
    final day = DateFmt.dateOnly(entry.date);
    final list = state.measurements
        .where((m) => !DateFmt.sameDay(m.date, day))
        .toList()
      ..add(entry);
    list.sort((a, b) => a.date.compareTo(b.date));
    await _store.setMeasurements(list);
    load();
  }

  Future<void> deleteMeasurement(MeasurementEntry entry) async {
    await _store.setMeasurements(
        state.measurements.where((m) => m.date != entry.date).toList());
    load();
  }
}
