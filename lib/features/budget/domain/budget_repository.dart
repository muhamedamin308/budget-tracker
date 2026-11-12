import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import 'budget_status.dart';

abstract interface class BudgetRepository {
  Stream<BudgetStatus> watchStatus(DateTime month);

  Future<Either<Failure, Unit>> setMonthlyLimit({
    required DateTime month,
    required int amountMinor,
  });
}
