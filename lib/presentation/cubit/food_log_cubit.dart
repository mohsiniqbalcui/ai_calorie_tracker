import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/meal_types.dart';
import '../../core/utils/units.dart';
import '../../data/local/tracker_store.dart';
import '../../data/models/food_item.dart';
import '../../data/models/tracker_models.dart';
import '../../data/repositories/food_repository.dart';

class FoodLogState {
  final DateTime selectedDate;
  final List<FoodItem> meals;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double totalFiber;
  final double totalSugar;
  final double totalSodium;

  /// Last 30 days ending today, oldest first.
  final List<DayTotals> history;
  final int streak;
  final int lifetimeMeals;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const FoodLogState({
    required this.selectedDate,
    this.meals = const [],
    this.totalCalories = 0,
    this.totalProtein = 0,
    this.totalCarbs = 0,
    this.totalFat = 0,
    this.totalFiber = 0,
    this.totalSugar = 0,
    this.totalSodium = 0,
    this.history = const [],
    this.streak = 0,
    this.lifetimeMeals = 0,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  bool get isToday => DateFmt.sameDay(selectedDate, DateTime.now());

  /// Calories for the last 7 days, oldest first.
  List<double> get weeklyData =>
      history.skip(history.length > 7 ? history.length - 7 : 0).map((d) => d.calories).toList();

  FoodLogState copyWith({
    DateTime? selectedDate,
    List<FoodItem>? meals,
    double? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    double? totalFiber,
    double? totalSugar,
    double? totalSodium,
    List<DayTotals>? history,
    int? streak,
    int? lifetimeMeals,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return FoodLogState(
      selectedDate: selectedDate ?? this.selectedDate,
      meals: meals ?? this.meals,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      totalFiber: totalFiber ?? this.totalFiber,
      totalSugar: totalSugar ?? this.totalSugar,
      totalSodium: totalSodium ?? this.totalSodium,
      history: history ?? this.history,
      streak: streak ?? this.streak,
      lifetimeMeals: lifetimeMeals ?? this.lifetimeMeals,
      isLoading: isLoading ?? this.isLoading,
      error: clearMessages ? null : (error ?? this.error),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class FoodLogCubit extends Cubit<FoodLogState> {
  final FoodRepository _repository;
  final TrackerStore _store;

  FoodLogCubit(this._repository, this._store)
      : super(FoodLogState(selectedDate: DateFmt.dateOnly(DateTime.now())));

  Future<void> loadDailyLog({DateTime? date}) async {
    final day = DateFmt.dateOnly(date ?? state.selectedDate);
    emit(state.copyWith(selectedDate: day, isLoading: true));
    try {
      final meals = await _repository.getDailyFoodLog(day);
      final totals = _calculateTotals(meals);
      final history = await _loadHistory(30);
      emit(state.copyWith(
        selectedDate: day,
        meals: meals,
        totalCalories: totals.calories,
        totalProtein: totals.protein,
        totalCarbs: totals.carbs,
        totalFat: totals.fat,
        totalFiber: meals.fold<double>(0.0, (s, m) => s + m.fiber),
        totalSugar: meals.fold<double>(0.0, (s, m) => s + m.sugar),
        totalSodium: meals.fold<double>(0.0, (s, m) => s + m.sodium),
        history: history,
        streak: _repository.getStreak(),
        lifetimeMeals: _repository.getLifetimeMealCount(),
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> selectDate(DateTime date) => loadDailyLog(date: date);

  DayTotals _calculateTotals(List<FoodItem> meals, [DateTime? date]) {
    double c = 0, p = 0, cb = 0, f = 0;
    for (final m in meals) {
      c += m.calories;
      p += m.protein;
      cb += m.carbs;
      f += m.fat;
    }
    return DayTotals(date: date ?? state.selectedDate, calories: c, protein: p, carbs: cb, fat: f, meals: meals.length);
  }

  Future<List<DayTotals>> _loadHistory(int days) async {
    final today = DateFmt.dateOnly(DateTime.now());
    final result = <DayTotals>[];
    for (int i = days - 1; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      result.add(_calculateTotals(await _repository.getDailyFoodLog(date), date));
    }
    return result;
  }

  /// A timestamp on the selected day, using the current time of day.
  DateTime _stamp() {
    final now = DateTime.now();
    final d = state.selectedDate;
    return DateTime(d.year, d.month, d.day, now.hour, now.minute, now.second);
  }

  FoodItem _place(FoodItem meal, String? mealType) =>
      meal.copyWith(mealType: mealType ?? MealTypes.now(), timestamp: _stamp());

  Future<void> addMeal(FoodItem meal, {String? successMessage}) async {
    try {
      await _repository.addFoodItem(meal);
      await _store.addRecent(meal);
      await loadDailyLog();
      if (successMessage != null) emit(state.copyWith(successMessage: successMessage));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> addMealFromImage(File image, {String? mealType}) async {
    emit(state.copyWith(isLoading: true));
    final result = await _repository.detectFoodFromImage(image);
    await _handleDetection(result, mealType);
  }

  Future<void> addMealFromText(String foodDescription, {String? mealType}) async {
    emit(state.copyWith(isLoading: true));
    final result = await _repository.detectFoodFromText(foodDescription);
    await _handleDetection(result, mealType);
  }

  Future<void> _handleDetection(Either<String, FoodItem> result, String? mealType) async {
    await result.fold(
      (failure) async => emit(state.copyWith(error: failure, isLoading: false)),
      (detected) async {
        final meal = _place(detected, mealType);
        await addMeal(meal,
            successMessage: 'Added "${meal.name}" to ${MealTypes.byKey(meal.mealType).label.toLowerCase()}.');
      },
    );
  }

  Future<void> addManual({
    required String name,
    required double calories,
    double protein = 0,
    double carbs = 0,
    double fat = 0,
    double quantity = 100,
    String? mealType,
    String? note,
    double fiber = 0,
    double sugar = 0,
    double sodium = 0,
  }) {
    final meal = FoodItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      quantity: quantity,
      timestamp: _stamp(),
      mealType: mealType ?? MealTypes.now(),
      note: note,
      fiber: fiber,
      sugar: sugar,
      sodium: sodium,
    );
    return addMeal(meal, successMessage: 'Added "$name".');
  }

  /// Re-logs a favorite or recent food as a brand new entry.
  Future<void> addFromTemplate(FoodItem template, {String? mealType}) {
    final meal = FoodItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: template.name,
      calories: template.calories,
      protein: template.protein,
      carbs: template.carbs,
      fat: template.fat,
      quantity: template.quantity,
      timestamp: _stamp(),
      mealType: mealType ?? MealTypes.now(),
      note: template.note,
      fiber: template.fiber,
      sugar: template.sugar,
      sodium: template.sodium,
    );
    return addMeal(meal, successMessage: 'Added "${meal.name}".');
  }

  Future<void> copyMealsFrom(DateTime from) async {
    final source = await _repository.getDailyFoodLog(from);
    if (source.isEmpty) {
      emit(state.copyWith(error: 'No meals found on ${DateFmt.short(from)} to copy.'));
      return;
    }
    var offset = 0;
    for (final m in source) {
      final copy = FoodItem(
        id: '${DateTime.now().microsecondsSinceEpoch}_${offset++}',
        name: m.name,
        calories: m.calories,
        protein: m.protein,
        carbs: m.carbs,
        fat: m.fat,
        quantity: m.quantity,
        timestamp: _stamp(),
        mealType: m.mealType,
        note: m.note,
        fiber: m.fiber,
        sugar: m.sugar,
        sodium: m.sodium,
      );
      await _repository.addFoodItem(copy);
    }
    await loadDailyLog();
    emit(state.copyWith(successMessage: 'Copied ${source.length} meals from ${DateFmt.relative(from).toLowerCase()}.'));
  }

  void clearMessages() => emit(state.copyWith(clearMessages: true));

  Future<void> deleteMeal(FoodItem meal) async {
    try {
      await _repository.deleteFoodItem(meal);
      await loadDailyLog();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> restoreMeal(FoodItem meal) async {
    await _repository.addFoodItem(meal);
    await loadDailyLog();
  }

  Future<void> updateMeal(FoodItem meal) async {
    try {
      await _repository.updateFoodItem(meal);
      await loadDailyLog();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
