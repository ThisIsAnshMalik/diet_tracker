import 'package:diet_tracker/logic/nutrition_calculator.dart';
import 'package:diet_tracker/models/food_item.dart';
import 'package:diet_tracker/models/serving_size.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const food = FoodItem(
    name: 'Test food',
    calories: 200,
    proteinG: 10,
    carbsG: 20,
    fatG: 5,
    caloriesPer100g: 100,
    proteinPer100g: 5,
    carbohydratesPer100g: 10,
    fatPer100g: 2.5,
    defaultServingGrams: 100,
  );

  test('calculates nutrition for 200g', () {
    final result = NutritionCalculator.forGrams(food, 200);
    expect(result.calories, 200);
    expect(result.proteinG, 10);
    expect(result.carbsG, 20);
    expect(result.fatG, 5);
  });

  test('calculates nutrition for custom serving weight', () {
    const portion = ServingSize(label: '1 cup', gramWeight: 240);
    const rich = FoodItem(
      name: 'Rice',
      calories: 0,
      proteinG: 0,
      carbsG: 0,
      fatG: 0,
      caloriesPer100g: 130,
      proteinPer100g: 2.7,
      carbohydratesPer100g: 28,
      fatPer100g: 0.3,
    );
    final result = NutritionCalculator.forPortions(
      rich,
      portion: portion,
      servings: 1,
    );
    expect(result.calories, (130 * 2.4).round());
    expect(result.carbsG, closeTo(28 * 2.4, 0.01));
  });
}