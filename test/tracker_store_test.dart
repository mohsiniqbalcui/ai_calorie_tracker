import 'dart:convert';

import 'package:calorie_lens/data/local/tracker_store.dart';
import 'package:calorie_lens/data/models/food_item.dart';
import 'package:calorie_lens/data/models/tracker_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

FoodItem _food(String name, {String note = ''}) => FoodItem(
    id: name, name: name, calories: 100, protein: 5, carbs: 10, fat: 2, quantity: 50,
    timestamp: DateTime(2026, 2, 3, 9, 5), mealType: 'breakfast', note: note);

Future<TrackerStore> _store([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return TrackerStore(await SharedPreferences.getInstance());
}

void main() {
  final day = DateTime(2026, 2, 3);

  test('water never goes negative and is stored per day', () async {
    final s = await _store();
    expect(s.getWater(day), 0);
    await s.setWater(day, 750);
    await s.setWater(day.add(const Duration(days: 1)), -5);
    expect(s.getWater(day), 750);
    expect(s.getWater(day.add(const Duration(days: 1))), 0);
  });

  test('weights come back sorted by date', () async {
    final s = await _store();
    await s.setWeights([
      WeightEntry(date: DateTime(2026, 2, 5), kg: 71),
      WeightEntry(date: DateTime(2026, 2, 1), kg: 72),
    ]);
    expect(s.getWeights().map((w) => w.kg), [72, 71]);
  });

  test('recents are de-duplicated, newest first, capped at 12', () async {
    final s = await _store();
    for (var i = 0; i < 15; i++) {
      await s.addRecent(_food('Food $i'));
    }
    await s.addRecent(_food('food 10'));
    final r = s.getRecents();
    expect(r.length, 12);
    expect(r.first.name, 'food 10');
    expect(r.where((f) => f.name.toLowerCase() == 'food 10').length, 1);
  });

  test('fasting state and history', () async {
    final s = await _store();
    expect(s.getFastStart(), isNull);
    expect(s.getFastGoalHours(), 16);
    final start = DateTime(2026, 2, 3, 20);
    await s.setFastStart(start);
    expect(s.getFastStart(), start);
    await s.setFastStart(null);
    expect(s.getFastStart(), isNull);
    for (var i = 0; i < 25; i++) {
      await s.addFastRecord(FastRecord(start: start, end: start.add(Duration(hours: i)), goalHours: 16));
    }
    expect(s.getFastHistory().length, 20);
  });

  test('meal plan clears when emptied', () async {
    final s = await _store();
    expect(s.getPlan(day), isEmpty);
    await s.setPlan(day, []);
    expect(s.getPlan(day), isEmpty);
  });

  test('export then import restores data and skips onboarding drafts', () async {
    final a = await _store({'water_2026-02-03': 500, 'onboarding_draft_weight': '80', 'fast_goal_hours': 18});
    final text = a.exportJson();
    expect(text, isNot(contains('onboarding_draft_')));

    final b = await _store();
    await b.importJson(text);
    expect(b.getWater(day), 500);
    expect(b.getFastGoalHours(), 18);
  });

  test('import rejects foreign or malformed files', () async {
    final s = await _store();
    expect(() => s.importJson('{"app":"other","data":{}}'), throwsFormatException);
    expect(() => s.importJson('{"app":"calorie_lens","data":5}'), throwsFormatException);
    expect(() => s.importJson('not json'), throwsFormatException);
  });

  test('csv export escapes quotes and lists every logged item', () async {
    final s = await _store();
    final item = _food('Mac "n" cheese', note: 'say "hi"');
    await s.prefs.setString('food_log_2026-02-03', '[${_jsonOf(item)}]');
    final lines = s.exportCsv().split('\n');
    expect(lines.length, 2);
    expect(lines[0], startsWith('date,time,meal,name'));
    expect(lines[1], contains('"Mac ""n"" cheese"'));
    expect(lines[1], contains('"say ""hi"""'));
    expect(lines[1], startsWith('2026-02-03,09:05,breakfast'));
  });

  test('resetAll wipes everything', () async {
    final s = await _store({'water_2026-02-03': 500});
    await s.resetAll();
    expect(s.getWater(day), 0);
  });
}

String _jsonOf(FoodItem f) => json.encode(f.toJson());
