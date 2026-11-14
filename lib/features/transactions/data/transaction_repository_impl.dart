import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/category_dao.dart';
import '../../../core/database/daos/transaction_dao.dart';
import '../../../core/error/failures.dart';
import '../domain/transaction_entity.dart';
import '../domain/transaction_repository.dart';

@LazySingleton(as: TransactionRepository)
class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl(this._transactionDao, this._categoryDao);

  final TransactionDao _transactionDao;
  final CategoryDao _categoryDao;

  @override
  Stream<int> watchBalance() => _transactionDao.watchBalance();

  @override
  Stream<DateTime?> watchFirstTransactionMonth() =>
      _transactionDao.watchFirstTransactionMonth();

  @override
  Stream<List<TransactionEntity>> watchMonthTransactions(DateTime month) {
    final start = DateTime(month.year, month.month);
    final nextMonth = DateTime(month.year, month.month + 1);
    return _transactionDao
        .watchInRangeWithCategory(start, nextMonth)
        .map(
          (rows) => rows
              .map((row) => _toEntity(row.transaction, row.category))
              .toList(),
        );
  }

  @override
  Future<Either<Failure, Unit>> addTransaction(TransactionDraft draft) =>
      _persist(
        () => _transactionDao.insert(
          TransactionsCompanion.insert(
            type: _toDatabaseType(draft.kind),
            amountMinor: draft.amountMinor,
            categoryId: draft.categoryId,
            walletId: draft.walletId ?? 1,
            title: Value(draft.title),
            createdAt: draft.createdAt ?? DateTime.now(),
          ),
        ),
        'Could not add the transaction',
      );

  @override
  Future<Either<Failure, Unit>> updateTransaction(
    int id,
    TransactionDraft draft,
  ) async {
    try {
      final existing = await _transactionDao.getById(id);
      if (existing == null) {
        return const Left(PersistenceFailure('Transaction not found.'));
      }
      final updatedRows = await _transactionDao.updateById(
        id,
        TransactionsCompanion(
          type: Value(_toDatabaseType(draft.kind)),
          amountMinor: Value(draft.amountMinor),
          categoryId: Value(draft.categoryId),
          walletId: draft.walletId != null ? Value(draft.walletId!) : const Value.absent(),
          title: Value(draft.title),
          createdAt: Value(draft.createdAt ?? existing.createdAt),
        ),
      );
      if (updatedRows == 0) {
        return const Left(PersistenceFailure('Transaction not found.'));
      }
      return Right(unit);
    } on Exception catch (error) {
      return Left(
        PersistenceFailure('Could not update the transaction: $error'),
      );
    }
  }

  @override
  Future<Either<Failure, TransactionEntity>> deleteTransaction(int id) async {
    try {
      final row = await _transactionDao.getById(id);
      if (row == null) {
        return const Left(PersistenceFailure('Transaction not found.'));
      }
      final category = await _categoryDao.getById(row.categoryId);
      if (category == null) {
        return const Left(
          PersistenceFailure('The transaction category could not be found.'),
        );
      }
      final deletedRows = await _transactionDao.deleteById(id);
      if (deletedRows == 0) {
        return const Left(PersistenceFailure('Transaction not found.'));
      }
      return Right(_toEntity(row, category));
    } on Exception catch (error) {
      return Left(
        PersistenceFailure('Could not delete the transaction: $error'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> restoreTransaction(
    TransactionEntity transaction,
  ) => _persist(
    () => _transactionDao.insert(
      TransactionsCompanion.insert(
        id: Value(transaction.id),
        type: _toDatabaseType(transaction.kind),
        amountMinor: transaction.amountMinor,
        categoryId: transaction.categoryId,
        walletId: transaction.walletId,
        title: Value(transaction.title),
        createdAt: transaction.createdAt,
        recurringRuleId: Value(transaction.recurringRuleId),
        recurringDueDate: Value(transaction.recurringDueDate),
      ),
    ),
    'Could not restore the transaction',
  );

  Future<Either<Failure, Unit>> _persist(
    Future<int> Function() operation,
    String failureMessage,
  ) async {
    try {
      final changedRows = await operation();
      if (changedRows == 0) {
        return Left(PersistenceFailure(failureMessage));
      }
      return const Right(unit);
    } on Exception catch (error) {
      return Left(PersistenceFailure('$failureMessage: $error'));
    }
  }

  TransactionEntity _toEntity(TransactionRow row, Category category) =>
      TransactionEntity(
        id: row.id,
        kind: _toDomainKind(row.type),
        amountMinor: row.amountMinor,
        categoryId: row.categoryId,
        categoryName: category.name,
        categoryIconKey: category.iconKey,
        title: row.title,
        createdAt: row.createdAt,
        recurringRuleId: row.recurringRuleId,
        recurringDueDate: row.recurringDueDate,
        walletId: row.walletId,
      );

  TransactionType _toDatabaseType(TransactionKind kind) => switch (kind) {
    TransactionKind.income => TransactionType.income,
    TransactionKind.expense => TransactionType.expense,
  };

  TransactionKind _toDomainKind(TransactionType type) => switch (type) {
    TransactionType.income => TransactionKind.income,
    TransactionType.expense => TransactionKind.expense,
  };
}
