import 'package:diet_tracker/models/food_item.dart';
import 'package:diet_tracker/models/serving_size.dart';

class NutritionTotals {
  const NutritionTotals({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fibreG,
    this.sugarG,
    this.saturatedFatG,
    this.grams,
  });

  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? fibreG;
  final double? sugarG;
  final double? saturatedFatG;
  final double? grams;
}

abstract final class NutritionCalculator {
  /// Nutrition for a weight in grams using per-100g reference values.
  static NutritionTotals forGrams(FoodItem food, double grams) {
    if (grams <= 0) {
      return const NutritionTotals(
        calories: 0,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
        grams: 0,
      );
    }
    final factor = grams / 100;
  return NutritionTotals(
      calories: _scale(food.caloriesPer100g, factor).round(),
      proteinG: _scale(food.proteinPer100g, factor),
      carbsG: _scale(food.carbohydratesPer100g, factor),
      fatG: _scale(food.fatPer100g, factor),
      fibreG: food.fibrePer100g != null
          ? _scale(food.fibrePer100g, factor)
          : null,
      sugarG:
          food.sugarPer100g != null ? _scale(food.sugarPer100g, factor) : null,
      saturatedFatG: food.saturatedFatPer100g != null
          ? _scale(food.saturatedFatPer100g, factor)
          : null,
      grams: grams,
    );
  }

  /// [servings] × selected [portion]'s gram weight, or item default grams.
  static NutritionTotals forPortions(
    FoodItem food, {
    required ServingSize portion,
    required double servings,
  }) {
    final grams = portion.gramWeight;
    if (grams == null || grams <= 0) {
      if (food.hasPer100g) {
        return forGrams(food, food.defaultServingGrams * servings);
      }
      return NutritionTotals(
        calories: (food.calories * servings).round(),
        proteinG: food.proteinG * servings,
        carbsG: food.carbsG * servings,
        fatG: food.fatG * servings,
      );
    }
    return forGrams(food, grams * servings);
  }

  static FoodItem withDisplayForGrams(FoodItem food, double grams) {
    if (!food.hasPer100g) {
      final mult = grams / (food.defaultServingGrams > 0
          ? food.defaultServingGrams
          : 100);
      return food.scaled(mult);
    }
    final t = forGrams(food, grams);
    return food.copyWith(
      calories: t.calories,
      proteinG: t.proteinG,
      carbsG: t.carbsG,
      fatG: t.fatG,
      servingLabel: '${grams.toStringAsFixed(grams == grams.roundToDouble() ? 0 : 1)} g',
      defaultServingGrams: grams,
    );
  }

  static FoodItem withDefaultServingDisplay(FoodItem food) {
    final defaultPortion = food.servingSizes.isNotEmpty
        ? food.servingSizes.firstWhere(
            (s) => s.gramWeight != null && s.gramWeight != 100,
            orElse: () => food.servingSizes.first,
          )
        : ServingSize(
            label: food.servingLabel,
            gramWeight: food.defaultServingGrams,
          );

    if (food.hasPer100g && defaultPortion.gramWeight != null) {
      final t = forPortions(food, portion: defaultPortion, servings: 1);
      return food.copyWith(
        calories: t.calories,
        proteinG: t.proteinG,
        carbsG: t.carbsG,
        fatG: t.fatG,
        servingLabel: defaultPortion.label,
        defaultServingGrams: defaultPortion.gramWeight!,
      );
    }
    return food;
  }

  static double _scale(double? per100g, double factor) =>
      (per100g ?? 0) * factor;
}