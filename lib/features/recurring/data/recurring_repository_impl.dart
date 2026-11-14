import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/recurring_dao.dart';
import '../../../core/error/failures.dart';
import '../../transactions/domain/transaction_entity.dart';
import '../domain/recurring_repository.dart';
import '../domain/recurring_rule_entity.dart';

@LazySingleton(as: RecurringRepository)
class RecurringRepositoryImpl implements RecurringRepository {
  const RecurringRepositoryImpl(this._recurringDao);

  final RecurringDao _recurringDao;

  @override
  Stream<List<RecurringRuleEntity>> watchRules() =>
      _recurringDao.watchRulesWithCategory().map(
        (rows) => rows
            .map(
              (row) => RecurringRuleEntity(
                id: row.rule.id,
                kind: _toDomainKind(row.rule.type),
                amountMinor: row.rule.amountMinor,
                categoryId: row.rule.categoryId,
                categoryName: row.category.name,
                title: row.rule.title,
                dayOfMonth: row.rule.dayOfMonth,
                startDate: row.rule.startDate,
                endDate: row.rule.endDate,
                lastGeneratedDue: row.rule.lastGeneratedDue,
                isActive: row.rule.isActive,
                walletId: row.rule.walletId,
              ),
            )
            .toList(),
      );

  @override
  Future<Either<Failure, Unit>> saveRule(RecurringRuleDraft draft) =>
      _persist(() {
        final companion = RecurringRulesCompanion(
          type: Value(_toDatabaseType(draft.kind)),
          amountMinor: Value(draft.amountMinor),
          categoryId: Value(draft.categoryId),
          walletId: draft.walletId != null ? Value(draft.walletId!) : const Value.absent(),
          title: Value(draft.title),
          dayOfMonth: Value(draft.dayOfMonth),
          startDate: Value(draft.startDate),
          endDate: Value(draft.endDate),
        );
        final id = draft.id;
        if (id == null) {
          return _recurringDao.insert(
            RecurringRulesCompanion.insert(
              type: _toDatabaseType(draft.kind),
              amountMinor: draft.amountMinor,
              categoryId: draft.categoryId,
              walletId: draft.walletId ?? 1,
              title: Value(draft.title),
              dayOfMonth: draft.dayOfMonth,
              startDate: draft.startDate,
              endDate: Value(draft.endDate),
            ),
          );
        }
        return _recurringDao.updateById(id, companion);
      }, 'Could not save the recurring rule');

  @override
  Future<Either<Failure, Unit>> setRuleActive(int id, bool isActive) =>
      _persist(
        () => _recurringDao.setActive(id, isActive),
        'Could not update the recurring rule',
      );

  @override
  Future<Either<Failure, Unit>> deleteRule(int id) => _persist(
    () => _recurringDao.deleteById(id),
    'Could not delete the recurring rule',
  );

  @override
  Future<Either<Failure, Unit>> generateDueRecurring(DateTime until) async {
    try {
      await _recurringDao.generateDueRecurring(until);
      return Right(unit);
    } on Exception catch (error) {
      return Left(
        PersistenceFailure('Could not generate recurring transactions: $error'),
      );
    }
  }

  Future<Either<Failure, Unit>> _persist(
    Future<int> Function() operation,
    String message,
  ) async {
    try {
      final changedRows = await operation();
      if (changedRows == 0) {
        return Left(PersistenceFailure('$message: recurring rule not found.'));
      }
      return Right(unit);
    } on Exception catch (error) {
      return Left(PersistenceFailure('$message: $error'));
    }
  }

  TransactionType _toDatabaseType(TransactionKind kind) => switch (kind) {
    TransactionKind.income => TransactionType.income,
    TransactionKind.expense => TransactionType.expense,
  };

  TransactionKind _toDomainKind(TransactionType type) => switch (type) {
    TransactionType.income => TransactionKind.income,
    TransactionType.expense => TransactionKind.expense,
  };
}
