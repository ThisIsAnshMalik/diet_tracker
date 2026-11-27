import 'package:diet_tracker/data/diet_storage.dart';
import 'package:diet_tracker/data/food_cache_storage.dart';
import 'package:diet_tracker/data/profile_storage.dart';
import 'package:diet_tracker/repositories/nutrition_repository.dart';
import 'package:diet_tracker/screens/main_shell.dart';
import 'package:diet_tracker/screens/onboarding/onboarding_flow.dart';
import 'package:diet_tracker/theme/mfp_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dietStorage = await DietStorage.create();
  final profileStorage = await ProfileStorage.create();
  final foodCache = await FoodCacheStorage.create();
  final nutritionRepository = NutritionRepository(cache: foodCache);
  runApp(
    DietTrackerApp(
      dietStorage: dietStorage,
      profileStorage: profileStorage,
      nutritionRepository: nutritionRepository,
    ),
  );
}

class DietTrackerApp extends StatefulWidget {
  const DietTrackerApp({
    super.key,
    required this.dietStorage,
    required this.profileStorage,
    required this.nutritionRepository,
  });

  final DietStorage dietStorage;
  final ProfileStorage profileStorage;
  final NutritionRepository nutritionRepository;

  @override
  State<DietTrackerApp> createState() => _DietTrackerAppState();
}

class _DietTrackerAppState extends State<DietTrackerApp> {
  late bool _onboarded = widget.profileStorage.isOnboardingComplete;

  void _onOnboardingComplete() {
    setState(() => _onboarded = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diary',
      theme: buildMfpTheme(),
      home: _onboarded
          ? MainShell(
              storage: widget.dietStorage,
              profileStorage: widget.profileStorage,
              nutritionRepository: widget.nutritionRepository,
            )
          : OnboardingFlow(
              profileStorage: widget.profileStorage,
              onComplete: _onOnboardingComplete,
            ),
      builder: (context, child) {
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        );
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
