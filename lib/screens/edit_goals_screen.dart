import 'package:diet_tracker/data/profile_storage.dart';
import 'package:diet_tracker/logic/calorie_calculator.dart';
import 'package:diet_tracker/models/user_profile.dart';
import 'package:diet_tracker/theme/mfp_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditGoalsScreen extends StatefulWidget {
  const EditGoalsScreen({super.key, required this.profileStorage});

  final ProfileStorage profileStorage;

  @override
  State<EditGoalsScreen> createState() => _EditGoalsScreenState();
}

class _EditGoalsScreenState extends State<EditGoalsScreen> {
  late double _heightCm;
  late double _weightKg;
  late int _age;
  late Gender _gender;
  late ActivityLevel _activity;
  late WeightGoal _goal;
  late bool _useCustomCalories;
  late int _customCalories;

  CaloriePlan get _plan => CalorieCalculator.buildPlan(
        heightCm: _heightCm,
        weightKg: _weightKg,
        age: _age,
        gender: _gender,
        activity: _activity,
        goal: _goal,
      );

  int get _displayCalories =>
      _useCustomCalories ? _customCalories : _plan.calorieGoal;

  ({double proteinG, double carbsG, double fatG}) get _displayMacros =>
      CalorieCalculator.macrosForCalories(_displayCalories);

  @override
  void initState() {
    super.initState();
    final p = widget.profileStorage.profileOrDefault;
    _heightCm = p.heightCm;
    _weightKg = p.weightKg;
    _age = p.age;
    _gender = p.gender;
    _activity = p.activity;
    _goal = p.goal;
    _useCustomCalories = p.useCustomCalories;
    _customCalories = p.calorieGoal;
  }

  Future<void> _save() async {
    final profile = CalorieCalculator.toProfile(
      heightCm: _heightCm,
      weightKg: _weightKg,
      age: _age,
      gender: _gender,
      activity: _activity,
      goal: _goal,
      useCustomCalories: _useCustomCalories,
      customCalorieGoal: _customCalories,
    );
    await widget.profileStorage.saveProfile(profile);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final macros = _displayMacros;
    final subtitle = _useCustomCalories
        ? 'Custom calorie goal • suggested ${_plan.calorieGoal} from your stats'
        : 'BMI ${plan.bmi.toStringAsFixed(1)} (${plan.bmiLabel}) • '
            'TDEE ~${plan.tdee.round()}';

    return Scaffold(
      backgroundColor: MfpColors.scaffold,
      appBar: AppBar(
        title: Text(
          'Edit goals',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: mfpCardDecoration(),
            child: Column(
              children: [
                Text(
                  '$_displayCalories',
                  style: GoogleFonts.inter(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: MfpColors.primaryText,
                  ),
                ),
                Text(
                  'calories / day',
                  style: GoogleFonts.inter(color: MfpColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: MfpColors.textMuted,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _miniMacro('C', macros.carbsG, MfpColors.carbs),
                    _miniMacro('F', macros.fatG, MfpColors.fat),
                    _miniMacro('P', macros.proteinG, MfpColors.protein),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            decoration: mfpCardDecoration(),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Custom calorie goal',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _useCustomCalories
                        ? 'Set your own daily target'
                        : 'Use calculated goal from body & activity',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: MfpColors.textMuted,
                    ),
                  ),
                  value: _useCustomCalories,
                  activeTrackColor: MfpColors.primary.withValues(alpha: 0.5),
                  activeThumbColor: MfpColors.primary,
                  onChanged: (v) {
                    setState(() {
                      _useCustomCalories = v;
                      if (v) _customCalories = _plan.calorieGoal;
                    });
                  },
                ),
                if (_useCustomCalories)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Daily calories',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '$_customCalories',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                color: MfpColors.primaryText,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _customCalories.clamp(1200, 4500).toDouble(),
                          min: 1200,
                          max: 4500,
                          divisions: 66,
                          label: '$_customCalories',
                          activeColor: MfpColors.primary,
                          onChanged: (v) =>
                              setState(() => _customCalories = v.round()),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '1200',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: MfpColors.textMuted,
                              ),
                            ),
                            Text(
                              '4500',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: MfpColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Body'),
          _sliderTile(
            label: 'Height',
            value: '${_heightCm.toStringAsFixed(0)} cm',
            child: Slider(
              value: _heightCm.clamp(130, 210),
              min: 130,
              max: 210,
              divisions: 80,
              activeColor: MfpColors.primary,
              onChanged: (v) => setState(() => _heightCm = v),
            ),
          ),
          _sliderTile(
            label: 'Weight',
            value: '${_weightKg.toStringAsFixed(1)} kg',
            child: Slider(
              value: _weightKg.clamp(40, 160),
              min: 40,
              max: 160,
              divisions: 120,
              activeColor: MfpColors.primary,
              onChanged: (v) => setState(() => _weightKg = v),
            ),
          ),
          _sliderTile(
            label: 'Age',
            value: '$_age years',
            child: Slider(
              value: _age.toDouble().clamp(16, 80),
              min: 16,
              max: 80,
              divisions: 64,
              activeColor: MfpColors.primary,
              onChanged: (v) => setState(() => _age = v.round()),
            ),
          ),
          const SizedBox(height: 8),
          _sectionTitle('Gender'),
          _chipRow<Gender>(
            values: Gender.values,
            selected: _gender,
            label: (g) => g.label,
            onSelect: (g) => setState(() => _gender = g),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Activity'),
          _chipRow<ActivityLevel>(
            values: ActivityLevel.values,
            selected: _activity,
            label: (a) => a.label,
            onSelect: (a) => setState(() => _activity = a),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Goal'),
          _chipRow<WeightGoal>(
            values: WeightGoal.values,
            selected: _goal,
            label: (g) => g.label,
            onSelect: (g) => setState(() => _goal = g),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              backgroundColor: MfpColors.premium,
              foregroundColor: Colors.black87,
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(
              'Save goals',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: MfpColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _sliderTile({
    required String label,
    required String value,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: mfpCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: MfpColors.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }

  Widget _chipRow<T>({
    required List<T> values,
    required T selected,
    required String Function(T) label,
    required ValueChanged<T> onSelect,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final v in values)
          FilterChip(
            label: Text(label(v)),
            selected: v == selected,
            onSelected: (_) => onSelect(v),
            selectedColor: MfpColors.primary,
            backgroundColor: MfpColors.surface,
            checkmarkColor: Colors.white,
            labelStyle: TextStyle(
              color: v == selected ? Colors.white : MfpColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            side: BorderSide(
              color: v == selected ? MfpColors.primary : MfpColors.border,
            ),
            showCheckmark: false,
          ),
      ],
    );
  }

  Widget _miniMacro(String letter, double g, Color color) {
    return Column(
      children: [
        Text(
          letter,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          '${g.round()}g',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}