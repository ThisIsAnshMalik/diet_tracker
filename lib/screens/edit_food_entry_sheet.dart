import 'package:diet_tracker/data/diet_storage.dart';
import 'package:diet_tracker/data/food_catalog.dart';
import 'package:diet_tracker/models/food_entry.dart';
import 'package:diet_tracker/models/food_item.dart';
import 'package:diet_tracker/models/meal_type.dart';
import 'package:diet_tracker/theme/mfp_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

FoodItem? catalogItemForEntry(String name) {
  for (final item in foodCatalog) {
    if (item.name.toLowerCase() == name.toLowerCase()) return item;
  }
  return null;
}

double _inferServings(FoodEntry entry, FoodItem? catalog) {
  if (catalog != null && catalog.calories > 0) {
    return entry.calories / catalog.calories;
  }
  return 1;
}

FoodEntry _entryFromServings({
  required FoodEntry original,
  required double servings,
  required FoodItem? catalog,
  required MealType meal,
}) {
  if (catalog != null) {
    final scaled = catalog.scaled(servings);
    return FoodEntry(
      id: original.id,
      name: scaled.name,
      mealType: meal,
      loggedAt: original.loggedAt,
      calories: scaled.calories,
      proteinG: scaled.proteinG,
      carbsG: scaled.carbsG,
      fatG: scaled.fatG,
    );
  }
  final base = _baseNutrition(original, catalog);
  return FoodEntry(
    id: original.id,
    name: original.name,
    mealType: meal,
    loggedAt: original.loggedAt,
    calories: (base.calories * servings).round(),
    proteinG: base.proteinG * servings,
    carbsG: base.carbsG * servings,
    fatG: base.fatG * servings,
  );
}

/// Per-serving nutrition when the entry was saved with a non-1 serving count.
FoodEntry _baseNutrition(FoodEntry entry, FoodItem? catalog) {
  final s = _inferServings(entry, catalog);
  if (s == 1 || s <= 0) return entry;
  return FoodEntry(
    id: entry.id,
    name: entry.name,
    mealType: entry.mealType,
    loggedAt: entry.loggedAt,
    calories: (entry.calories / s).round(),
    proteinG: entry.proteinG / s,
    carbsG: entry.carbsG / s,
    fatG: entry.fatG / s,
  );
}

Future<void> showEditFoodEntrySheet(
  BuildContext context, {
  required DietStorage storage,
  required FoodEntry entry,
  required VoidCallback onSaved,
}) async {
  final catalog = catalogItemForEntry(entry.name);
  var meal = entry.mealType;
  var servings = _inferServings(entry, catalog);
  final servingsController = TextEditingController(
    text: _formatServings(servings),
  );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: MfpColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final preview = _entryFromServings(
            original: entry,
            servings: servings,
            catalog: catalog,
            meal: meal,
          );

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Edit food',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: MfpColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Text(
                  entry.name,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (catalog != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    catalog.servingLabel,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: MfpColors.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                DropdownButtonFormField<MealType>(
                  initialValue: meal,
                  decoration: const InputDecoration(labelText: 'Meal'),
                  items: MealType.values
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.label),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setModalState(() => meal = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: servingsController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Number of servings',
                  ),
                  onChanged: (v) {
                    setModalState(() {
                      servings = double.tryParse(v.trim()) ?? servings;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: MfpColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: MfpColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${preview.calories} cal',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'C ${preview.carbsG.toStringAsFixed(0)}g · '
                        'F ${preview.fatG.toStringAsFixed(0)}g · '
                        'P ${preview.proteinG.toStringAsFixed(0)}g',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: MfpColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    final s =
                        double.tryParse(servingsController.text.trim()) ?? 1;
                    if (s <= 0) return;
                    final updated = _entryFromServings(
                      original: entry,
                      servings: s,
                      catalog: catalog,
                      meal: meal,
                    );
                    await storage.update(updated);
                    if (ctx.mounted) Navigator.pop(ctx);
                    onSaved();
                  },
                  child: const Text('Save changes'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () async {
                    await storage.remove(entry.id);
                    if (ctx.mounted) Navigator.pop(ctx);
                    onSaved();
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                  child: const Text('Remove from diary'),
                ),
              ],
            ),
          );
        },
      );
    },
  );
  servingsController.dispose();
}

String _formatServings(double s) {
  if (s == s.roundToDouble()) return s.toStringAsFixed(0);
  return s.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}