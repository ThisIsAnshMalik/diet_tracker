import 'package:diet_tracker/services/usda_nutrient_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses core USDA nutrients from search payload', () {
    final nutrients = parseUsdaNutrients([
      {
        'nutrientId': 1008,
        'value': 86,
      },
      {
        'nutrientId': 1003,
        'value': 3.1,
      },
      {
        'nutrientId': 1005,
        'value': 20.1,
      },
      {
        'nutrientId': 1004,
        'value': 0.1,
      },
    ]);

    expect(nutrients.caloriesPer100g, 86);
    expect(nutrients.proteinPer100g, 3.1);
    expect(nutrients.carbohydratesPer100g, 20.1);
    expect(nutrients.fatPer100g, 0.1);
    expect(nutrients.hasCoreMacros, isTrue);
  });

  test('infers raw vs cooked', () {
    expect(inferRawCooked('Chicken breast, raw', null), isTrue);
    expect(inferRawCooked('Rice, cooked', null), isFalse);
  });
}