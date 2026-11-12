import 'package:budget_tracker/core/database/app_database.dart';
import 'package:budget_tracker/core/database/daos/category_dao.dart';
import 'package:budget_tracker/core/database/daos/transaction_dao.dart';
import 'package:budget_tracker/core/utils/category_icons.dart';
import 'package:budget_tracker/features/categories/data/category_repository_impl.dart';
import 'package:budget_tracker/features/categories/domain/category_entity.dart';
import 'package:budget_tracker/features/categories/domain/category_use_cases.dart';
import 'package:budget_tracker/features/transactions/data/transaction_repository_impl.dart';
import 'package:budget_tracker/features/transactions/domain/transaction_use_cases.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late CategoryRepositoryImpl categoryRepository;
  late TransactionRepositoryImpl transactionRepository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    final categoryDao = CategoryDao(database);
    final transactionDao = TransactionDao(database);
    categoryRepository = CategoryRepositoryImpl(categoryDao);
    transactionRepository = TransactionRepositoryImpl(
      transactionDao,
      categoryDao,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test(
    'selected category icon persists and appears on linked transactions',
    () async {
      final addResult = await AddCategory(categoryRepository)(
        name: 'Coffee',
        type: CategoryType.expense,
        iconKey: 'coffee',
      );
      expect(addResult.isRight(), isTrue);

      final category = (await categoryRepository.watchCategories().first)
          .singleWhere((item) => item.name == 'Coffee');
      expect(category.iconKey, 'coffee');

      final expenseResult = await AddExpense(
        transactionRepository,
        categoryRepository,
      )(amountMinor: 575, categoryId: category.id);
      expect(expenseResult.isRight(), isTrue);

      final transaction =
          (await transactionRepository
                  .watchMonthTransactions(DateTime.now())
                  .first)
              .single;
      expect(transaction.categoryIconKey, 'coffee');
      expect(
        CategoryIcons.getIcon(transaction.categoryIconKey),
        Icons.coffee_rounded,
      );
    },
  );

  test(
    'renaming a category can also update its icon for existing entries',
    () async {
      final category = (await categoryRepository.watchCategories().first)
          .firstWhere((item) => item.type == CategoryType.expense);
      await AddExpense(transactionRepository, categoryRepository)(
        amountMinor: 100,
        categoryId: category.id,
      );

      final result = await RenameCategory(categoryRepository)(
        id: category.id,
        name: category.name,
        iconKey: 'shopping_bag',
      );

      expect(result.isRight(), isTrue);
      final transaction =
          (await transactionRepository
                  .watchMonthTransactions(DateTime.now())
                  .first)
              .single;
      expect(transaction.categoryIconKey, 'shopping_bag');
    },
  );
}
