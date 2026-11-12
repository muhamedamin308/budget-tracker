import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../app_database.dart';

@lazySingleton
class BudgetDao extends DatabaseAccessor<AppDatabase> {
  BudgetDao(super.db);

  Stream<MonthlyLimit?> watchEffectiveLimit(String yearMonth) {
    final query = select(db.monthlyLimits)
      ..where((limit) => limit.yearMonth.isSmallerOrEqualValue(yearMonth))
      ..orderBy([(limit) => OrderingTerm.desc(limit.yearMonth)])
      ..limit(1);
    return query.watch().map((limits) => limits.isEmpty ? null : limits.first);
  }

  Stream<({int spentMinor, int? limitMinor})> watchStatusData({
    required String yearMonth,
    required DateTime start,
    required DateTime end,
  }) =>
      customSelect(
        '''
        SELECT
          COALESCE(
            SUM(CASE WHEN transactions.type = ? THEN transactions.amount_minor ELSE 0 END),
            0
          ) AS spent_minor,
          (
            SELECT limit_minor
            FROM monthly_limits
            WHERE year_month <= ?
            ORDER BY year_month DESC
            LIMIT 1
          ) AS limit_minor
        FROM transactions
        WHERE created_at >= ? AND created_at < ?
        ''',
        variables: [
          Variable<int>(TransactionType.expense.index),
          Variable<String>(yearMonth),
          Variable<DateTime>(start),
          Variable<DateTime>(end),
        ],
        readsFrom: {db.transactions, db.monthlyLimits},
      ).watchSingle().map(
        (row) => (
          spentMinor: row.read<int>('spent_minor'),
          limitMinor: row.read<int?>('limit_minor'),
        ),
      );

  Future<int> setMonthlyLimit(String yearMonth, int amountMinor) =>
      into(db.monthlyLimits).insertOnConflictUpdate(
        MonthlyLimitsCompanion.insert(
          yearMonth: yearMonth,
          limitMinor: amountMinor,
        ),
      );
}
