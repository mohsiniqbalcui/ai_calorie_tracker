import 'package:calorie_lens/data/local/tracker_store.dart';
import 'package:calorie_lens/data/repositories/food_repository.dart';
import 'package:calorie_lens/data/services/food_service.dart';
import 'package:calorie_lens/presentation/cubit/food_log_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<FoodLogCubit> _cubit() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return FoodLogCubit(
      FoodRepository(FoodService(), prefs), TrackerStore(prefs));
}

void main() {
  test('FoodService can be created without an API key', () {
    expect(FoodService.new, returnsNormally);
  });

  test('addManual updates meals and totals immediately', () async {
    final c = await _cubit();
    await c.loadDailyLog();
    expect(c.state.meals, isEmpty);

    await c.addManual(
        name: 'Oats',
        calories: 150,
        protein: 5,
        carbs: 27,
        fat: 3,
        mealType: 'breakfast');
    await c.addManual(
        name: 'Egg',
        calories: 78,
        protein: 6,
        carbs: 1,
        fat: 5,
        mealType: 'breakfast');

    expect(c.state.meals.length, 2);
    expect(c.state.totalCalories, 228);
    expect(c.state.totalProtein, 11);
    expect(c.state.successMessage, isNotNull);
    await c.close();
  });

  test('delete then restore brings the meal back', () async {
    final c = await _cubit();
    await c.loadDailyLog();
    await c.addManual(name: 'Rice', calories: 200);
    final meal = c.state.meals.single;

    await c.deleteMeal(meal);
    expect(c.state.meals, isEmpty);
    expect(c.state.totalCalories, 0);

    await c.restoreMeal(meal);
    expect(c.state.meals.single.id, meal.id);
    await c.close();
  });

  test('update changes values and totals', () async {
    final c = await _cubit();
    await c.loadDailyLog();
    await c.addManual(name: 'Pasta', calories: 300, mealType: 'lunch');
    await c.updateMeal(
        c.state.meals.single.copyWith(calories: 450, mealType: 'dinner'));
    expect(c.state.totalCalories, 450);
    expect(c.state.meals.single.mealType, 'dinner');
    await c.close();
  });

  test('a food added for another date lands on that day only', () async {
    final c = await _cubit();
    await c.loadDailyLog();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await c.addManual(name: 'Soup', calories: 120, date: yesterday);

    expect(c.state.meals, isEmpty, reason: 'today stays empty');
    await c.selectDate(yesterday);
    expect(c.state.meals.single.name, 'Soup');
    expect(c.state.totalCalories, 120);
    await c.close();
  });

  test('history covers 90 days and includes today', () async {
    final c = await _cubit();
    await c.loadDailyLog();
    await c.addManual(name: 'Apple', calories: 95);
    expect(c.state.history.length, 90);
    expect(c.state.history.last.calories, 95);
    expect(c.state.weeklyData.length, 7);
    expect(c.state.lifetimeMeals, 1);
    await c.close();
  });

  test(
      'copy yesterday duplicates meals, and reports when there is nothing to copy',
      () async {
    final c = await _cubit();
    await c.loadDailyLog();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    await c.copyMealsFrom(yesterday);
    expect(c.state.error, contains('No meals found'));

    c.clearMessages();
    await c.addManual(name: 'Toast', calories: 90, date: yesterday);
    await c.copyMealsFrom(yesterday);
    expect(c.state.meals.single.name, 'Toast');
    expect(c.state.successMessage, contains('Copied 1 meals'));
    await c.close();
  });
}
