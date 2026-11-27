import 'package:flutter/material.dart';

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get label => switch (this) {
        MealType.breakfast => 'Breakfast',
        MealType.lunch => 'Lunch',
        MealType.dinner => 'Dinner',
        MealType.snack => 'Snacks',
      };

  IconData get icon => switch (this) {
        MealType.breakfast => Icons.free_breakfast_outlined,
        MealType.lunch => Icons.lunch_dining_outlined,
        MealType.dinner => Icons.dinner_dining_outlined,
        MealType.snack => Icons.cookie_outlined,
      };

  static MealType fromJson(String value) => MealType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => MealType.snack,
      );
}