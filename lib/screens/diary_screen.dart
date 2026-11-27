import 'package:diet_tracker/data/diet_storage.dart';
import 'package:diet_tracker/models/food_entry.dart';
import 'package:diet_tracker/models/meal_type.dart';
import 'package:diet_tracker/theme/mfp_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key, required this.storage});

  final DietStorage storage;

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  List<FoodEntry> _today = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final all = widget.storage.loadAll();
    setState(() {
      _today = widget.storage.entriesForDate(DateTime.now(), all);
    });
  }

  Future<void> _delete(FoodEntry e) async {
    await widget.storage.remove(e.id);
    _load();
  }

  List<FoodEntry> _meal(MealType m) =>
      _today.where((e) => e.mealType == m).toList();

  @override
  Widget build(BuildContext context) {
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
            const Icon(Icons.chevron_left, color: MfpColors.textMuted),
            Text(
              'Today',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded),
            const Icon(Icons.chevron_right, color: MfpColors.textMuted),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          for (final meal in MealType.values)
            _DiaryMealCard(
              meal: meal,
              entries: _meal(meal),
              onDelete: _delete,
            ),
        ],
      ),
    );
  }
}

class _DiaryMealCard extends StatelessWidget {
  const _DiaryMealCard({
    required this.meal,
    required this.entries,
    required this.onDelete,
  });

  final MealType meal;
  final List<FoodEntry> entries;
  final void Function(FoodEntry) onDelete;

  @override
  Widget build(BuildContext context) {
    final cals = entries.fold(0, (s, e) => s + e.calories);
    final c = entries.fold<double>(0, (s, e) => s + e.carbsG);
    final f = entries.fold<double>(0, (s, e) => s + e.fatG);
    final p = entries.fold<double>(0, (s, e) => s + e.proteinG);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: mfpCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  meal.label,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (entries.isNotEmpty)
                  Text(
                    '$cals cal',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: MfpColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (entries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                'C ${c.toStringAsFixed(0)}g  F ${f.toStringAsFixed(0)}g  P ${p.toStringAsFixed(0)}g',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: MfpColors.textMuted,
                ),
              ),
            ),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Log food',
                  style: GoogleFonts.inter(
                    color: MfpColors.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else ...[
            const Divider(height: 1),
            for (final e in entries)
              Dismissible(
                key: ValueKey(e.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => onDelete(e),
                background: Container(
                  color: const Color(0xFFB91C1C),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.name,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${e.calories} cal',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: MfpColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${e.calories}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Log more',
                  style: GoogleFonts.inter(
                    color: MfpColors.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}