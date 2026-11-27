import 'package:diet_tracker/data/diet_storage.dart';
import 'package:diet_tracker/screens/edit_food_entry_sheet.dart';
import 'package:diet_tracker/models/food_entry.dart';
import 'package:diet_tracker/models/meal_type.dart';
import 'package:diet_tracker/theme/mfp_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MealDetailScreen extends StatefulWidget {
  const MealDetailScreen({
    super.key,
    required this.storage,
    required this.meal,
    this.onLogMore,
  });

  final DietStorage storage;
  final MealType meal;
  final Future<void> Function()? onLogMore;

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  List<FoodEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final all = widget.storage.loadAll();
    setState(() {
      _entries = widget.storage
          .entriesForDate(DateTime.now(), all)
          .where((e) => e.mealType == widget.meal)
          .toList();
    });
  }

  Future<void> _delete(FoodEntry e) async {
    await widget.storage.remove(e.id);
    _load();
  }

  Future<void> _edit(FoodEntry e) async {
    await showEditFoodEntrySheet(
      context,
      storage: widget.storage,
      entry: e,
      onSaved: _load,
    );
  }

  @override
  Widget build(BuildContext context) {
    final calories = _entries.fold<int>(0, (s, e) => s + e.calories);
    final carbs = _entries.fold<double>(0, (s, e) => s + e.carbsG);
    final fat = _entries.fold<double>(0, (s, e) => s + e.fatG);
    final protein = _entries.fold<double>(0, (s, e) => s + e.proteinG);

    return Scaffold(
      backgroundColor: MfpColors.scaffold,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.meal.icon, size: 22, color: MfpColors.primaryText),
            const SizedBox(width: 8),
            Text(
              widget.meal.label,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: mfpCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meal total',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: MfpColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$calories cal',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _NutritionChip(
                      label: 'Carbs',
                      value: carbs,
                      color: MfpColors.carbs,
                    ),
                    _NutritionChip(
                      label: 'Fat',
                      value: fat,
                      color: MfpColors.fat,
                    ),
                    _NutritionChip(
                      label: 'Protein',
                      value: protein,
                      color: MfpColors.protein,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Foods',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (widget.onLogMore != null)
                TextButton(
                  onPressed: () async {
                    await widget.onLogMore?.call();
                    if (mounted) _load();
                  },
                  child: Text(
                    _entries.isEmpty ? 'Log food' : 'Log more',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: MfpColors.primaryText,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_entries.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: mfpCardDecoration(),
              child: Center(
                child: Text(
                  'No foods logged for ${widget.meal.label.toLowerCase()} yet.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: MfpColors.textMuted,
                  ),
                ),
              ),
            )
          else
            Container(
              decoration: mfpCardDecoration(),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < _entries.length; i++) ...[
                    if (i > 0) const Divider(height: 1, thickness: 1),
                    Dismissible(
                      key: ValueKey(_entries[i].id),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) => _delete(_entries[i]),
                      background: Container(
                        color: const Color(0xFFB91C1C),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                      child: _FoodRow(
                        entry: _entries[i],
                        onTap: () => _edit(_entries[i]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _NutritionChip extends StatelessWidget {
  const _NutritionChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: MfpColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${value.toStringAsFixed(0)}g',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              height: 3,
              child: LinearProgressIndicator(
                value: value > 0 ? 1 : 0,
                backgroundColor: MfpColors.border,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodRow extends StatelessWidget {
  const _FoodRow({required this.entry, required this.onTap});

  final FoodEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'C ${entry.carbsG.toStringAsFixed(0)}g · '
                      'F ${entry.fatG.toStringAsFixed(0)}g · '
                      'P ${entry.proteinG.toStringAsFixed(0)}g',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: MfpColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${entry.calories} cal',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: MfpColors.textMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}