import 'package:diet_tracker/data/diet_storage.dart';
import 'package:diet_tracker/data/profile_storage.dart';
import 'package:diet_tracker/screens/edit_goals_screen.dart';
import 'package:diet_tracker/models/food_entry.dart';
import 'package:diet_tracker/models/meal_type.dart';
import 'package:diet_tracker/theme/mfp_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({
    super.key,
    required this.storage,
    required this.profileStorage,
    required this.onLogMeal,
    required this.onOpenMeal,
    required this.onViewDiary,
  });

  final DietStorage storage;
  final ProfileStorage profileStorage;
  final void Function({MealType meal}) onLogMeal;
  final void Function(MealType meal) onOpenMeal;
  final VoidCallback onViewDiary;

  @override
  State<TodayScreen> createState() => TodayScreenState();
}

class TodayScreenState extends State<TodayScreen> {
  List<FoodEntry> _today = [];

  @override
  void initState() {
    super.initState();
    reload();
  }

  void reload() {
    final all = widget.storage.loadAll();
    setState(() {
      _today = widget.storage.entriesForDate(DateTime.now(), all);
    });
  }

  Future<void> _openEditGoals() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            EditGoalsScreen(profileStorage: widget.profileStorage),
      ),
    );
    if (saved == true) reload();
  }

  @override
  Widget build(BuildContext context) {
    final calories = _today.fold<int>(0, (s, e) => s + e.calories);
    final carbs = _today.fold<double>(0, (s, e) => s + e.carbsG);
    final fat = _today.fold<double>(0, (s, e) => s + e.fatG);
    final protein = _today.fold<double>(0, (s, e) => s + e.proteinG);
    final profile = widget.profileStorage.profileOrDefault;
    final calorieGoal = profile.calorieGoal;
    final left = calorieGoal - calories;
    final calProgress =
        (calories / calorieGoal).clamp(0.0, 1.0).toDouble();

    return SafeArea(
      child: RefreshIndicator(
        color: MfpColors.primary,
        onRefresh: () async => reload(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            Row(
              children: [
                Text(
                  'Today',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                const Spacer(),
                GestureDetector(
                  onTap: _openEditGoals,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: MfpColors.premium,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Text(
                      'Goals',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: mfpCardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calories',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$calories cal',
                        style: GoogleFonts.inter(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        ' / $calorieGoal',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: MfpColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${left.abs()} ${left >= 0 ? 'left' : 'over'}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: MfpColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: calProgress,
                      minHeight: 6,
                      backgroundColor: MfpColors.border,
                      color: MfpColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: mfpCardDecoration(),
              child: Row(
                children: [
                  _MacroStat(
                    label: 'Carbs',
                    value: carbs,
                    goal: profile.carbsG,
                    color: MfpColors.carbs,
                  ),
                  _MacroStat(
                    label: 'Fat',
                    value: fat,
                    goal: profile.fatG,
                    color: MfpColors.fat,
                  ),
                  _MacroStat(
                    label: 'Protein',
                    value: protein,
                    goal: profile.proteinG,
                    color: MfpColors.protein,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Meals',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: widget.onViewDiary,
                  child: Text(
                    'View diary',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: MfpColors.primaryText,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final meal in MealType.values)
              _MealRow(
                meal: meal,
                entries: _today.where((e) => e.mealType == meal).toList(),
                onTap: () => widget.onOpenMeal(meal),
                onLog: () => widget.onLogMeal(meal: meal),
              ),
          ],
        ),
      ),
    );
  }
}

class _MacroStat extends StatelessWidget {
  const _MacroStat({
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });

  final String label;
  final double value;
  final double goal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: MfpColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(fontSize: 15),
              children: [
                TextSpan(
                  text: '${value.toStringAsFixed(0)}g',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: ' / ${goal.toStringAsFixed(0)}',
                  style: const TextStyle(color: MfpColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: p,
              minHeight: 4,
              backgroundColor: MfpColors.border,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({
    required this.meal,
    required this.entries,
    required this.onTap,
    required this.onLog,
  });

  final MealType meal;
  final List<FoodEntry> entries;
  final VoidCallback onTap;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    final cals = entries.fold(0, (s, e) => s + e.calories);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: mfpCardDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(meal.icon, color: MfpColors.primaryText, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.label,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (entries.isNotEmpty)
                        Text(
                          '$cals cal logged',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: MfpColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onLog,
                  style: TextButton.styleFrom(
                    backgroundColor: MfpColors.logPillBg,
                    foregroundColor: MfpColors.primaryText,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                  child: Text(
                    entries.isEmpty ? 'Log food' : 'Log more',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}