import 'package:calorie_lens/core/theme/app_theme.dart';
import 'package:calorie_lens/data/food_database.dart';
import 'package:calorie_lens/presentation/cubit/settings_cubit.dart';
import 'package:calorie_lens/presentation/screens/food_details_screen.dart';
import 'package:calorie_lens/presentation/screens/food_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ServingResult?> _open(WidgetTester tester, FoodEntry entry,
    {bool pick = false}) async {
  ServingResult? result;
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.build(UiMode.simple, Brightness.light),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () async {
              result = await Navigator.push<ServingResult>(
                context,
                MaterialPageRoute(
                    builder: (_) => FoodDetailsScreen(
                        entry: entry, mealType: 'lunch', pick: pick)),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  final apple = FoodDatabase.byName('Apple')!; // 182 g serving
  final drink = FoodDatabase.all.firstWhere((f) => f.category == 'Drinks');

  testWidgets('shows nutrition for one serving by default', (tester) async {
    await _open(tester, apple);
    final kcal = apple.portion(apple.servingG).kcal.round();
    expect(find.text('$kcal'), findsWidgets);
    expect(find.text('Add to diary · $kcal kcal'), findsOneWidget);
    expect(find.text('= ${apple.servingG.round()} g'), findsOneWidget);
  });

  testWidgets('switching to grams keeps the same amount', (tester) async {
    await _open(tester, apple);
    await tester.tap(find.text('g'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '${apple.servingG.round()}'),
        findsOneWidget);
  });

  testWidgets('invalid or empty amounts disable the add button',
      (tester) async {
    await _open(tester, apple);
    await tester.enterText(find.byType(TextField), '0');
    await tester.pump();
    expect(find.text('Enter a number above 0'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);

    await tester.enterText(find.byType(TextField), '99999');
    await tester.pump();
    expect(find.textContaining('more than'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
  });

  testWidgets('drinks offer millilitres', (tester) async {
    await _open(tester, drink);
    expect(find.text('ml'), findsOneWidget);
  });

  testWidgets('add returns grams, meal and date', (tester) async {
    ServingResult? popped;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.build(UiMode.simple, Brightness.light),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => popped = await Navigator.push<ServingResult>(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    FoodDetailsScreen(entry: apple, mealType: 'dinner')),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2');
    await tester.pump();
    await tester.tap(find.textContaining('Add to diary'));
    await tester.pumpAndSettle();
    expect(popped, isNotNull);
    expect(popped!.grams, closeTo(apple.servingG * 2, 1e-9));
    expect(popped!.mealType, 'dinner');
    expect(popped!.portion.kcal,
        closeTo(apple.portion(apple.servingG * 2).kcal, 1e-9));
  });

  testWidgets('pick mode hides meal and date', (tester) async {
    await _open(tester, apple, pick: true);
    expect(find.text('Add ingredient'), findsOneWidget);
    expect(find.text('Add to'), findsNothing);
  });
}
