import 'package:diet_tracker/config/api_config.dart';
import 'package:diet_tracker/data/food_cache_storage.dart';
import 'package:diet_tracker/data/food_catalog.dart';
import 'package:diet_tracker/logic/nutrition_calculator.dart';
import 'package:diet_tracker/models/food_item.dart';
import 'package:diet_tracker/models/food_source.dart';
import 'package:diet_tracker/services/open_food_facts_service.dart';
import 'package:diet_tracker/services/usda_food_service.dart';

class FoodSearchResult {
  const FoodSearchResult({
    required this.items,
    required this.fromCache,
    required this.fromApi,
    this.hasMore = false,
    this.page = 1,
    this.errorMessage,
  });

  final List<FoodItem> items;
  final bool fromCache;
  final bool fromApi;
  final bool hasMore;
  final int page;
  final String? errorMessage;
}

class NutritionRepository {
  NutritionRepository({
    required FoodCacheStorage cache,
    UsdaFoodService? usda,
    OpenFoodFactsService? openFoodFacts,
  })  : _cache = cache,
        _usda = usda ?? UsdaFoodService(),
        _off = openFoodFacts ?? OpenFoodFactsService();

  final FoodCacheStorage _cache;
  final UsdaFoodService _usda;
  final OpenFoodFactsService _off;

  String? _activeQuery;

  static final _barcodePattern = RegExp(r'^\d{8,14}$');

  static const _packagedKeywords = [
    'biscuit',
    'cereal',
    'protein bar',
    'chips',
    'namkeen',
    'snack pack',
    'beverage',
    'coke',
    'pepsi',
    'nestle',
    'britannia',
    'haldiram',
    'amul',
    'parle',
    'kellogg',
    'cadbury',
    'instant noodles',
    'packaged',
    'maggi',
  ];

  Future<FoodSearchResult> search(String query, {int page = 1}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const FoodSearchResult(items: [], fromCache: false, fromApi: false);
    }

    if (_barcodePattern.hasMatch(trimmed)) {
      return _searchBarcode(trimmed);
    }

    if (_activeQuery == trimmed && page == 1) {
      // Allow concurrent page fetches only.
    }
    _activeQuery = trimmed;

    final local = <FoodItem>[
      ..._searchCatalog(trimmed),
      ..._cache.searchLocal(trimmed),
    ];

    final packaged = _isPackagedQuery(trimmed);
    List<FoodItem> remote = [];
    var hasMore = false;
    String? error;

    if (packaged) {
      final off = await _off.searchProducts(trimmed, page: page);
      remote = off.items;
      hasMore = off.hasMore;
      if (remote.isEmpty && trimmed.length > 2) {
        error = 'No packaged products found. Try another brand or name.';
      }
    } else if (!_hasSuitableLocal(local, trimmed)) {
      if (!ApiConfig.hasUsdaKey) {
        error ??= 'USDA_API_KEY is not set. Add --dart-define=USDA_API_KEY=...';
      } else {
        final usda = await _usda.searchFoods(trimmed, page: page);
        remote = usda.items;
        hasMore = usda.hasMore;
        if (remote.isEmpty) {
          error = 'No foods found. Try a different spelling.';
        }
      }
    }

    final merged = _merge(local, remote);
    await _cache.upsertAll(merged.where((f) => f.source != FoodSource.catalog));

    return FoodSearchResult(
      items: merged,
      fromCache: local.isNotEmpty,
      fromApi: remote.isNotEmpty,
      hasMore: hasMore,
      page: page,
      errorMessage: merged.isEmpty ? error : null,
    );
  }

  Future<FoodItem?> lookupBarcode(String barcode) async {
    final cached = _cache.getByBarcode(barcode);
    if (cached != null && _cache.isFresh(cached)) return cached;

    final product = await _off.lookupBarcode(barcode);
    if (product == null) return null;
    final enriched = NutritionCalculator.withDefaultServingDisplay(product);
    await _cache.upsert(enriched);
    return enriched;
  }

  Future<FoodItem?> ensureDetail(FoodItem item) async {
    if (item.source == FoodSource.openFoodFacts &&
        item.barcode != null &&
        !_cache.isFresh(item)) {
      final refreshed = await _off.lookupBarcode(item.barcode!);
      if (refreshed != null) {
        final display = NutritionCalculator.withDefaultServingDisplay(refreshed);
        await _cache.upsert(display);
        return display;
      }
    }
    if (item.source == FoodSource.usda &&
        item.sourceFoodId != null &&
        item.servingSizes.length <= 1) {
      final detail = await _usda.fetchFoodDetail(item.sourceFoodId!);
      if (detail != null) {
        final display = NutritionCalculator.withDefaultServingDisplay(detail);
        await _cache.upsert(display);
        return display;
      }
    }
    if (_cache.isFresh(item)) return item;
    await _cache.upsert(item);
    return item;
  }

  List<FoodItem> listCachedFoods() => _cache.loadAllMap().values.toList();

  Future<FoodSearchResult> _searchBarcode(String barcode) async {
    final cached = _cache.getByBarcode(barcode);
    if (cached != null) {
      return FoodSearchResult(
        items: [cached],
        fromCache: true,
        fromApi: false,
      );
    }
    final product = await lookupBarcode(barcode);
    if (product == null) {
      return const FoodSearchResult(
        items: [],
        fromCache: false,
        fromApi: true,
        errorMessage: 'Barcode not found in Open Food Facts.',
      );
    }
    return FoodSearchResult(
      items: [product],
      fromCache: false,
      fromApi: true,
    );
  }

  List<FoodItem> _searchCatalog(String query) {
    final q = query.toLowerCase();
    return foodCatalog
        .where((f) => f.name.toLowerCase().contains(q))
        .map((f) => f.copyWith(source: FoodSource.catalog))
        .toList();
  }

  bool _hasSuitableLocal(List<FoodItem> local, String query) {
    final q = query.toLowerCase();
    if (local.isEmpty) return false;
    return local.any((f) {
      final name = f.name.toLowerCase();
      return name.contains(q) || name.split(' ').any((w) => w.startsWith(q));
    });
  }

  bool _isPackagedQuery(String query) {
    final lower = query.toLowerCase();
    if (_packagedKeywords.any(lower.contains)) return true;
    return RegExp(r'\b(ltd|pvt|brand|®)\b').hasMatch(lower);
  }

  List<FoodItem> _merge(List<FoodItem> a, List<FoodItem> b) {
    final seen = <String>{};
    final out = <FoodItem>[];
    for (final item in [...a, ...b]) {
      final key = item.cacheKey;
      if (seen.add(key)) {
        out.add(NutritionCalculator.withDefaultServingDisplay(item));
      }
    }
    return out;
  }
}

FoodItem? findFoodByName(String name) {
  for (final item in foodCatalog) {
    if (item.name.toLowerCase() == name.toLowerCase()) return item;
  }
  return null;
}