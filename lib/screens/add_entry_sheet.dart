import 'package:diet_tracker/data/diet_storage.dart';
import 'package:diet_tracker/data/food_catalog.dart';
import 'package:diet_tracker/models/food_entry.dart';
import 'package:diet_tracker/models/food_item.dart';
import 'package:diet_tracker/models/meal_type.dart';
import 'package:diet_tracker/theme/mfp_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({
    super.key,
    required this.storage,
    required this.onSaved,
    this.initialMeal = MealType.breakfast,
  });

  final DietStorage storage;
  final VoidCallback onSaved;
  final MealType initialMeal;

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen>
    with SingleTickerProviderStateMixin {
  late MealType _meal;
  late TabController _tabs;
  final _search = TextEditingController();
  bool _quickAdd = false;

  final _name = TextEditingController();
  final _calories = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  final _protein = TextEditingController();

  @override
  void initState() {
    super.initState();
    _meal = widget.initialMeal;
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    _name.dispose();
    _calories.dispose();
    _carbs.dispose();
    _fat.dispose();
    _protein.dispose();
    super.dispose();
  }

  List<FoodItem> get _catalogMatches {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return foodCatalog;
    return foodCatalog.where((f) => f.name.toLowerCase().contains(q)).toList();
  }

  List<String> get _suggestions {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return [];
    return foodCatalog
        .map((f) => f.name.toLowerCase())
        .where((n) => n.contains(q) && n != q)
        .take(5)
        .toList();
  }

  Future<void> _logEntry(FoodEntry entry) async {
    await widget.storage.add(entry);
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _logFromRecent(FoodEntry template) async {
    await _logEntry(
      FoodEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: template.name,
        mealType: _meal,
        loggedAt: DateTime.now(),
        calories: template.calories,
        proteinG: template.proteinG,
        carbsG: template.carbsG,
        fatG: template.fatG,
      ),
    );
  }

  Future<void> _logCatalogItem(FoodItem item, {double servings = 1}) async {
    final s = item.scaled(servings);
    await _logEntry(
      FoodEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: s.name,
        mealType: _meal,
        loggedAt: DateTime.now(),
        calories: s.calories,
        proteinG: s.proteinG,
        carbsG: s.carbsG,
        fatG: s.fatG,
      ),
    );
  }

  Future<void> _submitQuickAdd() async {
    final cals = int.tryParse(_calories.text.trim());
    final carb = double.tryParse(_carbs.text.trim());
    final f = double.tryParse(_fat.text.trim());
    final p = double.tryParse(_protein.text.trim());
    if (_name.text.trim().isEmpty ||
        cals == null ||
        carb == null ||
        f == null ||
        p == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill in all fields')),
      );
      return;
    }
    await _logEntry(
      FoodEntry(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        mealType: _meal,
        loggedAt: DateTime.now(),
        calories: cals,
        proteinG: p,
        carbsG: carb,
        fatG: f,
      ),
    );
  }

  void _stub(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is not available in this demo')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_quickAdd) return _buildQuickAddScaffold();

    final recent = widget.storage.recentEntries();

    return Scaffold(
      backgroundColor: MfpColors.scaffold,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.inter(color: MfpColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search foods, brands, flavours...',
                  prefixIcon: const Icon(Icons.search, color: MfpColors.textMuted),
                  suffixIcon: _search.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'My Meals'),
                Tab(text: 'My Recipes'),
                Tab(text: 'My Foods'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  _buildAllTab(recent),
                  _emptyTab('No saved meals yet'),
                  _emptyTab('No recipes yet'),
                  _buildMyFoodsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              foregroundColor: MfpColors.textPrimary,
              side: const BorderSide(color: MfpColors.border),
              shape: const CircleBorder(),
            ),
            icon: const Icon(Icons.close, size: 22),
          ),
          Expanded(
            child: PopupMenuButton<MealType>(
              initialValue: _meal,
              offset: const Offset(0, 40),
              color: MfpColors.surfaceElevated,
              onSelected: (m) => setState(() => _meal = m),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _meal.label,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: MfpColors.primaryText,
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: MfpColors.primaryText,
                  ),
                ],
              ),
              itemBuilder: (context) => MealType.values
                  .map(
                    (m) => PopupMenuItem(
                      value: m,
                      child: Text(m.label),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildAllTab(List<FoodEntry> recent) {
    final query = _search.text.trim();
    if (query.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (_suggestions.isNotEmpty) ...[
            Text(
              'Suggested Searches',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final s in _suggestions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.search, color: MfpColors.textMuted),
                title: Text(s),
                onTap: () {
                  _search.text = s;
                  setState(() {});
                },
              ),
            const SizedBox(height: 16),
          ],
          ..._catalogMatches.map(_catalogCard),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _quickActions(),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              'Recently logged',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Icon(Icons.tune, color: MfpColors.textMuted, size: 22),
          ],
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          Text(
            'Foods you log will show up here.',
            style: GoogleFonts.inter(color: MfpColors.textMuted),
          )
        else
          ...recent.map(_recentCard),
      ],
    );
  }

  Widget _quickActions() {
    final actions = [
      (Icons.qr_code_scanner_rounded, 'Barcode\nscan'),
      (Icons.mic_none_rounded, 'Voice\nlog'),
      (Icons.document_scanner_outlined, 'Meal\nscan'),
      (Icons.bolt_rounded, 'Quick\nadd'),
    ];
    return Row(
      children: [
        for (var i = 0; i < actions.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
              child: Material(
                color: MfpColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: InkWell(
                  onTap: () {
                    if (i == 3) {
                      setState(() => _quickAdd = true);
                    } else {
                      _stub(actions[i].$2.replaceAll('\n', ' '));
                    }
                  },
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: Container(
                    height: 88,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(color: MfpColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(actions[i].$1, color: MfpColors.primaryText),
                        const SizedBox(height: 6),
                        Text(
                          actions[i].$2,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: MfpColors.primaryText,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _recentCard(FoodEntry e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration: BoxDecoration(
        color: MfpColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: MfpColors.border),
      ),
      child: Row(
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
          _addCircle(() => _logFromRecent(e)),
        ],
      ),
    );
  }

  Widget _catalogCard(FoodItem f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration: BoxDecoration(
        color: MfpColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: MfpColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${f.calories} cal, ${f.servingLabel}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: MfpColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          _addCircle(() => _showServingSheet(f)),
        ],
      ),
    );
  }

  Widget _addCircle(VoidCallback onTap) {
    return Material(
      color: MfpColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.add, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildMyFoodsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: foodCatalog.map(_catalogCard).toList(),
    );
  }

  Widget _emptyTab(String message) {
    return Center(
      child: Text(
        message,
        style: GoogleFonts.inter(color: MfpColors.textMuted),
      ),
    );
  }

  Future<void> _showServingSheet(FoodItem item) async {
    final controller = TextEditingController(text: '1');
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: MfpColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item.name,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                item.servingLabel,
                style: GoogleFonts.inter(color: MfpColors.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Number of servings',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final s = double.tryParse(controller.text.trim()) ?? 1;
                  Navigator.pop(ctx);
                  _logCatalogItem(item, servings: s);
                },
                child: const Text('Add to diary'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickAddScaffold() {
    return Scaffold(
      backgroundColor: MfpColors.scaffold,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _quickAdd = false),
        ),
        title: const Text('Quick add'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Food name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _calories,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Calories'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _carbs,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Carbs (g)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _fat,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Fat (g)'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _protein,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Protein (g)'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitQuickAdd,
            child: const Text('Add to diary'),
          ),
        ],
      ),
    );
  }
}