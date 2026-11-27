class FoodItem {
  const FoodItem({
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.servingLabel = '1 serving',
  });

  final String name;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final String servingLabel;

  FoodItem scaled(double multiplier) {
    return FoodItem(
      name: name,
      calories: (calories * multiplier).round(),
      proteinG: proteinG * multiplier,
      carbsG: carbsG * multiplier,
      fatG: fatG * multiplier,
      servingLabel: servingLabel,
    );
  }
}