import 'package:calorie_lens/core/utils/insights.dart';
import 'package:flutter_test/flutter_test.dart';

Insight _daily({double calories = 1000, int meals = 2, int streak = 0, bool today = true, double protein = 80}) =>
    InsightEngine.daily(
      calories: calories,
      calorieGoal: 2000,
      protein: protein,
      proteinGoal: 100,
      waterMl: 2000,
      waterGoalMl: 2000,
      streak: streak,
      mealCount: meals,
      isToday: today,
    );

void main() {
  group('InsightEngine.daily', () {
    test('empty day', () {
      expect(_daily(meals: 0).text, contains('Nothing logged'));
      expect(_daily(meals: 0, today: false).text, contains('No meals were logged'));
    });

    test('over goal warns with the exact overage', () {
      expect(_daily(calories: 2500).text, contains('500 kcal over'));
    });

    test('on target is celebrated', () {
      expect(_daily(calories: 1950).text, contains('Right on target'));
    });

    test('streak message when not on target', () {
      expect(_daily(streak: 5).text, contains('5-day'));
    });

    test('default shows kcal left', () {
      expect(_daily().text, contains('1000 kcal left'));
    });
  });

  test('badges unlock from thresholds', () {
    List<Badge> b({int meals = 0, int streak = 0, int weighIns = 0, int fasts = 0, bool water = false, bool target = false}) =>
        InsightEngine.badges(
            streak: streak, lifetimeMeals: meals, weighIns: weighIns, waterGoalHit: water, onTargetToday: target, fasts: fasts);
    expect(b().length, 12);
    expect(b().where((x) => x.unlocked), isEmpty);
    expect(b(meals: 100).where((x) => x.unlocked).length, 4);
    expect(b(streak: 7).where((x) => x.unlocked).map((x) => x.title), containsAll(['3-Day Streak', 'Week Warrior']));
    expect(b(weighIns: 5).where((x) => x.unlocked).length, 2);
    expect(b(fasts: 1, water: true, target: true).where((x) => x.unlocked).length, 3);
  });
}
