import 'package:budget_tracker/app.dart';
import 'package:budget_tracker/core/database/app_database.dart';
import 'package:budget_tracker/core/di/injection.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  late AppDatabase testDatabase;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('esys.at/home_widget'),
      (MethodCall methodCall) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('esys.at/home_widget/events'),
      (MethodCall methodCall) async => null,
    );

    configureDependencies();
    getIt.allowReassignment = true;
    testDatabase = AppDatabase(NativeDatabase.memory());
    getIt.registerSingleton<AppDatabase>(testDatabase);
  });

  tearDownAll(() async {
    await getIt.reset();
    await testDatabase.close();
  });

  testWidgets('tabs share the selected month and categories can be managed', (
    tester,
  ) async {
    await tester.pumpWidget(const BudgetTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    final previousMonth = DateTime(
      DateTime.now().year,
      DateTime.now().month - 1,
    );
    final previousMonthLabel = DateFormat.yMMMM().format(previousMonth);
    await tester.tap(find.byTooltip('Previous month').first);
    await tester.pumpAndSettle();
    expect(find.text(previousMonthLabel), findsOneWidget);

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(find.text(previousMonthLabel), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);

    await tester.tap(find.text('Add').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Travel');
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();
    expect(find.text('Travel'), findsOneWidget);

    final travelTile = find.ancestor(
      of: find.text('Travel'),
      matching: find.byType(ListTile),
    );
    await tester.ensureVisible(travelTile);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: travelTile,
        matching: find.byType(PopupMenuButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Travel costs');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Travel costs'), findsOneWidget);

    final renamedTile = find.ancestor(
      of: find.text('Travel costs'),
      matching: find.byType(ListTile),
    );
    await tester.ensureVisible(renamedTile);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: renamedTile,
        matching: find.byType(PopupMenuButton<String>),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive').last);
    await tester.pumpAndSettle();
    expect(find.text('Travel costs'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
