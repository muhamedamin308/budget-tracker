import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../core/database/daos/budget_dao.dart';
import '../../../core/error/failures.dart';
import '../domain/budget_repository.dart';
import '../domain/budget_status.dart';

@LazySingleton(as: BudgetRepository)
class BudgetRepositoryImpl implements BudgetRepository {
  const BudgetRepositoryImpl(this._budgetDao);

  final BudgetDao _budgetDao;

  @override
  Stream<BudgetStatus> watchStatus(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    return _budgetDao
        .watchStatusData(yearMonth: _yearMonth(month), start: start, end: end)
        .map(
          (data) => BudgetStatus.calculate(
            spentMinor: data.spentMinor,
            limitMinor: data.limitMinor,
          ),
        );
  }

  @override
  Future<Either<Failure, Unit>> setMonthlyLimit({
    required DateTime month,
    required int amountMinor,
  }) async {
    try {
      await _budgetDao.setMonthlyLimit(_yearMonth(month), amountMinor);
      return Right(unit);
    } on Exception catch (error) {
      return Left(
        PersistenceFailure('Could not save the monthly limit: $error'),
      );
    }
  }

  String _yearMonth(DateTime month) =>
      '${month.year.toString().padLeft(4, '0')}-'
      '${month.month.toString().padLeft(2, '0')}';
}
