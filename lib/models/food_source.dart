enum FoodSource {
  catalog,
  local,
  usda,
  openFoodFacts;

  String get label => switch (this) {
        FoodSource.catalog => 'catalog',
        FoodSource.local => 'local',
        FoodSource.usda => 'USDA',
        FoodSource.openFoodFacts => 'Open Food Facts',
      };

  static FoodSource fromJson(String value) => FoodSource.values.firstWhere(
        (e) => e.name == value,
        orElse: () => FoodSource.local,
      );
}