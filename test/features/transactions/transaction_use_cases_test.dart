import 'package:budget_tracker/core/database/app_database.dart';
import 'package:budget_tracker/core/database/daos/category_dao.dart';
import 'package:budget_tracker/core/database/daos/transaction_dao.dart';
import 'package:budget_tracker/features/categories/data/category_repository_impl.dart';
import 'package:budget_tracker/features/categories/domain/category_entity.dart';
import 'package:budget_tracker/features/transactions/data/transaction_repository_impl.dart';
import 'package:budget_tracker/features/transactions/domain/transaction_entity.dart';
import 'package:budget_tracker/features/transactions/domain/transaction_use_cases.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late CategoryDao categoryDao;
  late TransactionDao transactionDao;
  late CategoryRepositoryImpl categoryRepository;
  late TransactionRepositoryImpl transactionRepository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    categoryDao = CategoryDao(database);
    transactionDao = TransactionDao(database);
    categoryRepository = CategoryRepositoryImpl(categoryDao);
    transactionRepository = TransactionRepositoryImpl(
      transactionDao,
      categoryDao,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('rejects non-positive amounts and income without a title', () async {
    final expenses = await categoryRepository.watchCategories().first;
    final expense = expenses.firstWhere(
      (category) => category.type == CategoryType.expense,
    );
    final income = expenses.firstWhere(
      (category) => category.type == CategoryType.income,
    );

    final invalidExpense = await AddExpense(
      transactionRepository,
      categoryRepository,
    )(amountMinor: 0, categoryId: expense.id);
    final untitledIncome = await AddIncome(
      transactionRepository,
      categoryRepository,
    )(amountMinor: 100, categoryId: income.id, title: '  ');

    expect(invalidExpense.fold((_) => true, (_) => false), isTrue);
    expect(untitledIncome.fold((_) => true, (_) => false), isTrue);
    expect(await transactionDao.watchBalance().first, 0);
  });

  test(
    'rejects a category whose type does not match the transaction',
    () async {
      final categories = await categoryRepository.watchCategories().first;
      final income = categories.firstWhere(
        (category) => category.type == CategoryType.income,
      );
      final result = await AddExpense(
        transactionRepository,
        categoryRepository,
      )(amountMinor: 100, categoryId: income.id);

      expect(result.fold((_) => true, (_) => false), isTrue);
      expect(await transactionDao.watchBalance().first, 0);
    },
  );

  test(
    'expense changes the derived balance and deletion can be undone',
    () async {
      final categories = await categoryRepository.watchCategories().first;
      final expense = categories.firstWhere(
        (category) => category.type == CategoryType.expense,
      );
      await AddIncome(transactionRepository, categoryRepository)(
        amountMinor: 10000,
        categoryId: categories
            .firstWhere((category) => category.type == CategoryType.income)
            .id,
        title: 'Opening balance',
      );
      await AddExpense(transactionRepository, categoryRepository)(
        amountMinor: 2500,
        categoryId: expense.id,
      );
      expect(await transactionDao.watchBalance().first, 7500);

      final row = (await database.select(database.transactions).get()).last;
      final deleteResult = await DeleteTransaction(transactionRepository)(
        row.id,
      );
      TransactionEntity? deleted;
      deleteResult.fold((_) {}, (transaction) => deleted = transaction);

      expect(deleted, isNotNull);
      expect(await transactionDao.watchBalance().first, 10000);
      final restoreResult = await RestoreTransaction(transactionRepository)(
        deleted!,
      );

      expect(restoreResult.fold((_) => false, (_) => true), isTrue);
      expect(await transactionDao.watchBalance().first, 7500);
    },
  );

  test(
    'can edit a transaction without changing its archived category',
    () async {
      final categories = await categoryRepository.watchCategories().first;
      final expense = categories.firstWhere(
        (category) => category.type == CategoryType.expense,
      );
      await AddExpense(transactionRepository, categoryRepository)(
        amountMinor: 250,
        categoryId: expense.id,
      );
      final row = (await database.select(database.transactions).get()).single;
      await categoryDao.setArchived(expense.id, true);

      final result =
          await UpdateTransaction(transactionRepository, categoryRepository)(
            id: row.id,
            originalCategoryId: expense.id,
            draft: TransactionDraft(
              kind: TransactionKind.expense,
              amountMinor: 300,
              categoryId: expense.id,
            ),
          );

      expect(result.fold((_) => false, (_) => true), isTrue);
      expect(await transactionDao.watchBalance().first, -300);
    },
  );
}
