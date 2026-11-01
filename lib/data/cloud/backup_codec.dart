import 'package:shared_preferences/shared_preferences.dart';

/// Turns the app's saved data into a map that fits in one cloud document,
/// and back. Keys that only matter on this device are left out.
class BackupCodec {
  static const _skip = ['draft', 'onboarding_step', 'notification'];

  static bool _included(String key) => !_skip.any(key.contains);

  static Map<String, dynamic> encode(SharedPreferences prefs) {
    final values = <String, dynamic>{};
    for (final key in prefs.getKeys().where(_included)) {
      final v = prefs.get(key);
      if (v != null) values[key] = v;
    }
    return {
      'savedAt': DateTime.now().toUtc().toIso8601String(),
      'values': values,
    };
  }

  /// Replaces local data with the backup. Returns how many values were restored.
  static Future<int> restore(
      SharedPreferences prefs, Map<String, dynamic> backup) async {
    final values = Map<String, dynamic>.from(backup['values'] as Map? ?? {});
    var count = 0;
    for (final e in values.entries) {
      final v = e.value;
      if (!_included(e.key)) continue;
      if (v is bool) {
        await prefs.setBool(e.key, v);
      } else if (v is int) {
        await prefs.setInt(e.key, v);
      } else if (v is double) {
        await prefs.setDouble(e.key, v);
      } else if (v is String) {
        await prefs.setString(e.key, v);
      } else if (v is List) {
        await prefs.setStringList(e.key, v.map((x) => '$x').toList());
      } else {
        continue;
      }
      count++;
    }
    return count;
  }

  static DateTime? savedAt(Map<String, dynamic> backup) =>
      DateTime.tryParse('${backup['savedAt']}')?.toLocal();
}
