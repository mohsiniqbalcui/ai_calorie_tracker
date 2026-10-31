import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/reminder_service.dart';

class ReminderConfig {
  final int id;
  final String key;
  final String label;
  final String body;
  final IconData icon;
  final bool enabled;
  final TimeOfDay time;

  const ReminderConfig({
    required this.id,
    required this.key,
    required this.label,
    required this.body,
    required this.icon,
    required this.enabled,
    required this.time,
  });

  ReminderConfig copyWith({bool? enabled, TimeOfDay? time}) => ReminderConfig(
        id: id,
        key: key,
        label: label,
        body: body,
        icon: icon,
        enabled: enabled ?? this.enabled,
        time: time ?? this.time,
      );
}

/// Daily "log your meal" reminders, saved on the device and scheduled as
/// local notifications.
class RemindersCubit extends Cubit<List<ReminderConfig>> {
  final SharedPreferences _prefs;
  final ReminderService _service;

  static const _defaults = [
    (
      'breakfast',
      'Breakfast',
      'Time to log your breakfast.',
      Icons.free_breakfast_rounded,
      8,
      0
    ),
    (
      'lunch',
      'Lunch',
      'Remember to log your lunch.',
      Icons.lunch_dining_rounded,
      13,
      0
    ),
    (
      'dinner',
      'Dinner',
      'Log your dinner to stay on track.',
      Icons.dinner_dining_rounded,
      19,
      0
    ),
    (
      'evening',
      'Daily check-in',
      'Anything left to log today? Review your day.',
      Icons.nights_stay_rounded,
      21,
      0
    ),
  ];

  RemindersCubit(this._prefs, this._service) : super(const []) {
    emit(_load());
  }

  static TimeOfDay parseTime(String s, TimeOfDay fallback) {
    final parts = s.split(':');
    if (parts.length != 2) return fallback;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59)
      return fallback;
    return TimeOfDay(hour: h, minute: m);
  }

  static String formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  List<ReminderConfig> _load() => [
        for (var i = 0; i < _defaults.length; i++)
          ReminderConfig(
            id: 100 + i,
            key: _defaults[i].$1,
            label: _defaults[i].$2,
            body: _defaults[i].$3,
            icon: _defaults[i].$4,
            enabled: _prefs.getBool('reminder_${_defaults[i].$1}_on') ?? false,
            time: parseTime(
                _prefs.getString('reminder_${_defaults[i].$1}_time') ?? '',
                TimeOfDay(hour: _defaults[i].$5, minute: _defaults[i].$6)),
          ),
      ];

  Future<void> _apply(ReminderConfig r) async {
    if (r.enabled) {
      await _service.scheduleDaily(
          id: r.id,
          hour: r.time.hour,
          minute: r.time.minute,
          title: 'Calorie Lens · ${r.label}',
          body: r.body);
    } else {
      await _service.cancel(r.id);
    }
  }

  /// Re-registers the saved reminders, for example after a restore or an app update.
  Future<void> syncAll() async {
    for (final r in state) {
      if (r.enabled) await _apply(r);
    }
  }

  /// Returns false when the user declined notification permission.
  Future<bool> setEnabled(String key, bool enabled) async {
    if (enabled && !await _service.requestPermission()) return false;
    final updated = [
      for (final r in state) r.key == key ? r.copyWith(enabled: enabled) : r
    ];
    await _prefs.setBool('reminder_${key}_on', enabled);
    emit(updated);
    await _apply(updated.firstWhere((r) => r.key == key));
    return true;
  }

  Future<void> setTime(String key, TimeOfDay time) async {
    final updated = [
      for (final r in state) r.key == key ? r.copyWith(time: time) : r
    ];
    await _prefs.setString('reminder_${key}_time', formatTime(time));
    emit(updated);
    await _apply(updated.firstWhere((r) => r.key == key));
  }
}
