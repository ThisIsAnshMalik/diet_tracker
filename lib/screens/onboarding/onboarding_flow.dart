import 'package:diet_tracker/data/profile_storage.dart';
import 'package:diet_tracker/logic/calorie_calculator.dart';
import 'package:diet_tracker/models/user_profile.dart';
import 'package:diet_tracker/theme/mfp_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({
    super.key,
    required this.profileStorage,
    required this.onComplete,
  });

  final ProfileStorage profileStorage;
  final VoidCallback onComplete;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  static const _stepCount = 7;
  int _step = 0;

  double _heightCm = 170;
  double _weightKg = 70;
  int _age = 28;
  Gender _gender = Gender.male;
  ActivityLevel _activity = ActivityLevel.light;
  WeightGoal _goal = WeightGoal.maintain;

  CaloriePlan? _plan;

  void _next() {
    if (_step < _stepCount - 2) {
      setState(() => _step++);
      return;
    }
    if (_step == _stepCount - 2) {
      setState(() {
        _plan = CalorieCalculator.buildPlan(
          heightCm: _heightCm,
          weightKg: _weightKg,
          age: _age,
          gender: _gender,
          activity: _activity,
          goal: _goal,
        );
        _step++;
      });
      return;
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _finish() async {
    final profile = CalorieCalculator.toProfile(
      heightCm: _heightCm,
      weightKg: _weightKg,
      age: _age,
      gender: _gender,
      activity: _activity,
      goal: _goal,
    );
    await widget.profileStorage.saveProfile(profile);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MfpColors.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  if (_step > 0 && _step < _stepCount - 1)
                    IconButton(
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: _StepDots(current: _step, total: _stepCount),
                  ),
                  Text(
                    '${_step + 1}/$_stepCount',
                    style: GoogleFonts.inter(
                      color: MfpColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _buildStep(),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => _StepHeight(
          key: const ValueKey(0),
          value: _heightCm,
          onChanged: (v) => setState(() => _heightCm = v),
        ),
      1 => _StepWeight(
          key: const ValueKey(1),
          value: _weightKg,
          onChanged: (v) => setState(() => _weightKg = v),
        ),
      2 => _StepAge(
          key: const ValueKey(2),
          value: _age,
          onChanged: (v) => setState(() => _age = v),
        ),
      3 => _StepGender(
          key: const ValueKey(3),
          value: _gender,
          onChanged: (v) => setState(() => _gender = v),
        ),
      4 => _StepActivity(
          key: const ValueKey(4),
          value: _activity,
          onChanged: (v) => setState(() => _activity = v),
        ),
      5 => _StepGoal(
          key: const ValueKey(5),
          value: _goal,
          onChanged: (v) => setState(() => _goal = v),
        ),
      _ => _StepPlan(
          key: const ValueKey(6),
          plan: _plan!,
          weightKg: _weightKg,
          heightCm: _heightCm,
        ),
    };
  }

  Widget _buildBottomBar() {
    final isLast = _step == _stepCount - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: FilledButton(
        onPressed: isLast ? _finish : _next,
        style: FilledButton.styleFrom(
          backgroundColor: MfpColors.premium,
          foregroundColor: Colors.black87,
          minimumSize: const Size.fromHeight(54),
        ),
        child: Text(
          isLast ? 'Start tracking' : 'Continue',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          Container(
            width: i == current ? 22 : 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: i <= current ? MfpColors.primary : MfpColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _StepShell extends StatelessWidget {
  const _StepShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: MfpColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        child,
      ],
    );
  }
}

class _StepHeight extends StatelessWidget {
  const _StepHeight({super.key, required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final feet = (value / 30.48).floor();
    final inches = ((value / 2.54) % 12).round();

    return _StepShell(
      title: "What's your height?",
      subtitle: 'Used for BMI and calorie estimates.',
      child: _MetricSliderCard(
        bigValue: '${value.toStringAsFixed(0)} cm',
        helper: "About $feet'$inches\"",
        min: 130,
        max: 210,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _StepWeight extends StatelessWidget {
  const _StepWeight({super.key, required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final lbs = (value * 2.205).round();
    return _StepShell(
      title: "What's your weight?",
      subtitle: 'Be honest — your goals work best with accurate data.',
      child: _MetricSliderCard(
        bigValue: '${value.toStringAsFixed(1)} kg',
        helper: 'About $lbs lb',
        min: 40,
        max: 160,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _StepAge extends StatelessWidget {
  const _StepAge({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      title: 'How old are you?',
      subtitle: 'Age affects your basal metabolic rate.',
      child: _MetricSliderCard(
        bigValue: '$value',
        helper: 'years old',
        min: 16,
        max: 80,
        value: value.toDouble(),
        divisions: 64,
        onChanged: (v) => onChanged(v.round()),
      ),
    );
  }
}

class _StepGender extends StatelessWidget {
  const _StepGender({super.key, required this.value, required this.onChanged});

  final Gender value;
  final ValueChanged<Gender> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      title: "What's your gender?",
      subtitle: 'Used for the Mifflin–St Jeor calorie formula.',
      child: Column(
        children: [
          _OptionCard(
            label: 'Male',
            selected: value == Gender.male,
            onTap: () => onChanged(Gender.male),
          ),
          _OptionCard(
            label: 'Female',
            selected: value == Gender.female,
            onTap: () => onChanged(Gender.female),
          ),
          _OptionCard(
            label: 'Prefer not to say',
            selected: value == Gender.other,
            onTap: () => onChanged(Gender.other),
          ),
        ],
      ),
    );
  }
}

class _StepActivity extends StatelessWidget {
  const _StepActivity({super.key, required this.value, required this.onChanged});

  final ActivityLevel value;
  final ValueChanged<ActivityLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      title: 'Workout routine',
      subtitle: 'How active are you on a typical week?',
      child: Column(
        children: [
          for (final a in ActivityLevel.values)
            _OptionCard(
              label: a.label,
              subtitle: a.description,
              selected: value == a,
              onTap: () => onChanged(a),
            ),
        ],
      ),
    );
  }
}

class _StepGoal extends StatelessWidget {
  const _StepGoal({super.key, required this.value, required this.onChanged});

  final WeightGoal value;
  final ValueChanged<WeightGoal> onChanged;

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      title: 'Your goal',
      subtitle: "We'll adjust calories below or above maintenance.",
      child: Column(
        children: [
          for (final g in WeightGoal.values)
            _OptionCard(
              label: g.label,
              selected: value == g,
              onTap: () => onChanged(g),
            ),
        ],
      ),
    );
  }
}

class _StepPlan extends StatelessWidget {
  const _StepPlan({
    super.key,
    required this.plan,
    required this.weightKg,
    required this.heightCm,
  });

  final CaloriePlan plan;
  final double weightKg;
  final double heightCm;

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      title: 'Your daily plan',
      subtitle:
          'Based on BMI (${plan.bmi.toStringAsFixed(1)} — ${plan.bmiLabel}), '
          'activity level, and goal.',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: mfpCardDecoration(),
            child: Column(
              children: [
                Text(
                  '${plan.calorieGoal}',
                  style: GoogleFonts.inter(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: MfpColors.primaryText,
                  ),
                ),
                Text(
                  'calories / day',
                  style: GoogleFonts.inter(color: MfpColors.textSecondary),
                ),
                const SizedBox(height: 12),
                Text(
                  'Maintenance ~${plan.tdee.round()} cal • BMR ${plan.bmr.round()}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: MfpColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MacroGoalCard(
                  label: 'Carbs',
                  grams: plan.carbsG,
                  color: MfpColors.carbs,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MacroGoalCard(
                  label: 'Fat',
                  grams: plan.fatG,
                  color: MfpColors.fat,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MacroGoalCard(
                  label: 'Protein',
                  grams: plan.proteinG,
                  color: MfpColors.protein,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroGoalCard extends StatelessWidget {
  const _MacroGoalCard({
    required this.label,
    required this.grams,
    required this.color,
  });

  final String label;
  final double grams;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: mfpCardDecoration(),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${grams.round()}g',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricSliderCard extends StatelessWidget {
  const _MetricSliderCard({
    required this.bigValue,
    required this.helper,
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    this.divisions,
  });

  final String bigValue;
  final String helper;
  final double min;
  final double max;
  final double value;
  final ValueChanged<double> onChanged;
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      decoration: mfpCardDecoration(),
      child: Column(
        children: [
          Text(
            bigValue,
            style: GoogleFonts.inter(
              fontSize: 44,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            helper,
            style: GoogleFonts.inter(color: MfpColors.textMuted),
          ),
          const SizedBox(height: 20),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions ?? (max - min).round(),
            activeColor: MfpColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? MfpColors.primary.withValues(alpha: 0.12)
            : MfpColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.md),
              border: Border.all(
                color: selected ? MfpColors.primary : MfpColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: MfpColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle, color: MfpColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}