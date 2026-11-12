import 'package:injectable/injectable.dart';

import '../../transactions/domain/transaction_repository.dart';
import 'month_stats.dart';

@injectable
class WatchMonthStats {
  const WatchMonthStats(this._transactionRepository);

  final TransactionRepository _transactionRepository;

  Stream<MonthStats> call(DateTime month) => _transactionRepository
      .watchMonthTransactions(month)
      .map(
        (transactions) =>
            MonthStats.calculate(month: month, transactions: transactions),
      );
}
