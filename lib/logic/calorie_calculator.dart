import 'package:diet_tracker/models/user_profile.dart';

class CaloriePlan {
  const CaloriePlan({
    required this.bmi,
    required this.bmiLabel,
    required this.bmr,
    required this.tdee,
    required this.calorieGoal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final double bmi;
  final String bmiLabel;
  final double bmr;
  final double tdee;
  final int calorieGoal;
  final double proteinG;
  final double carbsG;
  final double fatG;
}

abstract final class CalorieCalculator {
  static double bmi({required double weightKg, required double heightCm}) {
    final h = heightCm / 100;
    return weightKg / (h * h);
  }

  static String bmiCategory(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  /// Mifflin–St Jeor BMR; [gender.other] uses female coefficients.
  static double bmr({
    required double weightKg,
    required double heightCm,
    required int age,
    required Gender gender,
  }) {
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return gender.usesMaleBmr ? base + 5 : base - 161;
  }

  static CaloriePlan buildPlan({
    required double heightCm,
    required double weightKg,
    required int age,
    required Gender gender,
    required ActivityLevel activity,
    required WeightGoal goal,
  }) {
    final bmiVal = bmi(weightKg: weightKg, heightCm: heightCm);
    final bmrVal = bmr(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
    );
    final tdeeVal = bmrVal * activity.factor;
    var calories = (tdeeVal + goal.calorieAdjustment).round();
    calories = calories.clamp(1200, 4500);

    const proteinRatio = 0.30;
    const carbsRatio = 0.40;
    const fatRatio = 0.30;

    final proteinG = (calories * proteinRatio) / 4;
    final carbsG = (calories * carbsRatio) / 4;
    final fatG = (calories * fatRatio) / 9;

    return CaloriePlan(
      bmi: bmiVal,
      bmiLabel: bmiCategory(bmiVal),
      bmr: bmrVal,
      tdee: tdeeVal,
      calorieGoal: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
    );
  }

  static UserProfile toProfile({
    required double heightCm,
    required double weightKg,
    required int age,
    required Gender gender,
    required ActivityLevel activity,
    required WeightGoal goal,
  }) {
    final plan = buildPlan(
      heightCm: heightCm,
      weightKg: weightKg,
      age: age,
      gender: gender,
      activity: activity,
      goal: goal,
    );
    return UserProfile(
      heightCm: heightCm,
      weightKg: weightKg,
      age: age,
      gender: gender,
      activity: activity,
      goal: goal,
      calorieGoal: plan.calorieGoal,
      proteinG: plan.proteinG,
      carbsG: plan.carbsG,
      fatG: plan.fatG,
      bmi: plan.bmi,
    );
  }
}