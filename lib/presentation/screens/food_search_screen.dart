import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/meal_types.dart';
import '../../data/food_database.dart';
import '../../data/models/food_item.dart';
import '../../data/remote/open_food_facts.dart';
import '../cubit/food_log_cubit.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/tracker_cubit.dart';
import '../widgets/common.dart';
import '../widgets/food_thumb.dart';
import 'barcode_scan_screen.dart';
import 'food_details_screen.dart';

/// What the user picked on the food details screen.
class ServingResult {
  final FoodEntry entry;
  final double grams;
  final String mealType;
  final DateTime date;
  const ServingResult(this.entry, this.grams, this.mealType, this.date);
  FoodPortion get portion => entry.portion(grams);
}

/// Adds a food picked on the details screen to the diary.
void logServing(BuildContext context, ServingResult result) {
  final p = result.portion;
  context.read<FoodLogCubit>().addManual(
        name: result.entry.name,
        calories: p.kcal,
        protein: p.protein,
        carbs: p.carbs,
        fat: p.fat,
        quantity: p.grams,
        mealType: result.mealType,
        fiber: p.fiber,
        sugar: p.sugar,
        sodium: p.sodium,
        date: result.date,
        imageUrl: result.entry.imageUrl,
      );
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
        content: Text('Added ${result.entry.name} · ${p.kcal.round()} kcal')));
}

/// Scan a barcode, confirm the serving, and log it.
Future<void> scanAndLog(BuildContext context, {String? mealType}) async {
  final entry = await Navigator.push<FoodEntry>(
      context, MaterialPageRoute(builder: (_) => const BarcodeScanScreen()));
  if (entry == null || !context.mounted) return;
  final result = await Navigator.push<ServingResult>(
    context,
    MaterialPageRoute(
        builder: (_) => FoodDetailsScreen(
            entry: entry, mealType: mealType ?? MealTypes.now())),
  );
  if (result != null && context.mounted) logServing(context, result);
}

enum _OnlineState { idle, loading, done, offline, error }

/// Search-first food picker. Built-in foods answer instantly and work
/// offline; Open Food Facts results are added after a short debounce.
/// In [pick] mode it returns the chosen food instead of logging it (used by
/// recipes and the planner).
class FoodSearchScreen extends StatefulWidget {
  final bool pick;
  final String? mealType;
  const FoodSearchScreen({super.key, this.pick = false, this.mealType});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String? _category;
  List<FoodEntry> _online = const [];
  _OnlineState _onlineState = _OnlineState.idle;
  String? _onlineMessage;
  int _requestId = 0;

  OpenFoodFactsSource get _source => context.read<OpenFoodFactsSource>();

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    final q = value.trim();
    if (q.length < 3) {
      _requestId++;
      setState(() {
        _online = const [];
        _onlineState = _OnlineState.idle;
      });
      return;
    }
    setState(() => _onlineState = _OnlineState.loading);
    _debounce = Timer(const Duration(milliseconds: 450), () => _fetchOnline(q));
  }

  Future<void> _fetchOnline(String q) async {
    final id = ++_requestId;
    try {
      final results = await _source.search(q);
      if (!mounted || id != _requestId) return;
      setState(() {
        _online = results;
        _onlineState = _OnlineState.done;
      });
    } on FoodSourceException catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _online = const [];
        _onlineState = e.offline ? _OnlineState.offline : _OnlineState.error;
        _onlineMessage = e.message;
      });
    }
  }

  Future<void> _select(FoodEntry entry) async {
    final result = await Navigator.push<ServingResult>(
      context,
      MaterialPageRoute(
        builder: (_) => FoodDetailsScreen(
            entry: entry,
            mealType: widget.mealType ?? MealTypes.now(),
            pick: widget.pick),
      ),
    );
    if (result == null || !mounted) return;
    if (widget.pick) {
      Navigator.pop(context, result);
      return;
    }
    _log(result);
  }

  void _log(ServingResult result) => logServing(context, result);

  Future<void> _scan() => scanAndLog(context, mealType: widget.mealType);

  void _quickLog(FoodItem item) {
    final meal = widget.mealType ?? MealTypes.now();
    context.read<FoodLogCubit>().addFromTemplate(item, mealType: meal);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text('Added ${item.name} · ${item.calories.round()} kcal')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diet = context.watch<SettingsCubit>().state.diet;
    final tracker = context.watch<TrackerCubit>().state;
    final local = FoodDatabase.search(_query, category: _category, diet: diet);
    final localNames = local.map((f) => f.name.toLowerCase()).toSet();
    final online = _category != null
        ? const <FoodEntry>[]
        : _online
            .where((f) => !localNames.contains(f.name.toLowerCase()))
            .toList();
    final searching = _query.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pick ? 'Pick an ingredient' : 'Add food'),
        actions: [
          if (!widget.pick)
            IconButton(
              tooltip: 'Scan barcode',
              icon: const Icon(Icons.qr_code_scanner_rounded),
              onPressed: _scan,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: TextField(
              controller: _controller,
              autofocus: false,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Search foods, brands, meals',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _onlineState == _OnlineState.loading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4)),
                      )
                    : (_query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _controller.clear();
                              _onChanged('');
                            },
                          )),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                      label: const Text('All'),
                      selected: _category == null,
                      onSelected: (_) => setState(() => _category = null)),
                ),
                for (final c in FoodDatabase.categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      onSelected: (_) =>
                          setState(() => _category = _category == c ? null : c),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                if (diet.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Icon(Icons.filter_alt_rounded,
                          size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Diet filter: ${FoodDatabase.diets.where((d) => diet.contains(d.key)).map((d) => d.label).join(', ')} (online results are not filtered)',
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                    ]),
                  ),
                if (!searching && _category == null && !widget.pick) ...[
                  if (tracker.favorites.isNotEmpty)
                    ..._quickSection(
                        'Favorites', Icons.star_rounded, tracker.favorites),
                  if (tracker.recents.isNotEmpty)
                    ..._quickSection('Recent', Icons.history_rounded,
                        tracker.recents.take(6).toList()),
                ],
                if (local.isNotEmpty) ...[
                  _SectionLabel(searching || _category != null
                      ? 'Foods'
                      : 'Browse foods'),
                  for (final f in local.take(searching ? 40 : 60))
                    _FoodTile(
                        entry: f, pick: widget.pick, onTap: () => _select(f)),
                ],
                if (online.isNotEmpty) ...[
                  const _SectionLabel('From the online database'),
                  for (final f in online)
                    _FoodTile(
                        entry: f, pick: widget.pick, onTap: () => _select(f)),
                ],
                if (_onlineState == _OnlineState.loading &&
                    online.isEmpty &&
                    searching &&
                    _query.trim().length >= 3)
                  const _LoadingRows(),
                if (_onlineState == _OnlineState.offline ||
                    _onlineState == _OnlineState.error)
                  _StatusCard(
                    icon: _onlineState == _OnlineState.offline
                        ? Icons.wifi_off_rounded
                        : Icons.cloud_off_rounded,
                    title: _onlineState == _OnlineState.offline
                        ? 'Offline'
                        : 'Online search unavailable',
                    message:
                        '${_onlineMessage ?? ''} Showing built-in foods only.',
                    onRetry: () {
                      setState(() => _onlineState = _OnlineState.loading);
                      _fetchOnline(_query.trim());
                    },
                  ),
                if (searching &&
                    local.isEmpty &&
                    online.isEmpty &&
                    _onlineState != _OnlineState.loading &&
                    _onlineState != _OnlineState.offline &&
                    _onlineState != _OnlineState.error)
                  const _EmptyResults(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _quickSection(
          String title, IconData icon, List<FoodItem> items) =>
      [
        _SectionLabel(title),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => ActionChip(
              avatar: Icon(icon, size: 16),
              label: Text('${items[i].name} · ${items[i].calories.round()}'),
              onPressed: () => _quickLog(items[i]),
            ),
          ),
        ),
        const SizedBox(height: 4),
      ];
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(text,
          style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurfaceVariant)),
    );
  }
}

class _FoodTile extends StatelessWidget {
  final FoodEntry entry;
  final bool pick;
  final VoidCallback onTap;
  const _FoodTile(
      {required this.entry, required this.pick, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serving = entry.portion(entry.servingG);
    final subtitle = [
      if (entry.brand != null) entry.brand!,
      entry.servingLabel,
      if (entry.servingLabel != '100 g') '${entry.servingG.round()} g'
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        label:
            '${entry.name}, ${serving.kcal.round()} calories per ${entry.servingLabel}',
        child: AppCard(
          onTap: onTap,
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              FoodThumb(
                  imageUrl: entry.imageUrl,
                  icon: FoodThumb.iconForCategory(entry.category)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${serving.kcal.round()}',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Text('kcal',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              Icon(
                  pick
                      ? Icons.add_circle_outline_rounded
                      : Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingRows extends StatelessWidget {
  const _LoadingRows();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double w) => Container(
        width: w,
        height: 12,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(6)));
    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AppCard(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(Radii.md - 2))),
                const SizedBox(width: 12),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [bar(160), const SizedBox(height: 8), bar(100)]),
              ]),
            ),
          ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;
  const _StatusCard(
      {required this.icon,
      required this.title,
      required this.message,
      required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AppCard(
        color: theme.colorScheme.surfaceContainerLow,
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(message, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded,
              size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('No foods found',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
              'Try another word, scan the barcode, or add it manually from the diary.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Tappable search field that opens [FoodSearchScreen].
class SearchFoodBar extends StatelessWidget {
  const SearchFoodBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: 'Search food',
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const FoodSearchScreen())),
        child: Row(
          children: [
            Icon(Icons.search_rounded,
                color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
                child: Text('Search food by name',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant))),
            Icon(Icons.qr_code_scanner_rounded,
                size: 22, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
