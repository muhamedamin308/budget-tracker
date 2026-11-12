import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failures.dart';
import 'budget_repository.dart';
import 'budget_status.dart';

@injectable
class WatchBudgetStatus {
  const WatchBudgetStatus(this._repository);

  final BudgetRepository _repository;

  Stream<BudgetStatus> call(DateTime month) => _repository.watchStatus(month);
}

@injectable
class SetMonthlyLimit {
  const SetMonthlyLimit(this._repository);

  final BudgetRepository _repository;

  Future<Either<Failure, Unit>> call({
    required DateTime month,
    required int amountMinor,
  }) {
    if (amountMinor <= 0) {
      return Future.value(
        const Left(
          ValidationFailure('Monthly limit must be greater than zero.'),
        ),
      );
    }
    return _repository.setMonthlyLimit(
      month: DateTime(month.year, month.month),
      amountMinor: amountMinor,
    );
  }
}
