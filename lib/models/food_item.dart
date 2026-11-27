import 'package:diet_tracker/models/food_source.dart';
import 'package:diet_tracker/models/serving_size.dart';

/// Unified food model used across catalog, USDA, Open Food Facts and cache.
class FoodItem {
  const FoodItem({
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.servingLabel = '1 serving',
    this.foodId,
    this.brandName,
    this.source = FoodSource.catalog,
    this.sourceFoodId,
    this.barcode,
    this.foodCategory,
    this.imageUrl,
    this.dataType,
    this.caloriesPer100g,
    this.proteinPer100g,
    this.carbohydratesPer100g,
    this.fatPer100g,
    this.fibrePer100g,
    this.sugarPer100g,
    this.saturatedFatPer100g,
    this.servingSizes = const [],
    this.isPackagedFood = false,
    this.isRaw,
    this.isCooked,
    this.cachedAt,
    this.defaultServingGrams = 100,
  });

  final String name;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String servingLabel;

  final String? foodId;
  final String? brandName;
  final FoodSource source;
  final String? sourceFoodId;
  final String? barcode;
  final String? foodCategory;
  final String? imageUrl;
  final String? dataType;

  final double? caloriesPer100g;
  final double? proteinPer100g;
  final double? carbohydratesPer100g;
  final double? fatPer100g;
  final double? fibrePer100g;
  final double? sugarPer100g;
  final double? saturatedFatPer100g;

  final List<ServingSize> servingSizes;
  final bool isPackagedFood;
  final bool? isRaw;
  final bool? isCooked;
  final DateTime? cachedAt;
  final double defaultServingGrams;

  String get cacheKey =>
      foodId ?? '${source.name}:${sourceFoodId ?? name.toLowerCase()}';

  bool get hasPer100g =>
      caloriesPer100g != null ||
      (proteinPer100g != null &&
          carbohydratesPer100g != null &&
          fatPer100g != null);

  FoodItem scaled(double multiplier) {
    return FoodItem(
      name: displayName,
      calories: (calories * multiplier).round(),
      proteinG: proteinG * multiplier,
      carbsG: carbsG * multiplier,
      fatG: fatG * multiplier,
      servingLabel: servingLabel,
      foodId: foodId,
      brandName: brandName,
      source: source,
      sourceFoodId: sourceFoodId,
      barcode: barcode,
      foodCategory: foodCategory,
      imageUrl: imageUrl,
      dataType: dataType,
      caloriesPer100g: caloriesPer100g,
      proteinPer100g: proteinPer100g,
      carbohydratesPer100g: carbohydratesPer100g,
      fatPer100g: fatPer100g,
      fibrePer100g: fibrePer100g,
      sugarPer100g: sugarPer100g,
      saturatedFatPer100g: saturatedFatPer100g,
      servingSizes: servingSizes,
      isPackagedFood: isPackagedFood,
      isRaw: isRaw,
      isCooked: isCooked,
      cachedAt: cachedAt,
      defaultServingGrams: defaultServingGrams,
    );
  }

  String get displayName {
    if (brandName != null && brandName!.trim().isNotEmpty) {
      return '$brandName — $name';
    }
    return name;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'calories': calories,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        'servingLabel': servingLabel,
        'foodId': foodId,
        'brandName': brandName,
        'source': source.name,
        'sourceFoodId': sourceFoodId,
        'barcode': barcode,
        'foodCategory': foodCategory,
        'imageUrl': imageUrl,
        'dataType': dataType,
        'caloriesPer100g': caloriesPer100g,
        'proteinPer100g': proteinPer100g,
        'carbohydratesPer100g': carbohydratesPer100g,
        'fatPer100g': fatPer100g,
        'fibrePer100g': fibrePer100g,
        'sugarPer100g': sugarPer100g,
        'saturatedFatPer100g': saturatedFatPer100g,
        'servingSizes': servingSizes.map((s) => s.toJson()).toList(),
        'isPackagedFood': isPackagedFood,
        'isRaw': isRaw,
        'isCooked': isCooked,
        'cachedAt': cachedAt?.toIso8601String(),
        'defaultServingGrams': defaultServingGrams,
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'] as String,
      calories: json['calories'] as int,
      proteinG: (json['proteinG'] as num).toDouble(),
      carbsG: (json['carbsG'] as num).toDouble(),
      fatG: (json['fatG'] as num).toDouble(),
      servingLabel: json['servingLabel'] as String? ?? '1 serving',
      foodId: json['foodId'] as String?,
      brandName: json['brandName'] as String?,
      source: FoodSource.fromJson(json['source'] as String? ?? 'catalog'),
      sourceFoodId: json['sourceFoodId'] as String?,
      barcode: json['barcode'] as String?,
      foodCategory: json['foodCategory'] as String?,
      imageUrl: json['imageUrl'] as String?,
      dataType: json['dataType'] as String?,
      caloriesPer100g: (json['caloriesPer100g'] as num?)?.toDouble(),
      proteinPer100g: (json['proteinPer100g'] as num?)?.toDouble(),
      carbohydratesPer100g: (json['carbohydratesPer100g'] as num?)?.toDouble(),
      fatPer100g: (json['fatPer100g'] as num?)?.toDouble(),
      fibrePer100g: (json['fibrePer100g'] as num?)?.toDouble(),
      sugarPer100g: (json['sugarPer100g'] as num?)?.toDouble(),
      saturatedFatPer100g: (json['saturatedFatPer100g'] as num?)?.toDouble(),
      servingSizes: (json['servingSizes'] as List<dynamic>?)
              ?.map((e) => ServingSize.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isPackagedFood: json['isPackagedFood'] as bool? ?? false,
      isRaw: json['isRaw'] as bool?,
      isCooked: json['isCooked'] as bool?,
      cachedAt: json['cachedAt'] != null
          ? DateTime.tryParse(json['cachedAt'] as String)
          : null,
      defaultServingGrams:
          (json['defaultServingGrams'] as num?)?.toDouble() ?? 100,
    );
  }

  FoodItem copyWith({
    String? name,
    int? calories,
    double? proteinG,
    double? carbsG,
    double? fatG,
    String? servingLabel,
    FoodSource? source,
    List<ServingSize>? servingSizes,
    DateTime? cachedAt,
    double? defaultServingGrams,
  }) {
    return FoodItem(
      name: name ?? this.name,
      calories: calories ?? this.calories,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      servingLabel: servingLabel ?? this.servingLabel,
      foodId: foodId,
      brandName: brandName,
      source: source ?? this.source,
      sourceFoodId: sourceFoodId,
      barcode: barcode,
      foodCategory: foodCategory,
      imageUrl: imageUrl,
      dataType: dataType,
      caloriesPer100g: caloriesPer100g,
      proteinPer100g: proteinPer100g,
      carbohydratesPer100g: carbohydratesPer100g,
      fatPer100g: fatPer100g,
      fibrePer100g: fibrePer100g,
      sugarPer100g: sugarPer100g,
      saturatedFatPer100g: saturatedFatPer100g,
      servingSizes: servingSizes ?? this.servingSizes,
      isPackagedFood: isPackagedFood,
      isRaw: isRaw,
      isCooked: isCooked,
      cachedAt: cachedAt ?? this.cachedAt,
      defaultServingGrams: defaultServingGrams ?? this.defaultServingGrams,
    );
  }
}