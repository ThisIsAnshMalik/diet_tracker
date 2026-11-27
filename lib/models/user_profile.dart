enum Gender {
  male,
  female,
  other;

  String get label => switch (this) {
        Gender.male => 'Male',
        Gender.female => 'Female',
        Gender.other => 'Prefer not to say',
      };

  static Gender fromJson(String v) =>
      Gender.values.firstWhere((g) => g.name == v, orElse: () => Gender.other);

  /// Used for Mifflin–St Jeor (male vs female offset).
  bool get usesMaleBmr => this == Gender.male;
}

enum ActivityLevel {
  sedentary,
  light,
  moderate,
  veryActive;

  String get label => switch (this) {
        ActivityLevel.sedentary => 'Sedentary',
        ActivityLevel.light => 'Lightly active',
        ActivityLevel.moderate => 'Active',
        ActivityLevel.veryActive => 'Very active',
      };

  String get description => switch (this) {
        ActivityLevel.sedentary => 'Little or no exercise',
        ActivityLevel.light => 'Light exercise 1–3 days/week',
        ActivityLevel.moderate => 'Moderate exercise 3–5 days/week',
        ActivityLevel.veryActive => 'Hard exercise 6–7 days/week',
      };

  double get factor => switch (this) {
        ActivityLevel.sedentary => 1.2,
        ActivityLevel.light => 1.375,
        ActivityLevel.moderate => 1.55,
        ActivityLevel.veryActive => 1.725,
      };

  static ActivityLevel fromJson(String v) => ActivityLevel.values
      .firstWhere((a) => a.name == v, orElse: () => ActivityLevel.light);
}

enum WeightGoal {
  lose,
  maintain,
  gain;

  String get label => switch (this) {
        WeightGoal.lose => 'Lose weight',
        WeightGoal.maintain => 'Maintain weight',
        WeightGoal.gain => 'Gain muscle',
      };

  int get calorieAdjustment => switch (this) {
        WeightGoal.lose => -500,
        WeightGoal.maintain => 0,
        WeightGoal.gain => 300,
      };

  static WeightGoal fromJson(String v) =>
      WeightGoal.values.firstWhere((g) => g.name == v, orElse: () => WeightGoal.maintain);
}

class UserProfile {
  UserProfile({
    required this.heightCm,
    required this.weightKg,
    required this.age,
    required this.gender,
    required this.activity,
    required this.goal,
    required this.calorieGoal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.bmi,
    this.useCustomCalories = false,
  });

  final double heightCm;
  final double weightKg;
  final int age;
  final Gender gender;
  final ActivityLevel activity;
  final WeightGoal goal;
  final int calorieGoal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double bmi;
  final bool useCustomCalories;

  Map<String, dynamic> toJson() => {
        'heightCm': heightCm,
        'weightKg': weightKg,
        'age': age,
        'gender': gender.name,
        'activity': activity.name,
        'goal': goal.name,
        'calorieGoal': calorieGoal,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
        'bmi': bmi,
        'useCustomCalories': useCustomCalories,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      heightCm: (json['heightCm'] as num).toDouble(),
      weightKg: (json['weightKg'] as num).toDouble(),
      age: json['age'] as int,
      gender: Gender.fromJson(json['gender'] as String),
      activity: ActivityLevel.fromJson(json['activity'] as String),
      goal: WeightGoal.fromJson(json['goal'] as String),
      calorieGoal: json['calorieGoal'] as int,
      proteinG: (json['proteinG'] as num).toDouble(),
      carbsG: (json['carbsG'] as num).toDouble(),
      fatG: (json['fatG'] as num).toDouble(),
      bmi: (json['bmi'] as num).toDouble(),
      useCustomCalories: json['useCustomCalories'] as bool? ?? false,
    );
  }
}