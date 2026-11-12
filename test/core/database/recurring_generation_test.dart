import 'package:budget_tracker/core/database/app_database.dart';
import 'package:budget_tracker/core/database/daos/category_dao.dart';
import 'package:budget_tracker/core/database/daos/recurring_dao.dart';
import 'package:budget_tracker/core/database/daos/transaction_dao.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late CategoryDao categoryDao;
  late RecurringDao recurringDao;
  late TransactionDao transactionDao;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    categoryDao = CategoryDao(database);
    recurringDao = RecurringDao(database);
    transactionDao = TransactionDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('backfills monthly occurrences and is idempotent across runs', () async {
    final category =
        (await categoryDao.watchByType(TransactionType.expense).first).first;
    final ruleId = await recurringDao.insert(
      RecurringRulesCompanion.insert(
        type: TransactionType.expense,
        amountMinor: 12500,
        categoryId: category.id,
        dayOfMonth: 31,
        startDate: DateTime(2026, 10, 31),
      ),
    );

    await recurringDao.generateDueRecurring(DateTime(2026, 12, 1, 23, 59));
    await (database.update(database.recurringRules)
          ..where((rule) => rule.id.equals(ruleId)))
        .write(const RecurringRulesCompanion(lastGeneratedDue: Value(null)));
    await recurringDao.generateDueRecurring(DateTime(2026, 12, 1, 23, 59));

    var rows = await transactionDao
        .watchInRange(DateTime(2026, 10), DateTime(2027, 4))
        .first;
    expect(rows, hasLength(2));
    expect(rows.map((row) => row.recurringDueDate).toSet(), {
      DateTime(2026, 10, 31, 12),
      DateTime(2026, 11, 30, 12),
    });
    expect(
      (await (database.select(
        database.recurringRules,
      )..where((rule) => rule.id.equals(ruleId))).getSingle()).lastGeneratedDue,
      DateTime(2026, 11, 30, 12),
    );

    await recurringDao.generateDueRecurring(DateTime(2027, 4, 1, 23, 59));
    rows = await transactionDao
        .watchInRange(DateTime(2026, 10), DateTime(2027, 4))
        .first;
    expect(rows, hasLength(6));
    expect(rows.map((row) => row.recurringDueDate).toSet(), {
      DateTime(2026, 10, 31, 12),
      DateTime(2026, 11, 30, 12),
      DateTime(2026, 12, 31, 12),
      DateTime(2027, 1, 31, 12),
      DateTime(2027, 2, 28, 12),
      DateTime(2027, 3, 31, 12),
    });
  });
}
