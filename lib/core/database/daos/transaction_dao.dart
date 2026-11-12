import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../app_database.dart';

@lazySingleton
class TransactionDao extends DatabaseAccessor<AppDatabase> {
  TransactionDao(super.db);

  Stream<int> watchBalance() => customSelect(
    '''
        SELECT COALESCE(
          SUM(CASE WHEN type = ? THEN amount_minor ELSE -amount_minor END),
          0
        ) AS balance_minor
        FROM transactions
        ''',
    variables: [Variable<int>(TransactionType.income.index)],
    readsFrom: {db.transactions},
  ).watchSingle().map((row) => row.read<int>('balance_minor'));

  Stream<DateTime?> watchFirstTransactionMonth() {
    final earliestDate = db.transactions.createdAt.min();
    return (selectOnly(
      db.transactions,
    )..addColumns([earliestDate])).watchSingle().map((row) {
      final firstDate = row.read(earliestDate);
      return firstDate == null
          ? null
          : DateTime(firstDate.year, firstDate.month);
    });
  }

  Stream<List<TransactionRow>> watchInRange(DateTime start, DateTime end) {
    final query = select(db.transactions)
      ..where(
        (transaction) =>
            transaction.createdAt.isBiggerOrEqualValue(start) &
            transaction.createdAt.isSmallerThanValue(end),
      )
      ..orderBy([
        (transaction) => OrderingTerm.desc(transaction.createdAt),
        (transaction) => OrderingTerm.desc(transaction.id),
      ]);
    return query.watch();
  }

  Stream<List<({TransactionRow transaction, Category category})>>
  watchInRangeWithCategory(DateTime start, DateTime end) {
    final query =
        select(db.transactions).join([
            innerJoin(
              db.categories,
              db.categories.id.equalsExp(db.transactions.categoryId),
            ),
          ])
          ..where(
            db.transactions.createdAt.isBiggerOrEqualValue(start) &
                db.transactions.createdAt.isSmallerThanValue(end),
          )
          ..orderBy([
            OrderingTerm.desc(db.transactions.createdAt),
            OrderingTerm.desc(db.transactions.id),
          ]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => (
              transaction: row.readTable(db.transactions),
              category: row.readTable(db.categories),
            ),
          )
          .toList(),
    );
  }

  Future<TransactionRow?> getById(int id) => (select(
    db.transactions,
  )..where((transaction) => transaction.id.equals(id))).getSingleOrNull();

  Future<int> insert(TransactionsCompanion transaction) =>
      into(db.transactions).insert(transaction);

  Future<int> updateById(int id, TransactionsCompanion transaction) => (update(
    db.transactions,
  )..where((row) => row.id.equals(id))).write(transaction);

  Future<int> deleteById(int id) => (delete(
    db.transactions,
  )..where((transaction) => transaction.id.equals(id))).go();
}
