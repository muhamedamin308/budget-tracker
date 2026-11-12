import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import 'recurring_rule_entity.dart';

abstract interface class RecurringRepository {
  Stream<List<RecurringRuleEntity>> watchRules();

  Future<Either<Failure, Unit>> saveRule(RecurringRuleDraft draft);

  Future<Either<Failure, Unit>> setRuleActive(int id, bool isActive);

  Future<Either<Failure, Unit>> deleteRule(int id);

  Future<Either<Failure, Unit>> generateDueRecurring(DateTime until);
}
