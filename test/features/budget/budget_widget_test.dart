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

  testWidgets('monthly limit editor updates Home budget progress', (
    tester,
  ) async {
    await tester.pumpWidget(const BudgetTrackerApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly limit'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('monthly-limit-amount')),
      '1000',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Home').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add income'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('transaction-amount')),
      '1000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('transaction-title')),
      'Income',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('transaction-amount')),
      '800',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('800.00 EGP of 1,000.00 EGP'), findsOneWidget);
    expect(find.text('You have used 80% of this limit.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
