import '../../data/models/user_data.dart';

class Units {
  static double kgToLb(double kg) => kg * 2.2046226218;
  static double lbToKg(double lb) => lb / 2.2046226218;

  static String weight(double kg, bool metric, {int digits = 1}) => metric
      ? '${kg.toStringAsFixed(digits)} kg'
      : '${kgToLb(kg).toStringAsFixed(digits)} lb';

  static String height(double cm, bool metric) {
    if (metric) return '${cm.toStringAsFixed(0)} cm';
    final totalInches = cm / 2.54;
    final feet = totalInches ~/ 12;
    final inches = (totalInches - feet * 12).round();
    return '$feet′ $inches″';
  }

  static String volume(int ml, bool metric) =>
      metric ? '$ml ml' : '${(ml / 29.5735).toStringAsFixed(0)} fl oz';

  static String weightUnit(bool metric) => metric ? 'kg' : 'lb';
}

class BodyMetrics {
  static double bmi(double kg, double cm) {
    final m = cm / 100;
    return m <= 0 ? 0 : kg / (m * m);
  }

  static String bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Healthy';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  /// Mifflin-St Jeor basal metabolic rate.
  static double bmr(UserData u, {double? weightKg}) {
    final w = weightKg ?? u.weight;
    final base = 10 * w + 6.25 * u.height - 5 * u.age;
    return switch (u.gender) {
      'Male' => base + 5,
      'Female' => base - 161,
      _ => base - 78,
    };
  }

  static (double, double) healthyWeightRange(double cm) {
    final m = cm / 100;
    return (18.5 * m * m, 24.9 * m * m);
  }
}

class DateFmt {
  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  static bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  static String short(DateTime d) => '${d.day} ${_months[d.month - 1]}';
  static String weekday(DateTime d) => _days[d.weekday - 1];
  static String weekdayInitial(DateTime d) => _days[d.weekday - 1][0];

  static String relative(DateTime d) {
    final today = dateOnly(DateTime.now());
    final diff = today.difference(dateOnly(d)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff == -1) return 'Tomorrow';
    return weekday(d);
  }
}
