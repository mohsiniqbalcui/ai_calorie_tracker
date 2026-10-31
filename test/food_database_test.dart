import 'package:calorie_lens/data/food_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FoodDatabase', () {
    test('has unique names and sane nutrition values', () {
      final names = FoodDatabase.all.map((f) => f.name).toList();
      expect(names.toSet().length, names.length,
          reason: 'duplicate food names');
      expect(FoodDatabase.all.length, greaterThan(100));
      for (final f in FoodDatabase.all) {
        expect(f.kcal, inInclusiveRange(0, 900), reason: f.name);
        expect(f.servingG, greaterThan(0), reason: f.name);
        expect(FoodDatabase.categories, contains(f.category), reason: f.name);
        // Macro energy should not exceed the stated calories by a wide margin.
        final macroKcal = f.protein * 4 + f.carbs * 4 + f.fat * 9;
        expect(macroKcal, lessThan(f.kcal * 1.35 + 15), reason: f.name);
      }
    });

    test('portion scales per-100g values', () {
      final egg = FoodDatabase.byName('Egg, boiled')!;
      final p = egg.portion(200);
      expect(p.kcal, closeTo(egg.kcal * 2, 1e-9));
      expect(p.protein, closeTo(egg.protein * 2, 1e-9));
      expect(egg.portion(0).kcal, 0);
    });

    test('byName is exact and returns null for unknown', () {
      expect(FoodDatabase.byName('Apple'), isNotNull);
      expect(FoodDatabase.byName('apple'), isNull);
      expect(FoodDatabase.byName('Nope'), isNull);
    });

    test('search requires every word and ranks prefix matches first', () {
      final r = FoodDatabase.search('chicken breast');
      expect(r, isNotEmpty);
      expect(r.every((f) => f.name.toLowerCase().contains('chicken')), isTrue);
      final apple = FoodDatabase.search('apple');
      expect(apple.first.name.toLowerCase().startsWith('apple'), isTrue);
      expect(FoodDatabase.search('zzzzqq'), isEmpty);
    });

    test('category filter and empty query', () {
      final fruit = FoodDatabase.search('', category: 'Fruit');
      expect(fruit, isNotEmpty);
      expect(fruit.every((f) => f.category == 'Fruit'), isTrue);
      expect(FoodDatabase.search('').length, FoodDatabase.all.length);
    });

    test('diet filter only returns foods carrying every tag', () {
      for (final diet in FoodDatabase.diets) {
        final r = FoodDatabase.search('', diet: {diet.key});
        expect(r.every((f) => f.tags.contains(diet.key)), isTrue,
            reason: diet.key);
      }
      final vegan = FoodDatabase.search('', diet: {'vegan'});
      expect(vegan, isNotEmpty);
      expect(vegan.any((f) => f.name.startsWith('Chicken')), isFalse);
    });
  });
}
