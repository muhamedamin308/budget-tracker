import 'package:budget_tracker/core/database/app_database.dart';
import 'package:budget_tracker/core/database/daos/budget_dao.dart';
import 'package:budget_tracker/core/database/daos/category_dao.dart';
import 'package:budget_tracker/core/database/daos/transaction_dao.dart';
import 'package:budget_tracker/features/budget/data/budget_repository_impl.dart';
import 'package:budget_tracker/features/budget/domain/budget_status.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late BudgetDao budgetDao;
  late CategoryDao categoryDao;
  late TransactionDao transactionDao;
  late BudgetRepositoryImpl repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    budgetDao = BudgetDao(database);
    categoryDao = CategoryDao(database);
    transactionDao = TransactionDao(database);
    repository = BudgetRepositoryImpl(budgetDao);
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'status sums monthly expenses and uses the carried-forward limit',
    () async {
      await repository.setMonthlyLimit(
        month: DateTime(2026, 11),
        amountMinor: 100000,
      );
      final expense =
          (await categoryDao.watchByType(TransactionType.expense).first).first;
      await transactionDao.insert(
        TransactionsCompanion.insert(
          type: TransactionType.expense,
          amountMinor: 80000,
          categoryId: expense.id,
          createdAt: DateTime(2026, 11, 12, 12),
        ),
      );

      final november = await repository.watchStatus(DateTime(2026, 11)).first;
      expect(november.spentMinor, 80000);
      expect(november.limitMinor, 100000);
      expect(november.level, BudgetLevel.warning);

      await repository.setMonthlyLimit(
        month: DateTime(2026, 12),
        amountMinor: 120000,
      );
      final january = await repository.watchStatus(DateTime(2027, 1)).first;
      expect(january.spentMinor, 0);
      expect(january.limitMinor, 120000);
      expect(january.level, BudgetLevel.ok);
    },
  );

  test('reports notSet when no current or earlier limit exists', () async {
    final status = await repository.watchStatus(DateTime(2026, 10)).first;

    expect(status.level, BudgetLevel.notSet);
    expect(status.limitMinor, isNull);
  });
}
