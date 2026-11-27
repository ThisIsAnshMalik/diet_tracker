import 'dart:convert';

import 'package:diet_tracker/logic/calorie_calculator.dart';
import 'package:diet_tracker/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileStorage {
  ProfileStorage(this._prefs);

  static const _profileKey = 'user_profile';
  static const _onboardingKey = 'onboarding_complete';

  final SharedPreferences _prefs;

  static Future<ProfileStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ProfileStorage(prefs);
  }

  bool get isOnboardingComplete => _prefs.getBool(_onboardingKey) ?? false;

  UserProfile? loadProfile() {
    final raw = _prefs.getString(_profileKey);
    if (raw == null || raw.isEmpty) return null;
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  UserProfile get profileOrDefault => loadProfile() ?? _defaultProfile();

  static UserProfile _defaultProfile() => CalorieCalculator.toProfile(
        heightCm: 170,
        weightKg: 70,
        age: 30,
        gender: Gender.other,
        activity: ActivityLevel.light,
        goal: WeightGoal.maintain,
      );

  Future<void> saveProfile(UserProfile profile) async {
    await _prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    await _prefs.setBool(_onboardingKey, true);
  }
}