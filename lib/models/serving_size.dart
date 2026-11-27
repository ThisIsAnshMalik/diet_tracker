/// A portion or serving with an optional gram weight for nutrition math.
class ServingSize {
  const ServingSize({
    required this.label,
    this.gramWeight,
    this.unit = ServingUnit.standard,
    this.isEstimated = false,
  });

  final String label;
  final double? gramWeight;
  final ServingUnit unit;
  final bool isEstimated;

  Map<String, dynamic> toJson() => {
        'label': label,
        'gramWeight': gramWeight,
        'unit': unit.name,
        'isEstimated': isEstimated,
      };

  factory ServingSize.fromJson(Map<String, dynamic> json) {
    return ServingSize(
      label: json['label'] as String,
      gramWeight: (json['gramWeight'] as num?)?.toDouble(),
      unit: ServingUnit.fromJson(json['unit'] as String? ?? 'standard'),
      isEstimated: json['isEstimated'] as bool? ?? false,
    );
  }

  static const per100g = ServingSize(
    label: '100 g',
    gramWeight: 100,
    unit: ServingUnit.gram,
  );
}

enum ServingUnit {
  gram,
  kilogram,
  millilitre,
  litre,
  piece,
  bowl,
  cup,
  tablespoon,
  teaspoon,
  standard;

  static ServingUnit fromJson(String value) {
    return ServingUnit.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ServingUnit.standard,
    );
  }
}