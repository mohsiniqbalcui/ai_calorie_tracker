import 'package:calorie_lens/core/theme/app_theme.dart';
import 'package:calorie_lens/data/local/tracker_store.dart';
import 'package:calorie_lens/data/remote/open_food_facts.dart';
import 'package:calorie_lens/data/repositories/food_repository.dart';
import 'package:calorie_lens/data/services/food_service.dart';
import 'package:calorie_lens/presentation/cubit/food_log_cubit.dart';
import 'package:calorie_lens/presentation/cubit/settings_cubit.dart';
import 'package:calorie_lens/presentation/cubit/tracker_cubit.dart';
import 'package:calorie_lens/presentation/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Harness {
  final SettingsCubit settings;
  final FoodLogCubit food;
  final TrackerCubit tracker;
  final Widget app;
  _Harness(this.settings, this.food, this.tracker, this.app);
}

Future<_Harness> _build(WidgetTester tester,
    {Size size = const Size(390, 844),
    Map<String, Object> prefsValues = const {}}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  final store = TrackerStore(prefs);
  final settings = SettingsCubit(prefs);
  final food = FoodLogCubit(FoodRepository(FoodService(), prefs), store)
    ..loadDailyLog();
  final tracker = TrackerCubit(store);

  final app = MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: store),
      RepositoryProvider(create: (_) => OpenFoodFactsSource()),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: settings),
        BlocProvider.value(value: food),
        BlocProvider.value(value: tracker)
      ],
      child: BlocBuilder<SettingsCubit, AppSettings>(
        builder: (context, s) => MaterialApp(
          theme: AppTheme.build(s.uiMode, Brightness.light),
          darkTheme: AppTheme.build(s.uiMode, Brightness.dark),
          themeMode: s.themeMode,
          // The test font (Ahem) is about twice as wide as real fonts, so scale it
          // down to make overflow checks meaningful.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(0.55)),
            child: child!,
          ),
          home: const MainScreen(),
        ),
      ),
    ),
  );
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
  return _Harness(settings, food, tracker, app);
}

void main() {
  testWidgets('Home shows the four meal sections and an empty state',
      (tester) async {
    await _build(tester);
    for (final m in ['Breakfast', 'Lunch', 'Dinner', 'Snacks']) {
      expect(find.text(m), findsOneWidget);
    }
    expect(
        find.text(
            'Nothing logged yet. Snap a photo or describe your meal to start the day.'),
        findsOneWidget);
    expect(find.text('Add food'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom navigation reaches Diary, Progress and More',
      (tester) async {
    await _build(tester);
    expect(find.byType(NavigationDestination), findsNWidgets(4));

    await tester.tap(find.text('Diary'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing logged yet'), findsOneWidget);

    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    expect(find.text('Goal progress'), findsOneWidget);

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Scan barcode'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'a logged meal appears on Home and in the Diary with updated totals',
      (tester) async {
    final h = await _build(tester);
    await h.food.addManual(
        name: 'Greek yogurt',
        calories: 120,
        protein: 12,
        carbs: 6,
        fat: 4,
        mealType: 'breakfast');
    await tester.pumpAndSettle();
    expect(find.text('Greek yogurt'), findsOneWidget);
    expect(find.text('1 item · 120 kcal'), findsOneWidget);

    await tester.tap(find.text('Diary'));
    await tester.pumpAndSettle();
    expect(find.text('Greek yogurt'), findsOneWidget);
    expect(find.textContaining('120 / '), findsOneWidget);
  });

  testWidgets('Pro mode adds analytics sections to Home and Diary',
      (tester) async {
    final h = await _build(tester);
    expect(find.text('Nutrition details'), findsNothing);
    await h.settings.setUiMode(UiMode.pro);
    await tester.pumpAndSettle();
    expect(find.text('Nutrition details'), findsOneWidget);

    await tester.tap(find.text('Diary'));
    await tester.pumpAndSettle();
    expect(find.text('Search this day'), findsOneWidget);
  });

  testWidgets('Add food sheet offers search, barcode, AI and manual options',
      (tester) async {
    await _build(tester);
    await tester.tap(find.text('Add food'));
    await tester.pumpAndSettle();
    for (final label in [
      'Search',
      'Scan barcode',
      'Photo (AI)',
      'Describe (AI)',
      'Manual',
      'Recipes'
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('search screen lists built-in foods and filters by typing',
      (tester) async {
    await _build(tester);
    await tester.tap(find.text('Add food'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.text('Apple'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ban');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Banana'), findsOneWidget);
    expect(find.text('Apple'), findsNothing);
  });

  testWidgets('small phones do not overflow', (tester) async {
    await _build(tester, size: const Size(320, 568));
    expect(tester.takeException(), isNull);
    for (final tab in ['Diary', 'Progress', 'More', 'Home']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'overflow on $tab');
    }
  });

  testWidgets('dark theme renders every tab', (tester) async {
    final h = await _build(tester);
    await h.settings.setThemeMode(ThemeMode.dark);
    await tester.pumpAndSettle();
    for (final tab in ['Diary', 'Progress', 'More', 'Home']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'error on $tab');
    }
  });
}
