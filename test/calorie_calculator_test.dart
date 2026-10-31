import 'package:calorie_lens/core/utils/calorie_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalorieCalculator', () {
    test('male estimate uses Harris-Benedict and activity multiplier', () {
      final kcal = CalorieCalculator.fallbackEstimateCalories(
          weight: 80,
          height: 180,
          age: 30,
          activityLevel: 'Sedentary',
          gender: 'Male');
      final bmr = 88.362 + 13.397 * 80 + 4.799 * 180 - 5.677 * 30;
      expect(kcal, (bmr * 1.2).toInt());
    });

    test('other gender is the average of male and female', () {
      int est(String g) => CalorieCalculator.fallbackEstimateCalories(
          weight: 70,
          height: 170,
          age: 25,
          activityLevel: 'Moderate',
          gender: g);
      expect(est('Other'), closeTo((est('Male') + est('Female')) / 2, 1));
    });

    test('unknown activity level falls back to sedentary', () {
      int est(String a) => CalorieCalculator.fallbackEstimateCalories(
          weight: 70, height: 170, age: 25, activityLevel: a, gender: 'Female');
      expect(est('???'), est('Sedentary'));
      expect(est('Very Active'), greaterThan(est('Active')));
    });

    test('goal adjusts calories', () {
      expect(
          CalorieCalculator.calculateCaloriesBasedOnGoal(
              maintenanceCalories: 2000, goal: 'Weight Loss'),
          1600);
      expect(
          CalorieCalculator.calculateCaloriesBasedOnGoal(
              maintenanceCalories: 2000, goal: 'Muscle Gain'),
          2300);
      expect(
          CalorieCalculator.calculateCaloriesBasedOnGoal(
              maintenanceCalories: 2000, goal: 'Maintain'),
          2000);
    });

    test('macro goals add back up to roughly the calorie target', () {
      for (final goal in ['Weight Loss', 'Muscle Gain', 'Maintain']) {
        final m =
            CalorieCalculator.calculateMacroGoals(calories: 2000, goal: goal);
        final total =
            m['proteinGoal']! * 4 + m['carbsGoal']! * 4 + m['fatGoal']! * 9;
        expect(total, closeTo(2000, 20), reason: goal);
      }
      expect(
          CalorieCalculator.calculateMacroGoals(
              calories: 2000, goal: 'Weight Loss')['proteinGoal'],
          150);
    });

    test('water and protein needs scale with weight and activity', () {
      expect(
          CalorieCalculator.calculateWaterIntake(
              weight: 60, activityLevel: 'Sedentary'),
          1980);
      expect(
          CalorieCalculator.calculateWaterIntake(
              weight: 60, activityLevel: 'Very Active'),
          2772);
      expect(
          CalorieCalculator.calculateProteinNeeds(
              weight: 70, activityLevel: 'Light', goal: 'Maintain'),
          126);
      expect(
          CalorieCalculator.calculateProteinNeeds(
              weight: 70, activityLevel: 'Active', goal: 'Muscle Gain'),
          168);
    });
  });
}
