/// USDA FoodData Central nutrient IDs (per 100g in detail responses).
abstract final class UsdaNutrientId {
  static const energyKcal = 1008;
  static const energyKcalAlt = 2047;
  static const protein = 1003;
  static const carbs = 1005;
  static const fat = 1004;
  static const fibre = 1079;
  static const sugars = 2000;
  static const saturatedFat = 1258;
}

class UsdaNutrients {
  const UsdaNutrients({
    this.caloriesPer100g,
    this.proteinPer100g,
    this.carbohydratesPer100g,
    this.fatPer100g,
    this.fibrePer100g,
    this.sugarPer100g,
    this.saturatedFatPer100g,
  });

  final double? caloriesPer100g;
  final double? proteinPer100g;
  final double? carbohydratesPer100g;
  final double? fatPer100g;
  final double? fibrePer100g;
  final double? sugarPer100g;
  final double? saturatedFatPer100g;

  bool get hasCoreMacros =>
      proteinPer100g != null ||
      carbohydratesPer100g != null ||
      fatPer100g != null ||
      caloriesPer100g != null;
}

UsdaNutrients parseUsdaNutrients(List<dynamic>? rawList) {
  if (rawList == null || rawList.isEmpty) return const UsdaNutrients();

  double? pick(int id) {
    for (final raw in rawList) {
      final map = raw as Map<String, dynamic>;
      final nutrient = map['nutrient'] as Map<String, dynamic>?;
      final nutrientId = nutrient?['id'] as int? ?? map['nutrientId'] as int?;
      if (nutrientId != id) continue;
      final value = map['value'] ?? map['amount'];
      if (value is num) return value.toDouble();
    }
    return null;
  }

  var kcal = pick(UsdaNutrientId.energyKcal);
  kcal ??= pick(UsdaNutrientId.energyKcalAlt);

  return UsdaNutrients(
    caloriesPer100g: kcal,
    proteinPer100g: pick(UsdaNutrientId.protein),
    carbohydratesPer100g: pick(UsdaNutrientId.carbs),
    fatPer100g: pick(UsdaNutrientId.fat),
    fibrePer100g: pick(UsdaNutrientId.fibre),
    sugarPer100g: pick(UsdaNutrientId.sugars),
    saturatedFatPer100g: pick(UsdaNutrientId.saturatedFat),
  );
}

bool? inferRawCooked(String description, String? category) {
  final text = '${description.toLowerCase()} ${category?.toLowerCase() ?? ''}';
  if (text.contains('raw') && !text.contains('cooked')) return true;
  if (text.contains('cooked') ||
      text.contains('boiled') ||
      text.contains('baked') ||
      text.contains('roasted')) {
    return false;
  }
  return null;
}