import 'package:calorie_lens/core/utils/units.dart';
import 'package:calorie_lens/data/models/user_data.dart';
import 'package:flutter_test/flutter_test.dart';

UserData _user(String gender) => UserData(
      weight: 70,
      height: 170,
      age: 30,
      activityLevel: 'Light',
      gender: gender,
      goal: 'Maintain',
      estimatedCalories: 2000,
      proteinGoal: 100,
      fatGoal: 60,
      carbsGoal: 250,
    );

void main() {
  group('Units', () {
    test('kg <-> lb round trip', () {
      expect(Units.kgToLb(100), closeTo(220.46, 0.01));
      expect(Units.lbToKg(Units.kgToLb(72.5)), closeTo(72.5, 1e-9));
    });

    test('formatting honours the unit system', () {
      expect(Units.weight(70, true), '70.0 kg');
      expect(Units.weight(70, false), '154.3 lb');
      expect(Units.height(170, true), '170 cm');
      expect(Units.height(180, false), '5′ 11″');
      expect(Units.volume(500, true), '500 ml');
      expect(Units.volume(500, false), '17 fl oz');
      expect(Units.weightUnit(false), 'lb');
    });
  });

  group('BodyMetrics', () {
    test('bmi and categories', () {
      expect(BodyMetrics.bmi(70, 170), closeTo(24.22, 0.01));
      expect(BodyMetrics.bmi(70, 0), 0);
      expect(BodyMetrics.bmiCategory(17), 'Underweight');
      expect(BodyMetrics.bmiCategory(22), 'Healthy');
      expect(BodyMetrics.bmiCategory(27), 'Overweight');
      expect(BodyMetrics.bmiCategory(35), 'Obese');
    });

    test('bmr by gender', () {
      const base = 10 * 70 + 6.25 * 170 - 5 * 30;
      expect(BodyMetrics.bmr(_user('Male')), base + 5);
      expect(BodyMetrics.bmr(_user('Female')), base - 161);
      expect(BodyMetrics.bmr(_user('Other')), base - 78);
      expect(BodyMetrics.bmr(_user('Male'), weightKg: 80), base + 100 + 5);
    });

    test('healthy weight range brackets a healthy BMI', () {
      final (lo, hi) = BodyMetrics.healthyWeightRange(170);
      expect(lo, closeTo(53.5, 0.1));
      expect(hi, closeTo(72.0, 0.1));
    });
  });

  group('DateFmt', () {
    test('date helpers', () {
      final d = DateTime(2026, 3, 9, 15, 30); // Monday
      expect(DateFmt.dateOnly(d), DateTime(2026, 3, 9));
      expect(DateFmt.sameDay(d, DateTime(2026, 3, 9, 1)), isTrue);
      expect(DateFmt.sameDay(d, DateTime(2026, 3, 10)), isFalse);
      expect(DateFmt.short(d), '9 Mar');
      expect(DateFmt.weekday(d), 'Mon');
      expect(DateFmt.weekdayInitial(d), 'M');
    });

    test('relative labels', () {
      final now = DateTime.now();
      expect(DateFmt.relative(now), 'Today');
      expect(DateFmt.relative(now.subtract(const Duration(days: 1))), 'Yesterday');
      expect(DateFmt.relative(now.add(const Duration(days: 1))), 'Tomorrow');
    });
  });
}
