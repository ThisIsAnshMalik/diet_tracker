import 'dart:convert';

import 'package:diet_tracker/models/food_entry.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DietStorage {
  DietStorage(this._prefs);

  static const _entriesKey = 'food_entries';

  final SharedPreferences _prefs;

  static Future<DietStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return DietStorage(prefs);
  }

  List<FoodEntry> loadAll() {
    final raw = _prefs.getString(_entriesKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => FoodEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAll(List<FoodEntry> entries) async {
    final encoded =
        jsonEncode(entries.map((e) => e.toJson()).toList(growable: false));
    await _prefs.setString(_entriesKey, encoded);
  }

  List<FoodEntry> entriesForDate(DateTime date, List<FoodEntry> all) {
    return all
        .where((e) => DateUtils.isSameDay(e.loggedAt, date))
        .toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  }

  Future<void> add(FoodEntry entry) async {
    final all = loadAll()..add(entry);
    await saveAll(all);
  }

  Future<void> remove(String id) async {
    final all = loadAll()..removeWhere((e) => e.id == id);
    await saveAll(all);
  }

  /// Most recently logged entries (newest first), unique by food name.
  List<FoodEntry> recentEntries({int limit = 12}) {
    final all = loadAll()..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    final seen = <String>{};
    final result = <FoodEntry>[];
    for (final e in all) {
      final key = e.name.toLowerCase();
      if (seen.add(key)) {
        result.add(e);
        if (result.length >= limit) break;
      }
    }
    return result;
  }
}