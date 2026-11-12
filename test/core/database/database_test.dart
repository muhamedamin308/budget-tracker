import 'package:budget_tracker/core/database/app_database.dart';
import 'package:budget_tracker/core/database/daos/budget_dao.dart';
import 'package:budget_tracker/core/database/daos/category_dao.dart';
import 'package:budget_tracker/core/database/daos/recurring_dao.dart';
import 'package:budget_tracker/core/database/daos/transaction_dao.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late BudgetDao budgetDao;
  late CategoryDao categoryDao;
  late RecurringDao recurringDao;
  late TransactionDao transactionDao;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    budgetDao = BudgetDao(database);
    categoryDao = CategoryDao(database);
    recurringDao = RecurringDao(database);
    transactionDao = TransactionDao(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('seeds the default income and expense categories', () async {
    final income = await categoryDao.watchByType(TransactionType.income).first;
    final expenses = await categoryDao
        .watchByType(TransactionType.expense)
        .first;

    expect(income, hasLength(6));
    expect(expenses, hasLength(11));
    expect(income.every((category) => category.isDefault), isTrue);
    expect(expenses.every((category) => category.isDefault), isTrue);
  });

  test('categories sort by transaction usage, then by name', () async {
    final expenses = await categoryDao
        .watchByType(TransactionType.expense)
        .first;
    expect(expenses.first.name, 'Bills & Utilities');

    final transport = expenses.firstWhere(
      (category) => category.name == 'Transport',
    );
    await transactionDao.insert(
      TransactionsCompanion.insert(
        type: TransactionType.expense,
        amountMinor: 100,
        categoryId: transport.id,
        createdAt: DateTime(2026, 11, 1),
      ),
    );

    expect(
      (await categoryDao.watchByType(TransactionType.expense).first).first.name,
      'Transport',
    );
  });

  test('last-used category is selected by latest transaction date', () async {
    final expenses = await categoryDao
        .watchByType(TransactionType.expense)
        .first;
    final older = expenses.firstWhere((category) => category.name == 'Rent');
    final latest = expenses.firstWhere(
      (category) => category.name == 'Transport',
    );
    for (final (category, date) in [
      (older, DateTime(2026, 11, 1)),
      (latest, DateTime(2026, 11, 5)),
    ]) {
      await transactionDao.insert(
        TransactionsCompanion.insert(
          type: TransactionType.expense,
          amountMinor: 100,
          categoryId: category.id,
          createdAt: date,
        ),
      );
    }

    expect(
      (await categoryDao.getLastUsedByType(TransactionType.expense))?.id,
      latest.id,
    );
  });

  test('balance reflects transaction inserts, edits, and deletes', () async {
    final balanceUpdates = expectLater(
      transactionDao.watchBalance(),
      emitsInOrder([0, 10000, 8500, 9500, 11000]),
    );
    final categories = await database.select(database.categories).get();
    final incomeCategory = categories.firstWhere(
      (category) => category.type == TransactionType.income,
    );
    final expenseCategory = categories.firstWhere(
      (category) => category.type == TransactionType.expense,
    );

    final incomeId = await transactionDao.insert(
      TransactionsCompanion.insert(
        type: TransactionType.income,
        amountMinor: 10000,
        categoryId: incomeCategory.id,
        createdAt: DateTime(2026, 11, 1),
      ),
    );
    final expenseId = await transactionDao.insert(
      TransactionsCompanion.insert(
        type: TransactionType.expense,
        amountMinor: 1500,
        categoryId: expenseCategory.id,
        createdAt: DateTime(2026, 11, 2),
      ),
    );
    await transactionDao.updateById(
      incomeId,
      const TransactionsCompanion(amountMinor: Value(11000)),
    );

    await transactionDao.deleteById(expenseId);
    await balanceUpdates;
  });

  test('month query uses a half-open date range', () async {
    final category = (await database.select(database.categories).get()).first;
    final start = DateTime(2026, 11);
    final end = DateTime(2026, 12);

    for (final date in [start, DateTime(2026, 11, 30, 23, 59), end]) {
      await transactionDao.insert(
        TransactionsCompanion.insert(
          type: TransactionType.expense,
          amountMinor: 100,
          categoryId: category.id,
          createdAt: date,
        ),
      );
    }

    final rows = await transactionDao.watchInRange(start, end).first;
    expect(rows, hasLength(2));
    expect(rows.last.createdAt, start);
  });

  test('first transaction month stream reports the earliest month', () async {
    final firstMonthUpdates = expectLater(
      transactionDao.watchFirstTransactionMonth(),
      emitsInOrder([null, DateTime(2026, 11), DateTime(2026, 10)]),
    );
    final category = (await database.select(database.categories).get()).first;
    await transactionDao.insert(
      TransactionsCompanion.insert(
        type: TransactionType.expense,
        amountMinor: 100,
        categoryId: category.id,
        createdAt: DateTime(2026, 11, 12),
      ),
    );
    await transactionDao.insert(
      TransactionsCompanion.insert(
        type: TransactionType.expense,
        amountMinor: 100,
        categoryId: category.id,
        createdAt: DateTime(2026, 10, 30),
      ),
    );
    await firstMonthUpdates;
  });

  test(
    'deleting a recurring rule preserves its transaction and clears link',
    () async {
      final category =
          (await categoryDao.watchByType(TransactionType.expense).first).first;
      final dueDate = DateTime(2026, 11, 30, 12);
      final ruleId = await recurringDao.insert(
        RecurringRulesCompanion.insert(
          type: TransactionType.expense,
          amountMinor: 2500,
          categoryId: category.id,
          dayOfMonth: 31,
          startDate: DateTime(2026, 11, 1),
        ),
      );
      final transactionId = await transactionDao.insert(
        TransactionsCompanion.insert(
          type: TransactionType.expense,
          amountMinor: 2500,
          categoryId: category.id,
          createdAt: dueDate,
          recurringRuleId: Value(ruleId),
          recurringDueDate: Value(dueDate),
        ),
      );

      await recurringDao.deleteById(ruleId);

      final transaction = await transactionDao.getById(transactionId);
      expect(transaction, isNotNull);
      expect(transaction!.recurringRuleId, isNull);
    },
  );

  test('monthly limits carry forward until changed', () async {
    await budgetDao.setMonthlyLimit('2026-11', 100000);
    await budgetDao.setMonthlyLimit('2026-12', 150000);

    expect(await budgetDao.watchEffectiveLimit('2026-10').first, isNull);
    expect(
      (await budgetDao.watchEffectiveLimit('2026-11').first)?.limitMinor,
      100000,
    );
    expect(
      (await budgetDao.watchEffectiveLimit('2027-01').first)?.limitMinor,
      150000,
    );
  });
}
