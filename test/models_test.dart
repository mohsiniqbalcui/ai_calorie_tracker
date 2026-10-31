import 'package:calorie_lens/data/models/food_item.dart';
import 'package:calorie_lens/data/models/tracker_models.dart';
import 'package:calorie_lens/data/models/user_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FoodItem JSON round trip keeps every field', () {
    final item = FoodItem(
      id: '1',
      name: 'Oats',
      calories: 150,
      protein: 5,
      carbs: 27,
      fat: 3,
      quantity: 40,
      timestamp: DateTime(2026, 1, 2, 8, 30),
      mealType: 'breakfast',
      note: 'with milk',
      fiber: 4,
      sugar: 1,
      sodium: 2,
    );
    final back = FoodItem.fromJson(item.toJson());
    expect(back.toJson(), item.toJson());
    expect(back.mealType, 'breakfast');
    expect(back.fiber, 4);
  });

  test('FoodItem.fromJson defaults for old saved data', () {
    final back = FoodItem.fromJson({
      'id': '1',
      'name': 'Old',
      'calories': 100,
      'protein': 1,
      'carbs': 1,
      'fat': 1,
      'quantity': 1,
      'timestamp': DateTime(2025).toIso8601String(),
    });
    expect(back.mealType, 'snack');
    expect(back.fiber, 0);
    expect(back.note, isNull);
  });

  test('FoodItem.copyWith changes only given fields', () {
    final a = FoodItem(
        id: '1', name: 'A', calories: 1, protein: 1, carbs: 1, fat: 1, quantity: 1, timestamp: DateTime(2026));
    final b = a.copyWith(name: 'B', calories: 5);
    expect(b.id, '1');
    expect(b.name, 'B');
    expect(b.calories, 5);
    expect(b.protein, 1);
  });

  test('UserData round trip and int-valued weight from JSON', () {
    final u = UserData(
        weight: 70, height: 170, age: 30, activityLevel: 'Light', gender: 'Male', goal: 'Maintain',
        estimatedCalories: 2000, proteinGoal: 100, fatGoal: 60, carbsGoal: 250);
    final back = UserData.fromJson({...u.toJson(), 'weight': 70, 'height': 170});
    expect(back.weight, 70.0);
    expect(back.copyWith(age: 31).age, 31);
    expect(back.copyWith(age: 31).goal, 'Maintain');
  });

  test('tracker models serialize', () {
    final w = WeightEntry(date: DateTime(2026, 1, 1), kg: 70.5);
    expect(WeightEntry.fromJson(w.toJson()).kg, 70.5);

    final e = ExerciseEntry(id: 'e', name: 'Run', minutes: 30, calories: 300, date: DateTime(2026, 1, 1));
    expect(ExerciseEntry.fromJson(e.toJson()).minutes, 30);

    final done = FastRecord(start: DateTime(2026, 1, 1, 20), end: DateTime(2026, 1, 2, 13), goalHours: 16);
    expect(done.completed, isTrue);
    final short = FastRecord(start: DateTime(2026, 1, 1, 20), end: DateTime(2026, 1, 2, 6), goalHours: 16);
    expect(short.completed, isFalse);
    expect(short.duration.inHours, 10);
  });
}
