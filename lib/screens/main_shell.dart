import 'package:diet_tracker/data/diet_storage.dart';
import 'package:diet_tracker/data/profile_storage.dart';
import 'package:diet_tracker/repositories/nutrition_repository.dart';
import 'package:diet_tracker/models/meal_type.dart';
import 'package:diet_tracker/screens/add_entry_sheet.dart';
import 'package:diet_tracker/screens/diary_screen.dart';
import 'package:diet_tracker/screens/meal_detail_screen.dart';
import 'package:diet_tracker/screens/today_screen.dart';
import 'package:diet_tracker/theme/mfp_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.storage,
    required this.profileStorage,
    required this.nutritionRepository,
  });

  final DietStorage storage;
  final ProfileStorage profileStorage;
  final NutritionRepository nutritionRepository;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  final _todayKey = GlobalKey<TodayScreenState>();

  Future<void> _openAddFood({MealType meal = MealType.breakfast}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => AddFoodScreen(
          storage: widget.storage,
          nutritionRepository: widget.nutritionRepository,
          initialMeal: meal,
          onSaved: () => _todayKey.currentState?.reload(),
        ),
      ),
    );
    _todayKey.currentState?.reload();
    setState(() {});
  }

  Future<void> _openMealDetail(MealType meal) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => MealDetailScreen(
          storage: widget.storage,
          meal: meal,
          onLogMore: () => _openAddFood(meal: meal),
        ),
      ),
    );
    _todayKey.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_tab) {
      0 => TodayScreen(
          key: _todayKey,
          storage: widget.storage,
          profileStorage: widget.profileStorage,
          onLogMeal: _openAddFood,
          onOpenMeal: _openMealDetail,
          onViewDiary: () async {
            await Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (context) => DiaryScreen(storage: widget.storage),
              ),
            );
            _todayKey.currentState?.reload();
          },
        ),
      _ => const _PlaceholderTab(title: 'Coming soon'),
    };

    return Scaffold(
      backgroundColor: MfpColors.scaffold,
      body: body,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddFood(),
        backgroundColor: MfpColors.primary,
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: MfpColors.navBar,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: MfpColors.border.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Today',
                selected: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                label: 'Progress',
                selected: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
              _NavItem(
                icon: Icons.more_horiz_rounded,
                label: 'More',
                selected: _tab == 2,
                onTap: () => setState(() => _tab = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? MfpColors.surfaceElevated.withValues(alpha: 0.9)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? MfpColors.textPrimary : MfpColors.textMuted,
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: GoogleFonts.inter(color: MfpColors.textSecondary),
      ),
    );
  }
}