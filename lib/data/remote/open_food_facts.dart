import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../food_database.dart';

/// Thrown when the online food database cannot be reached or misbehaves.
class FoodSourceException implements Exception {
  final String message;
  final bool offline;
  const FoodSourceException(this.message, {this.offline = false});

  @override
  String toString() => message;
}

/// Online food lookup backed by Open Food Facts (free, no API key).
/// Used for name search results and barcode scans; the built-in list stays
/// available offline.
class OpenFoodFactsSource {
  final http.Client _client;
  final Duration timeout;

  OpenFoodFactsSource(
      {http.Client? client, this.timeout = const Duration(seconds: 10)})
      : _client = client ?? http.Client();

  static const _headers = {'User-Agent': 'CalorieLens/1.0 (support@kjsis.com)'};
  static const _fields =
      'code,product_name,brands,nutriments,serving_size,serving_quantity,image_front_small_url';

  Future<List<FoodEntry>> search(String query, {int pageSize = 20}) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    final uri = Uri.https('search.openfoodfacts.org', '/search', {
      'q': q,
      'page_size': '$pageSize',
      'fields': _fields,
    });
    final body = await _get(uri);
    final hits = body['hits'];
    if (hits is! List) return const [];
    final seen = <String>{};
    return hits
        .whereType<Map<String, dynamic>>()
        .map(parseProduct)
        .whereType<FoodEntry>()
        .where((f) => seen.add('${f.name.toLowerCase()}|${f.kcal.round()}'))
        .toList();
  }

  /// Returns null when the barcode is not in the database.
  Future<FoodEntry?> byBarcode(String code) async {
    final digits = code.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return null;
    final uri = Uri.https('world.openfoodfacts.org',
        '/api/v2/product/$digits.json', {'fields': _fields});
    final body = await _get(uri, allowNotFound: true);
    if (body['status'] == 0) return null;
    final product = body['product'];
    if (product is! Map<String, dynamic>) return null;
    return parseProduct({...product, 'code': product['code'] ?? digits});
  }

  Future<Map<String, dynamic>> _get(Uri uri,
      {bool allowNotFound = false}) async {
    try {
      final res = await _client.get(uri, headers: _headers).timeout(timeout);
      if (res.statusCode == 404 && allowNotFound) return {'status': 0};
      if (res.statusCode != 200) {
        throw FoodSourceException(
            'The food database is busy (${res.statusCode}). Try again shortly.');
      }
      final decoded = json.decode(res.body);
      if (decoded is! Map<String, dynamic>) {
        throw const FoodSourceException(
            'Unexpected response from the food database.');
      }
      return decoded;
    } on SocketException {
      throw const FoodSourceException('You appear to be offline.',
          offline: true);
    } on http.ClientException {
      throw const FoodSourceException('You appear to be offline.',
          offline: true);
    } on TimeoutException {
      throw const FoodSourceException(
          'The food database took too long to respond.');
    } on FormatException {
      throw const FoodSourceException(
          'Unexpected response from the food database.');
    }
  }

  /// Maps an Open Food Facts product to a [FoodEntry] (per 100 g).
  /// Returns null when the product has no name or no calorie data.
  static FoodEntry? parseProduct(Map<String, dynamic> p) {
    final name = (p['product_name'] as String?)?.trim();
    final nutriments = p['nutriments'];
    if (name == null || name.isEmpty || nutriments is! Map) return null;

    double? n(String key) {
      final v = nutriments[key];
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    var kcal = n('energy-kcal_100g');
    if (kcal == null) {
      final kj = n('energy_100g') ?? n('energy-kj_100g');
      if (kj != null) kcal = kj / 4.184;
    }
    if (kcal == null || kcal < 0 || kcal > 900) return null;

    final brandsRaw = p['brands'];
    final brand = brandsRaw is List
        ? (brandsRaw.isEmpty ? null : '${brandsRaw.first}')
        : (brandsRaw is String && brandsRaw.trim().isNotEmpty
            ? brandsRaw.split(',').first.trim()
            : null);

    final servingG = _num(p['serving_quantity']);
    final servingSize = (p['serving_size'] as String?)?.trim();
    final hasServing = servingG != null && servingG > 0 && servingG <= 1000;

    return FoodEntry(
      name: name,
      category: 'Packaged',
      kcal: kcal,
      protein: n('proteins_100g') ?? 0,
      carbs: n('carbohydrates_100g') ?? 0,
      fat: n('fat_100g') ?? 0,
      fiber: n('fiber_100g') ?? 0,
      sugar: n('sugars_100g') ?? 0,
      sodium: (n('sodium_100g') ?? ((n('salt_100g') ?? 0) / 2.5)) * 1000,
      servingG: hasServing ? servingG : 100,
      servingLabel: hasServing
          ? (servingSize?.isNotEmpty == true ? servingSize! : '1 serving')
          : '100 g',
      tags: const {},
      imageUrl: p['image_front_small_url'] as String?,
      brand: brand,
      barcode: p['code']?.toString(),
    );
  }

  static double? _num(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
