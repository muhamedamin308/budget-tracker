import 'package:budget_tracker/app.dart';
import 'package:budget_tracker/core/database/app_database.dart';
import 'package:budget_tracker/core/di/injection.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase testDatabase;

  setUpAll(() async {
    configureDependencies();
    await getIt.unregister<AppDatabase>();
    testDatabase = AppDatabase(NativeDatabase.memory());
    getIt.registerSingleton<AppDatabase>(testDatabase);
  });

  tearDownAll(() async {
    await getIt.reset();
    await testDatabase.close();
  });

  testWidgets('starting income then overspending confirms and warns', (
    tester,
  ) async {
    await tester.pumpWidget(const BudgetTrackerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add your starting balance'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('transaction-amount')),
      '1000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('transaction-title')),
      'Opening balance',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('1,000.00 EGP'), findsOneWidget);

    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('transaction-amount')),
      '1500',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(
      find.text('This puts your wallet at −500.00 EGP. Save anyway?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Save anyway'));
    await tester.pumpAndSettle();

    expect(find.text('Your balance is below zero.'), findsOneWidget);
    expect(find.text('-500.00 EGP'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
