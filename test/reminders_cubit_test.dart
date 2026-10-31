import 'package:calorie_lens/data/services/reminder_service.dart';
import 'package:calorie_lens/presentation/cubit/reminders_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeService implements ReminderService {
  bool allow = true;
  final scheduled = <int, TimeOfDay>{};
  int permissionRequests = 0;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return allow;
  }

  @override
  Future<void> scheduleDaily(
      {required int id,
      required int hour,
      required int minute,
      required String title,
      required String body}) async {
    scheduled[id] = TimeOfDay(hour: hour, minute: minute);
  }

  @override
  Future<void> cancel(int id) async => scheduled.remove(id);
}

Future<(RemindersCubit, _FakeService, SharedPreferences)> _make(
    [Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  final service = _FakeService();
  return (RemindersCubit(prefs, service), service, prefs);
}

void main() {
  test('starts with four reminders, all off, with sensible default times',
      () async {
    final (c, service, _) = await _make();
    expect(
        c.state.map((r) => r.key), ['breakfast', 'lunch', 'dinner', 'evening']);
    expect(c.state.any((r) => r.enabled), isFalse);
    expect(c.state.first.time, const TimeOfDay(hour: 8, minute: 0));
    expect(service.scheduled, isEmpty);
  });

  test('enabling asks for permission, schedules, and persists', () async {
    final (c, service, prefs) = await _make();
    expect(await c.setEnabled('lunch', true), isTrue);
    expect(service.permissionRequests, 1);
    expect(service.scheduled[101], const TimeOfDay(hour: 13, minute: 0));
    expect(c.state.firstWhere((r) => r.key == 'lunch').enabled, isTrue);
    expect(prefs.getBool('reminder_lunch_on'), isTrue);
  });

  test('denied permission leaves the reminder off', () async {
    final (c, service, prefs) = await _make();
    service.allow = false;
    expect(await c.setEnabled('dinner', true), isFalse);
    expect(c.state.firstWhere((r) => r.key == 'dinner').enabled, isFalse);
    expect(service.scheduled, isEmpty);
    expect(prefs.getBool('reminder_dinner_on'), isNull);
  });

  test('disabling cancels without asking permission again', () async {
    final (c, service, _) = await _make();
    await c.setEnabled('breakfast', true);
    await c.setEnabled('breakfast', false);
    expect(service.scheduled, isEmpty);
    expect(service.permissionRequests, 1);
  });

  test('changing the time reschedules an enabled reminder', () async {
    final (c, service, prefs) = await _make();
    await c.setEnabled('breakfast', true);
    await c.setTime('breakfast', const TimeOfDay(hour: 7, minute: 30));
    expect(service.scheduled[100], const TimeOfDay(hour: 7, minute: 30));
    expect(prefs.getString('reminder_breakfast_time'), '07:30');
  });

  test('saved reminders are restored and re-registered on start-up', () async {
    final (c, service, _) = await _make(
        {'reminder_evening_on': true, 'reminder_evening_time': '22:15'});
    expect(c.state.last.enabled, isTrue);
    expect(c.state.last.time, const TimeOfDay(hour: 22, minute: 15));
    await c.syncAll();
    expect(service.scheduled.keys, [103]);
    expect(service.scheduled[103], const TimeOfDay(hour: 22, minute: 15));
  });

  test('parseTime rejects bad values', () {
    const fallback = TimeOfDay(hour: 9, minute: 0);
    expect(RemindersCubit.parseTime('25:00', fallback), fallback);
    expect(RemindersCubit.parseTime('abc', fallback), fallback);
    expect(RemindersCubit.parseTime('', fallback), fallback);
    expect(RemindersCubit.parseTime('06:05', fallback),
        const TimeOfDay(hour: 6, minute: 5));
    expect(RemindersCubit.formatTime(const TimeOfDay(hour: 6, minute: 5)),
        '06:05');
  });
}
