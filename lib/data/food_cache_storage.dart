import 'dart:convert';

import 'package:diet_tracker/config/api_config.dart';
import 'package:diet_tracker/models/food_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FoodCacheStorage {
  FoodCacheStorage(this._prefs);

  static const _foodsKey = 'cached_foods_v1';

  final SharedPreferences _prefs;

  static Future<FoodCacheStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return FoodCacheStorage(prefs);
  }

  Map<String, FoodItem> loadAllMap() {
    final raw = _prefs.getString(_foodsKey);
    if (raw == null || raw.isEmpty) return {};
    final list = jsonDecode(raw) as List<dynamic>;
    final map = <String, FoodItem>{};
    for (final entry in list) {
      final item = FoodItem.fromJson(entry as Map<String, dynamic>);
      map[item.cacheKey] = item;
    }
    return map;
  }

  List<FoodItem> searchLocal(String query, {int limit = 40}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final results = <FoodItem>[];
    for (final item in loadAllMap().values) {
      final hay =
          '${item.name} ${item.brandName ?? ''} ${item.foodCategory ?? ''}'
              .toLowerCase();
      if (hay.contains(q)) {
        results.add(item);
        if (results.length >= limit) break;
      }
    }
    results.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
    return results;
  }

  FoodItem? getByBarcode(String barcode) {
    for (final item in loadAllMap().values) {
      if (item.barcode == barcode) return item;
    }
    return null;
  }

  FoodItem? getByKey(String key) => loadAllMap()[key];

  bool isFresh(FoodItem item) {
    final at = item.cachedAt;
    if (at == null) return false;
    return DateTime.now().difference(at) < ApiConfig.cacheMaxAge;
  }

  Future<void> upsert(FoodItem item) async {
    final map = loadAllMap();
    map[item.cacheKey] = item.copyWith(cachedAt: DateTime.now());
    await _save(map);
  }

  Future<void> upsertAll(Iterable<FoodItem> items) async {
    if (items.isEmpty) return;
    final map = loadAllMap();
  final now = DateTime.now();
    for (final item in items) {
      map[item.cacheKey] = item.copyWith(cachedAt: now);
    }
    await _save(map);
  }

  Future<void> _save(Map<String, FoodItem> map) async {
    final list = map.values.map((e) => e.toJson()).toList();
    await _prefs.setString(_foodsKey, jsonEncode(list));
  }
}