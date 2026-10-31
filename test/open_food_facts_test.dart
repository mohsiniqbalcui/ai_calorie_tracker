import 'dart:convert';
import 'dart:io';

import 'package:calorie_lens/data/remote/open_food_facts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> _product(
        {String name = 'Hazelnut spread',
        num? kcal = 539,
        dynamic brands = 'Nutella, Ferrero'}) =>
    {
      'code': '3017620422003',
      'product_name': name,
      'brands': brands,
      'serving_quantity': 15,
      'serving_size': '15 g',
      'image_front_small_url': 'https://example.com/a.jpg',
      'nutriments': {
        if (kcal != null) 'energy-kcal_100g': kcal,
        'proteins_100g': 6.3,
        'carbohydrates_100g': 57.5,
        'fat_100g': 30.9,
        'fiber_100g': 0,
        'sugars_100g': 56.3,
        'sodium_100g': 0.0428,
      },
    };

void main() {
  group('parseProduct', () {
    test('maps per-100g values, serving and brand', () {
      final f = OpenFoodFactsSource.parseProduct(_product())!;
      expect(f.name, 'Hazelnut spread');
      expect(f.kcal, 539);
      expect(f.protein, 6.3);
      expect(f.sodium, closeTo(42.8, 0.01)); // g -> mg
      expect(f.servingG, 15);
      expect(f.servingLabel, '15 g');
      expect(f.brand, 'Nutella');
      expect(f.barcode, '3017620422003');
      expect(f.isOnline, isTrue);
    });

    test('accepts brands as a list and falls back to 100 g servings', () {
      final p = _product(brands: ['Ferrero'])..remove('serving_quantity');
      final f = OpenFoodFactsSource.parseProduct(p)!;
      expect(f.brand, 'Ferrero');
      expect(f.servingG, 100);
      expect(f.servingLabel, '100 g');
    });

    test('derives kcal from kJ when kcal is missing', () {
      final p = _product(kcal: null);
      (p['nutriments'] as Map)['energy_100g'] = 2092;
      expect(OpenFoodFactsSource.parseProduct(p)!.kcal, closeTo(500, 0.5));
    });

    test('rejects products without a name or sane calories', () {
      expect(OpenFoodFactsSource.parseProduct(_product(name: '  ')), isNull);
      expect(OpenFoodFactsSource.parseProduct(_product(kcal: null)), isNull);
      expect(OpenFoodFactsSource.parseProduct(_product(kcal: 5000)), isNull);
    });

    test('missing macros default to zero', () {
      final p = {
        'product_name': 'Mystery',
        'nutriments': {'energy-kcal_100g': 120},
      };
      final f = OpenFoodFactsSource.parseProduct(p)!;
      expect([f.protein, f.carbs, f.fat, f.fiber, f.sugar, f.sodium],
          everyElement(0));
    });
  });

  group('search', () {
    test('returns de-duplicated foods and sends a User-Agent', () async {
      late http.Request seen;
      final source = OpenFoodFactsSource(
        client: MockClient((req) async {
          seen = req;
          return http.Response(
            json.encode({
              'hits': [_product(), _product(), _product(name: 'Other')]
            }),
            200,
          );
        }),
      );
      final r = await source.search('nutella');
      expect(r.map((f) => f.name), ['Hazelnut spread', 'Other']);
      expect(seen.url.host, 'search.openfoodfacts.org');
      expect(seen.url.queryParameters['q'], 'nutella');
      expect(seen.headers['User-Agent'], contains('CalorieLens'));
    });

    test('short queries do not hit the network', () async {
      final source = OpenFoodFactsSource(
          client: MockClient((_) async => fail('should not be called')));
      expect(await source.search(' a '), isEmpty);
    });

    test('maps connection failures to an offline error', () async {
      final source = OpenFoodFactsSource(
          client:
              MockClient((_) async => throw const SocketException('no route')));
      expect(
        source.search('apple'),
        throwsA(isA<FoodSourceException>()
            .having((e) => e.offline, 'offline', isTrue)),
      );
    });

    test('maps server errors and bad bodies to a readable error', () async {
      final busy = OpenFoodFactsSource(
          client: MockClient((_) async => http.Response('nope', 503)));
      expect(
          busy.search('apple'),
          throwsA(isA<FoodSourceException>()
              .having((e) => e.offline, 'offline', isFalse)));
      final garbage = OpenFoodFactsSource(
          client: MockClient((_) async => http.Response('<html>', 200)));
      expect(garbage.search('apple'), throwsA(isA<FoodSourceException>()));
    });
  });

  group('byBarcode', () {
    test('returns the product', () async {
      final source = OpenFoodFactsSource(
        client: MockClient((req) async {
          expect(req.url.path, '/api/v2/product/3017620422003.json');
          return http.Response(
              json.encode({'status': 1, 'product': _product()}), 200);
        }),
      );
      final f = await source.byBarcode('3017-6204-22003');
      expect(f!.barcode, '3017620422003');
    });

    test('returns null for unknown or too-short codes', () async {
      final unknown = OpenFoodFactsSource(
          client: MockClient(
              (_) async => http.Response(json.encode({'status': 0}), 200)));
      expect(await unknown.byBarcode('0000000000000'), isNull);
      final notFound = OpenFoodFactsSource(
          client: MockClient((_) async => http.Response('', 404)));
      expect(await notFound.byBarcode('0000000000000'), isNull);
      final short = OpenFoodFactsSource(
          client: MockClient((_) async => fail('should not be called')));
      expect(await short.byBarcode('123'), isNull);
    });
  });
}
