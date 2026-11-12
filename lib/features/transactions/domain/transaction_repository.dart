import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import 'transaction_entity.dart';

abstract interface class TransactionRepository {
  Stream<int> watchBalance();

  Stream<DateTime?> watchFirstTransactionMonth();

  Stream<List<TransactionEntity>> watchMonthTransactions(DateTime month);

  Future<Either<Failure, Unit>> addTransaction(TransactionDraft draft);

  Future<Either<Failure, Unit>> updateTransaction(
    int id,
    TransactionDraft draft,
  );

  Future<Either<Failure, TransactionEntity>> deleteTransaction(int id);

  Future<Either<Failure, Unit>> restoreTransaction(
    TransactionEntity transaction,
  );
}
