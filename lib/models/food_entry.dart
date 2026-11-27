import 'package:diet_tracker/models/meal_type.dart';

class FoodEntry {
  FoodEntry({
    required this.id,
    required this.name,
    required this.mealType,
    required this.loggedAt,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final String id;
  final String name;
  final MealType mealType;
  final DateTime loggedAt;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mealType': mealType.name,
        'loggedAt': loggedAt.toIso8601String(),
        'calories': calories,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
      };

  factory FoodEntry.fromJson(Map<String, dynamic> json) {
    return FoodEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      mealType: MealType.fromJson(json['mealType'] as String),
      loggedAt: DateTime.parse(json['loggedAt'] as String),
      calories: json['calories'] as int,
      proteinG: (json['proteinG'] as num).toDouble(),
      carbsG: (json['carbsG'] as num).toDouble(),
      fatG: (json['fatG'] as num).toDouble(),
    );
  }
}