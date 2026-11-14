import 'dart:io';

import 'package:budget_tracker/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _DummyUser extends QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('migration from v1 to v2 preserves all data', () async {
    final tempDir = Directory.systemTemp.createTempSync('budget_migration_test');
    final dbFile = File('${tempDir.path}/test.db');

    try {
      final rawDb = NativeDatabase(dbFile);
      await rawDb.ensureOpen(_DummyUser());
      await rawDb.runCustom(
        'CREATE TABLE categories ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'name TEXT NOT NULL, '
        'type INTEGER NOT NULL, '
        'icon_key TEXT NOT NULL, '
        'is_default INTEGER NOT NULL DEFAULT 0, '
        'is_archived INTEGER NOT NULL DEFAULT 0, '
        'UNIQUE(name, type)'
        ');',
      );
      await rawDb.runCustom(
        'CREATE TABLE recurring_rules ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'type INTEGER NOT NULL, '
        'amount_minor INTEGER NOT NULL CHECK (amount_minor > 0), '
        'category_id INTEGER NOT NULL REFERENCES categories (id), '
        'title TEXT, '
        'day_of_month INTEGER NOT NULL CHECK (day_of_month BETWEEN 1 AND 31), '
        'start_date INTEGER NOT NULL, '
        'end_date INTEGER, '
        'last_generated_due INTEGER, '
        'is_active INTEGER NOT NULL DEFAULT 1'
        ');',
      );
      await rawDb.runCustom(
        'CREATE TABLE transactions ('
        'id INTEGER PRIMARY KEY AUTOINCREMENT, '
        'type INTEGER NOT NULL, '
        'amount_minor INTEGER NOT NULL CHECK (amount_minor > 0), '
        'category_id INTEGER NOT NULL REFERENCES categories (id), '
        'title TEXT, '
        'created_at INTEGER NOT NULL, '
        'recurring_rule_id INTEGER REFERENCES recurring_rules (id) ON DELETE SET NULL, '
        'recurring_due_date INTEGER, '
        'UNIQUE(recurring_rule_id, recurring_due_date)'
        ');',
      );
      await rawDb.runCustom(
        'CREATE TABLE monthly_limits ('
        'year_month TEXT NOT NULL PRIMARY KEY, '
        'limit_minor INTEGER NOT NULL CHECK (limit_minor > 0)'
        ');',
      );
      await rawDb.runCustom(
        "INSERT INTO categories (name, type, icon_key, is_default) VALUES ('Food', 1, 'food', 1);",
      );
      await rawDb.runCustom(
        "INSERT INTO transactions (type, amount_minor, category_id, created_at) VALUES (1, 1000, 1, 1700000000);",
      );
      await rawDb.runCustom('PRAGMA user_version = 1;');
      await rawDb.close();

      final migratedDb = AppDatabase(NativeDatabase(dbFile));

      final wallets = await migratedDb.select(migratedDb.wallets).get();
      expect(wallets, hasLength(3));
      expect(wallets[0].name, 'On-Hand');
      expect(wallets[1].name, 'Bank');
      expect(wallets[2].name, 'Mobile Wallet');

      final categories = await migratedDb.select(migratedDb.categories).get();
      expect(categories, isNotEmpty);
      expect(categories[0].name, 'Food');

      final transactions = await migratedDb.select(migratedDb.transactions).get();
      expect(transactions, hasLength(1));
      expect(transactions[0].walletId, 1);

      await migratedDb.close();
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });
}
