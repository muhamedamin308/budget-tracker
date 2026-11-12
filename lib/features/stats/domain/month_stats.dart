import 'package:equatable/equatable.dart';

import '../../transactions/domain/transaction_entity.dart';

enum StatsBucketType { daily, weekly }

class CategorySpending extends Equatable {
  const CategorySpending({
    required this.categoryId,
    required this.name,
    required this.amountMinor,
  });

  final int categoryId;
  final String name;
  final int amountMinor;

  @override
  List<Object?> get props => [categoryId, name, amountMinor];
}

class SpendingBucket extends Equatable {
  const SpendingBucket({required this.start, required this.amountMinor});

  final DateTime start;
  final int amountMinor;

  @override
  List<Object?> get props => [start, amountMinor];
}

class MonthStats extends Equatable {
  const MonthStats({
    required this.month,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.netMinor,
    required this.byCategory,
    required this.dailyBuckets,
    required this.weeklyBuckets,
  });

  static const int weeklyStartDay = DateTime.saturday;

  factory MonthStats.calculate({
    required DateTime month,
    required List<TransactionEntity> transactions,
  }) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    var incomeMinor = 0;
    var expenseMinor = 0;
    final categoryAmounts = <int, int>{};
    final categoryNames = <int, String>{};

    final monthTransactions = transactions.where((transaction) {
      return !transaction.createdAt.isBefore(start) &&
          transaction.createdAt.isBefore(end);
    }).toList();

    for (final transaction in monthTransactions) {
      if (transaction.kind == TransactionKind.income) {
        incomeMinor += transaction.amountMinor;
      } else {
        expenseMinor += transaction.amountMinor;
        categoryAmounts.update(
          transaction.categoryId,
          (amount) => amount + transaction.amountMinor,
          ifAbsent: () => transaction.amountMinor,
        );
        categoryNames[transaction.categoryId] = transaction.categoryName;
      }
    }

    final byCategory =
        categoryAmounts.entries
            .map(
              (entry) => CategorySpending(
                categoryId: entry.key,
                name: categoryNames[entry.key]!,
                amountMinor: entry.value,
              ),
            )
            .toList()
          ..sort((first, second) {
            final byAmount = second.amountMinor.compareTo(first.amountMinor);
            return byAmount != 0 ? byAmount : first.name.compareTo(second.name);
          });

    final dayCount = DateTime(start.year, start.month + 1, 0).day;
    final dailyBuckets = List<SpendingBucket>.generate(dayCount, (index) {
      final dayStart = DateTime(start.year, start.month, index + 1);
      final dayEnd = DateTime(start.year, start.month, index + 2);
      return SpendingBucket(
        start: dayStart,
        amountMinor: _expenseInRange(monthTransactions, dayStart, dayEnd),
      );
    });

    final daysFromSaturday =
        (start.weekday - weeklyStartDay + DateTime.daysPerWeek) %
        DateTime.daysPerWeek;
    var weekStart = DateTime(
      start.year,
      start.month,
      start.day - daysFromSaturday,
    );
    final weeklyBuckets = <SpendingBucket>[];
    while (weekStart.isBefore(end)) {
      final weekEnd = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day + DateTime.daysPerWeek,
      );
      final rangeStart = weekStart.isBefore(start) ? start : weekStart;
      final rangeEnd = weekEnd.isAfter(end) ? end : weekEnd;
      weeklyBuckets.add(
        SpendingBucket(
          start: weekStart,
          amountMinor: _expenseInRange(monthTransactions, rangeStart, rangeEnd),
        ),
      );
      weekStart = weekEnd;
    }

    return MonthStats(
      month: start,
      incomeMinor: incomeMinor,
      expenseMinor: expenseMinor,
      netMinor: incomeMinor - expenseMinor,
      byCategory: byCategory,
      dailyBuckets: dailyBuckets,
      weeklyBuckets: weeklyBuckets,
    );
  }

  final DateTime month;
  final int incomeMinor;
  final int expenseMinor;
  final int netMinor;
  final List<CategorySpending> byCategory;
  final List<SpendingBucket> dailyBuckets;
  final List<SpendingBucket> weeklyBuckets;

  @override
  List<Object?> get props => [
    month,
    incomeMinor,
    expenseMinor,
    netMinor,
    byCategory,
    dailyBuckets,
    weeklyBuckets,
  ];
}

int _expenseInRange(
  List<TransactionEntity> transactions,
  DateTime start,
  DateTime end,
) {
  var total = 0;
  for (final transaction in transactions) {
    if (transaction.kind == TransactionKind.expense &&
        !transaction.createdAt.isBefore(start) &&
        transaction.createdAt.isBefore(end)) {
      total += transaction.amountMinor;
    }
  }
  return total;
}
