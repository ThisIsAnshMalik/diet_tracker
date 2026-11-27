import 'package:diet_tracker/config/api_config.dart';
import 'package:diet_tracker/core/dio_client.dart';
import 'package:diet_tracker/logic/nutrition_calculator.dart';
import 'package:diet_tracker/models/food_item.dart';
import 'package:diet_tracker/models/food_source.dart';
import 'package:diet_tracker/models/serving_size.dart';
import 'package:dio/dio.dart';

class OffSearchResult {
  const OffSearchResult({
    required this.items,
    required this.count,
    required this.page,
  });

  final List<FoodItem> items;
  final int count;
  final int page;

  bool get hasMore => items.length >= ApiConfig.offPageSize;
}

class OpenFoodFactsService {
  OpenFoodFactsService({Dio? dio}) : _dio = dio ?? createOpenFoodFactsDio();

  final Dio _dio;
  String? _lastQuery;
  Future<OffSearchResult>? _inflightSearch;

  Future<OffSearchResult> searchProducts(
    String query, {
    int page = 1,
  }) async {
    final trimmed = query.trim();
    if (_inflightSearch != null && _lastQuery == '$trimmed|$page') {
      return _inflightSearch!;
    }
    _lastQuery = '$trimmed|$page';
    final future = _search(trimmed, page);
    _inflightSearch = future;
    try {
      return await future;
    } finally {
      _inflightSearch = null;
    }
  }

  Future<OffSearchResult> _search(String query, int page) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/cgi/search.pl',
        queryParameters: {
          'search_terms': query,
          'search_simple': 1,
          'action': 'process',
          'json': 1,
          'page_size': ApiConfig.offPageSize,
          'page': page,
          'fields':
              'code,product_name,brands,nutriments,serving_size,serving_quantity,product_quantity,image_url,categories',
        },
      );
      final data = response.data;
      final products = data?['products'] as List<dynamic>? ?? [];
      final items = <FoodItem>[];
      final seen = <String>{};
      for (final raw in products) {
        final item = _fromProductJson(raw as Map<String, dynamic>);
        if (item == null) continue;
        final key = item.barcode ?? item.name.toLowerCase();
        if (seen.add(key)) items.add(item);
      }
      return OffSearchResult(items: items, count: items.length, page: page);
    } on DioException {
      return OffSearchResult(items: [], count: 0, page: page);
    }
  }

  Future<FoodItem?> lookupBarcode(String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty) return null;
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/api/v2/product/$code',
        queryParameters: {
          'fields':
              'code,product_name,brands,nutriments,serving_size,serving_quantity,product_quantity,image_url,categories',
        },
      );
      final data = response.data;
      if (data == null) return null;
      if (data['status'] == 0) return null;
      final product = data['product'] as Map<String, dynamic>?;
      if (product == null) return null;
      return _fromProductJson(product);
    } on DioException {
      return null;
    }
  }

  FoodItem? parseProductJson(Map<String, dynamic> json) =>
      _fromProductJson(json);

  FoodItem? _fromProductJson(Map<String, dynamic> json) {
    final name = json['product_name'] as String?;
    if (name == null || name.trim().isEmpty) return null;

    final brand = (json['brands'] as String?)?.split(',').first.trim();
    final barcode = json['code']?.toString();
    final nutrients = json['nutriments'] as Map<String, dynamic>? ?? {};
    final per100 = _parseOffNutriments(nutrients);
    if (!per100.hasCore) return null;

    final servings = <ServingSize>[];
    final servingSize = json['serving_size'] as String?;
    var servingGrams = _num(nutrients['serving_size']);
    servingGrams ??= _num(nutrients['serving_quantity']);
    servingGrams ??= _num(json['serving_quantity']);
    if (servingGrams != null && servingGrams > 0) {
      servings.add(
        ServingSize(
          label: servingSize?.trim().isNotEmpty == true
              ? servingSize!
              : '${servingGrams.toStringAsFixed(0)} g serving',
          gramWeight: servingGrams,
          unit: ServingUnit.standard,
        ),
      );
    } else if (servingSize != null && servingSize.trim().isNotEmpty) {
      servings.add(
        ServingSize(
          label: servingSize,
          unit: ServingUnit.standard,
          isEstimated: true,
        ),
      );
    }
    servings.add(ServingSize.per100g);

    final defaultGrams = servingGrams ?? 100.0;
    final base = FoodItem(
      name: name.trim(),
      calories: 0,
      proteinG: 0,
      carbsG: 0,
      fatG: 0,
      servingLabel: servings.isNotEmpty ? servings.first.label : '100 g',
      foodId: barcode != null ? 'off:$barcode' : null,
      brandName: brand,
      source: FoodSource.openFoodFacts,
      sourceFoodId: barcode,
      barcode: barcode,
      foodCategory: json['categories'] as String?,
      imageUrl: json['image_url'] as String?,
      caloriesPer100g: per100.calories,
      proteinPer100g: per100.protein,
      carbohydratesPer100g: per100.carbs,
      fatPer100g: per100.fat,
      fibrePer100g: per100.fibre,
      sugarPer100g: per100.sugar,
      saturatedFatPer100g: per100.saturatedFat,
      servingSizes: servings,
      isPackagedFood: true,
      defaultServingGrams: defaultGrams,
      cachedAt: DateTime.now(),
    );

    return NutritionCalculator.withDefaultServingDisplay(base);
  }
}

class _OffNutrients {
  const _OffNutrients({
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fibre,
    this.sugar,
    this.saturatedFat,
  });

  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final double? fibre;
  final double? sugar;
  final double? saturatedFat;

  bool get hasCore =>
      calories != null || protein != null || carbs != null || fat != null;
}

_OffNutrients _parseOffNutriments(Map<String, dynamic> n) {
  double? pick100(String key) {
    final v = n['${key}_100g'] ?? n[key];
    return _num(v);
  }

  var kcal = pick100('energy-kcal');
  if (kcal == null) {
    final kj = pick100('energy');
    if (kj != null) kcal = kj / 4.184;
  }

  return _OffNutrients(
    calories: kcal,
    protein: pick100('proteins'),
    carbs: pick100('carbohydrates'),
    fat: pick100('fat'),
    fibre: pick100('fiber'),
    sugar: pick100('sugars'),
    saturatedFat: pick100('saturated-fat'),
  );
}

double? _num(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}