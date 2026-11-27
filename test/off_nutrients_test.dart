import 'package:diet_tracker/services/open_food_facts_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses Open Food Facts product nutriments per 100g', () {
    final service = OpenFoodFactsService();
    final item = service.parseProductJson({
      'product_name': 'Test Cereal',
      'brands': 'Acme',
      'code': '1234567890123',
      'nutriments': {
        'energy-kcal_100g': 380,
        'proteins_100g': 8,
        'carbohydrates_100g': 80,
        'fat_100g': 2,
        'fiber_100g': 6,
        'sugars_100g': 18,
        'saturated-fat_100g': 0.5,
        'serving_quantity': 30,
      },
      'serving_size': '30 g',
    });

    expect(item, isNotNull);
    expect(item!.name, 'Test Cereal');
    expect(item.caloriesPer100g, 380);
    expect(item.proteinPer100g, 8);
    expect(item.isPackagedFood, isTrue);
    expect(item.barcode, '1234567890123');
    expect(item.calories, (380 * 0.3).round());
  });
}