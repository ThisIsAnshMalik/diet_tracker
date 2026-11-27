import 'package:diet_tracker/config/api_config.dart';
import 'package:diet_tracker/core/dio_client.dart';
import 'package:diet_tracker/models/food_item.dart';
import 'package:diet_tracker/models/food_source.dart';
import 'package:diet_tracker/models/serving_size.dart';
import 'package:diet_tracker/services/usda_nutrient_parser.dart';
import 'package:dio/dio.dart';

class UsdaSearchResult {
  const UsdaSearchResult({
    required this.items,
    required this.totalHits,
    required this.page,
    required this.pageSize,
  });

  final List<FoodItem> items;
  final int totalHits;
  final int page;
  final int pageSize;

  bool get hasMore => page * pageSize < totalHits;
}

class UsdaFoodService {
  UsdaFoodService({Dio? dio}) : _dio = dio ?? createUsdaDio();

  final Dio _dio;
  String? _lastQuery;
  Future<UsdaSearchResult>? _inflightSearch;

  Future<UsdaSearchResult> searchFoods(
    String query, {
    int page = 1,
  }) async {
    if (!ApiConfig.hasUsdaKey) {
      return const UsdaSearchResult(
        items: [],
        totalHits: 0,
        page: 1,
        pageSize: 0,
      );
    }

    final trimmed = query.trim();
    if (_inflightSearch != null && _lastQuery == '$trimmed|$page') {
      return _inflightSearch!;
    }
    _lastQuery = '$trimmed|$page';

    final future = _searchFoods(trimmed, page: page);
    _inflightSearch = future;
    try {
      return await future;
    } finally {
      _inflightSearch = null;
    }
  }

  Future<UsdaSearchResult> _searchFoods(String query, {required int page}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/foods/search',
        queryParameters: {'api_key': ApiConfig.usdaApiKey},
        data: {
          'query': query,
          'pageSize': ApiConfig.usdaPageSize,
          'pageNumber': page,
          'dataType': ['Foundation', 'SR Legacy', 'Survey (FNDDS)', 'Branded'],
        },
      );
      final data = response.data;
      if (data == null) {
        return UsdaSearchResult(
          items: [],
          totalHits: 0,
          page: page,
          pageSize: ApiConfig.usdaPageSize,
        );
      }
      final foods = data['foods'] as List<dynamic>? ?? [];
      final total = data['totalHits'] as int? ?? foods.length;
      final items = foods
          .map((e) => _fromSearchJson(e as Map<String, dynamic>))
          .where((f) => f != null)
          .cast<FoodItem>()
          .toList();
      return UsdaSearchResult(
        items: items,
        totalHits: total,
        page: page,
        pageSize: ApiConfig.usdaPageSize,
      );
    } on DioException {
      return UsdaSearchResult(
        items: [],
        totalHits: 0,
        page: page,
        pageSize: ApiConfig.usdaPageSize,
      );
    }
  }

  Future<FoodItem?> fetchFoodDetail(String fdcId) async {
    if (!ApiConfig.hasUsdaKey) return null;
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/food/$fdcId',
        queryParameters: {'api_key': ApiConfig.usdaApiKey},
      );
      final data = response.data;
      if (data == null) return null;
      return _fromDetailJson(data);
    } on DioException {
      return null;
    }
  }

  FoodItem? _fromSearchJson(Map<String, dynamic> json) {
    final fdcId = json['fdcId'];
    if (fdcId == null) return null;
    final description = json['description'] as String? ?? 'Unknown food';
    final dataType = json['dataType'] as String?;
    final category = json['foodCategory'] as String?;
    final nutrients = parseUsdaNutrients(json['foodNutrients'] as List<dynamic>?);
    if (!nutrients.hasCoreMacros) {
      return FoodItem(
        name: description,
        calories: 0,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
        servingLabel: '100 g',
        foodId: 'usda:$fdcId',
        source: FoodSource.usda,
        sourceFoodId: '$fdcId',
        foodCategory: category,
        dataType: dataType,
        caloriesPer100g: nutrients.caloriesPer100g,
        proteinPer100g: nutrients.proteinPer100g,
        carbohydratesPer100g: nutrients.carbohydratesPer100g,
        fatPer100g: nutrients.fatPer100g,
        fibrePer100g: nutrients.fibrePer100g,
        sugarPer100g: nutrients.sugarPer100g,
        saturatedFatPer100g: nutrients.saturatedFatPer100g,
        servingSizes: const [ServingSize.per100g],
        defaultServingGrams: 100,
        isRaw: inferRawCooked(description, category),
        isCooked: inferRawCooked(description, category) == false ? true : null,
      );
    }
    return _buildItem(
      fdcId: '$fdcId',
      description: description,
      dataType: dataType,
      category: category,
      nutrients: nutrients,
      portions: const [ServingSize.per100g],
    );
  }

  FoodItem? _fromDetailJson(Map<String, dynamic> json) {
    final fdcId = json['fdcId'];
    if (fdcId == null) return null;
    final description = json['description'] as String? ?? 'Unknown food';
    final dataType = json['dataType'] as String?;
    final category = json['foodCategory'] as String?;
    final nutrients = parseUsdaNutrients(json['foodNutrients'] as List<dynamic>?);

    final portions = <ServingSize>[ServingSize.per100g];
    final rawPortions = json['foodPortions'] as List<dynamic>? ?? [];
    for (final raw in rawPortions) {
      final map = raw as Map<String, dynamic>;
      final grams = (map['gramWeight'] as num?)?.toDouble();
      final desc = map['portionDescription'] as String? ??
          map['modifier'] as String? ??
          'Serving';
      if (grams != null && grams > 0) {
        portions.add(
          ServingSize(
            label: desc.trim().isEmpty ? '${grams.toStringAsFixed(0)} g' : desc,
            gramWeight: grams,
            unit: ServingUnit.standard,
          ),
        );
      }
    }

    return _buildItem(
      fdcId: '$fdcId',
      description: description,
      dataType: dataType,
      category: category,
      nutrients: nutrients,
      portions: portions,
    );
  }

  FoodItem _buildItem({
    required String fdcId,
    required String description,
    required String? dataType,
    required String? category,
    required UsdaNutrients nutrients,
    required List<ServingSize> portions,
  }) {
    final defaultGrams = portions.length > 1 && portions[1].gramWeight != null
        ? portions[1].gramWeight!
        : 100.0;
    final defaultPortion =
        portions.length > 1 ? portions[1] : ServingSize.per100g;

    return FoodItem(
      name: description,
      calories: ((nutrients.caloriesPer100g ?? 0) * defaultGrams / 100).round(),
      proteinG: (nutrients.proteinPer100g ?? 0) * defaultGrams / 100,
      carbsG: (nutrients.carbohydratesPer100g ?? 0) * defaultGrams / 100,
      fatG: (nutrients.fatPer100g ?? 0) * defaultGrams / 100,
      servingLabel: defaultPortion.label,
      foodId: 'usda:$fdcId',
      source: FoodSource.usda,
      sourceFoodId: fdcId,
      foodCategory: category,
      dataType: dataType,
      caloriesPer100g: nutrients.caloriesPer100g,
      proteinPer100g: nutrients.proteinPer100g,
      carbohydratesPer100g: nutrients.carbohydratesPer100g,
      fatPer100g: nutrients.fatPer100g,
      fibrePer100g: nutrients.fibrePer100g,
      sugarPer100g: nutrients.sugarPer100g,
      saturatedFatPer100g: nutrients.saturatedFatPer100g,
      servingSizes: portions,
      defaultServingGrams: defaultGrams,
      isPackagedFood: dataType == 'Branded',
      isRaw: inferRawCooked(description, category),
      isCooked: inferRawCooked(description, category) == false ? true : null,
      cachedAt: DateTime.now(),
    );
  }
}