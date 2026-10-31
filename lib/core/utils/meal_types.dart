import 'package:flutter/material.dart';

class MealType {
  final String key;
  final String label;
  final IconData icon;
  const MealType(this.key, this.label, this.icon);
}

class MealTypes {
  static const all = [
    MealType('breakfast', 'Breakfast', Icons.free_breakfast_rounded),
    MealType('lunch', 'Lunch', Icons.lunch_dining_rounded),
    MealType('dinner', 'Dinner', Icons.dinner_dining_rounded),
    MealType('snack', 'Snacks', Icons.cookie_rounded),
  ];

  static MealType byKey(String key) =>
      all.firstWhere((m) => m.key == key, orElse: () => all.last);

  /// Best guess for the meal being eaten right now.
  static String now() {
    final h = DateTime.now().hour;
    if (h >= 4 && h < 11) return 'breakfast';
    if (h >= 11 && h < 16) return 'lunch';
    if (h >= 17 && h < 22) return 'dinner';
    return 'snack';
  }
}
