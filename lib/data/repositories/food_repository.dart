import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_item.dart';
import '../services/food_service.dart';

class FoodRepository {
  final FoodService _foodService;
  final SharedPreferences _prefs;

  FoodRepository(this._foodService, this._prefs);

  Future<List<FoodItem>> getDailyFoodLog(DateTime date) async {
    final String key = 'food_log_${date.toIso8601String().split('T')[0]}';
    final String? storedData = _prefs.getString(key);

    if (storedData != null) {
      final List<dynamic> jsonList = json.decode(storedData);
      return jsonList.map((json) => FoodItem.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> addFoodItem(FoodItem item) async {
    final String key =
        'food_log_${item.timestamp.toIso8601String().split('T')[0]}';
    List<FoodItem> currentLog = await getDailyFoodLog(item.timestamp);
    currentLog.add(item);

    await _prefs.setString(
      key,
      json.encode(currentLog.map((item) => item.toJson()).toList()),
    );
  }

  Future<Either<String, FoodItem>> detectFoodFromImage(File image) async {
    return await _foodService.detectFoodAndCalories(image);
  }

  Future<Either<String, FoodItem>> detectFoodFromText(
      String foodDescription) async {
    debugPrint('=== REPOSITORY DETECTFOODFROMTEXT CALLED ===');
    debugPrint('Food description: "$foodDescription"');
    debugPrint('Calling food service...');
    final result = await _foodService.detectFoodFromText(foodDescription);
    debugPrint('Food service result received');
    return result;
  }

  Future<void> deleteFoodItem(FoodItem item) async {
    final String key =
        'food_log_${item.timestamp.toIso8601String().split('T')[0]}';
    List<FoodItem> currentLog = await getDailyFoodLog(item.timestamp);
    currentLog.removeWhere((existingItem) => existingItem.id == item.id);

    await _prefs.setString(
      key,
      json.encode(currentLog.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> updateFoodItem(FoodItem item) async {
    final String key =
        'food_log_${item.timestamp.toIso8601String().split('T')[0]}';
    List<FoodItem> currentLog = await getDailyFoodLog(item.timestamp);
    final index =
        currentLog.indexWhere((existingItem) => existingItem.id == item.id);

    if (index != -1) {
      currentLog[index] = item;
      await _prefs.setString(
        key,
        json.encode(currentLog.map((item) => item.toJson()).toList()),
      );
    }
  }

  /// Days that have at least one meal, and the total meal count ever logged.
  ({Set<String> days, int meals}) _logSummary() {
    final days = <String>{};
    var meals = 0;
    for (final key
        in _prefs.getKeys().where((k) => k.startsWith('food_log_'))) {
      final raw = _prefs.getString(key);
      if (raw == null) continue;
      final count = (json.decode(raw) as List).length;
      if (count > 0) {
        days.add(key.substring('food_log_'.length));
        meals += count;
      }
    }
    return (days: days, meals: meals);
  }

  int getLifetimeMealCount() => _logSummary().meals;

  /// Consecutive logged days ending today (or yesterday if today is empty).
  int getStreak() {
    final days = _logSummary().days;
    String keyFor(DateTime d) => d.toIso8601String().split('T')[0];
    var day = DateTime.now();
    if (!days.contains(keyFor(day))) {
      day = day.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (days.contains(keyFor(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
