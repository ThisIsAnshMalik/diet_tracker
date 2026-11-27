import 'dart:convert';

import 'package:diet_tracker/data/diet_storage.dart';
import 'package:diet_tracker/data/food_cache_storage.dart';
import 'package:diet_tracker/data/profile_storage.dart';
import 'package:diet_tracker/repositories/nutrition_repository.dart';
import 'package:diet_tracker/logic/calorie_calculator.dart';
import 'package:diet_tracker/main.dart';
import 'package:diet_tracker/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Today dashboard smoke test', (WidgetTester tester) async {
    final profile = CalorieCalculator.toProfile(
      heightCm: 175,
      weightKg: 72,
      age: 30,
      gender: Gender.male,
      activity: ActivityLevel.moderate,
      goal: WeightGoal.maintain,
    );
    SharedPreferences.setMockInitialValues({
      'onboarding_complete': true,
      'user_profile': jsonEncode(profile.toJson()),
    });

    final dietStorage = await DietStorage.create();
    final profileStorage = await ProfileStorage.create();
    final foodCache = await FoodCacheStorage.create();
    final nutritionRepository = NutritionRepository(cache: foodCache);

    await tester.pumpWidget(
      DietTrackerApp(
        dietStorage: dietStorage,
        profileStorage: profileStorage,
        nutritionRepository: nutritionRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('View diary'), findsOneWidget);
    expect(find.text('Breakfast'), findsOneWidget);
  });
}