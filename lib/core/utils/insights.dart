import 'package:flutter/material.dart';

class Insight {
  final IconData icon;
  final String text;
  final Color? color;
  const Insight(this.icon, this.text, [this.color]);
}

class Badge {
  final String title;
  final String description;
  final IconData icon;
  final bool unlocked;
  const Badge(this.title, this.description, this.icon, this.unlocked);
}

class InsightEngine {
  static Insight daily({
    required double calories,
    required int calorieGoal,
    required double protein,
    required int proteinGoal,
    required int waterMl,
    required int waterGoalMl,
    required int streak,
    required int mealCount,
    required bool isToday,
  }) {
    final hour = DateTime.now().hour;
    if (mealCount == 0) {
      return Insight(
        Icons.restaurant_rounded,
        isToday ? 'Nothing logged yet. Snap a photo or describe your meal to start the day.' : 'No meals were logged on this day.',
      );
    }
    if (calories > calorieGoal * 1.1) {
      return Insight(Icons.warning_amber_rounded,
          'You are ${(calories - calorieGoal).round()} kcal over your goal. A light walk can help balance it out.',
          Colors.orange);
    }
    if (isToday && waterMl < waterGoalMl * 0.4 && hour >= 14) {
      return const Insight(Icons.water_drop_rounded, 'Hydration is behind schedule. Have a glass of water now.', Colors.blue);
    }
    if (proteinGoal > 0 && protein < proteinGoal * 0.5 && hour >= 16 && isToday) {
      return const Insight(Icons.egg_alt_rounded, 'Protein is under half of your goal. Consider eggs, yogurt, or chicken at dinner.');
    }
    if (calories >= calorieGoal * 0.9 && calories <= calorieGoal * 1.1) {
      return const Insight(Icons.emoji_events_rounded, 'Right on target. Great calorie control today!', Colors.green);
    }
    if (streak >= 3) {
      return Insight(Icons.local_fire_department_rounded, '$streak-day logging streak. Consistency is the real secret.', Colors.deepOrange);
    }
    final left = (calorieGoal - calories).round();
    return Insight(Icons.trending_flat_rounded, '$left kcal left for the day. Keep going!');
  }

  static List<Badge> badges({
    required int streak,
    required int lifetimeMeals,
    required int weighIns,
    required bool waterGoalHit,
    required bool onTargetToday,
    required int fasts,
  }) =>
      [
        Badge('First Bite', 'Log your first meal', Icons.restaurant_rounded, lifetimeMeals >= 1),
        Badge('Getting Going', 'Log 10 meals', Icons.looks_one_rounded, lifetimeMeals >= 10),
        Badge('Dedicated', 'Log 50 meals', Icons.workspace_premium_rounded, lifetimeMeals >= 50),
        Badge('Centurion', 'Log 100 meals', Icons.military_tech_rounded, lifetimeMeals >= 100),
        Badge('3-Day Streak', 'Log 3 days in a row', Icons.local_fire_department_rounded, streak >= 3),
        Badge('Week Warrior', 'Log 7 days in a row', Icons.whatshot_rounded, streak >= 7),
        Badge('Monthly Master', 'Log 30 days in a row', Icons.calendar_month_rounded, streak >= 30),
        Badge('Hydrated', 'Hit your water goal', Icons.water_drop_rounded, waterGoalHit),
        Badge('Weigh-in', 'Log your weight', Icons.monitor_weight_rounded, weighIns >= 1),
        Badge('Trend Tracker', 'Log 5 weigh-ins', Icons.show_chart_rounded, weighIns >= 5),
        Badge('On Target', 'Finish within 10% of goal', Icons.track_changes_rounded, onTargetToday),
        Badge('Faster', 'Complete a fast', Icons.timer_rounded, fasts >= 1),
      ];
}
