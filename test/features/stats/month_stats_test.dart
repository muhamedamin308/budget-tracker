import 'package:budget_tracker/features/stats/domain/month_stats.dart';
import 'package:budget_tracker/features/transactions/domain/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aggregates income, expenses, net, and ordered category totals', () {
    final stats = MonthStats.calculate(
      month: DateTime(2026, 1),
      transactions: [
        _transaction(kind: TransactionKind.income, amount: 10000),
        _transaction(amount: 500, categoryId: 1, categoryName: 'Food'),
        _transaction(amount: 250, categoryId: 2, categoryName: 'Transport', day: 2),
        _transaction(amount: 500, categoryId: 1, categoryName: 'Food', day: 31),
        _transaction(amount: 900, year: 2025, day: 31, month: 12),
        _transaction(amount: 900, day: 1, month: 2),
      ],
    );

    expect(stats.incomeMinor, 10000);
    expect(stats.expenseMinor, 1250);
    expect(stats.netMinor, 8750);
    expect(
      stats.byCategory
          .map((category) => (category.name, category.amountMinor))
          .toList(),
      [('Food', 1000), ('Transport', 250)],
    );
    expect(stats.dailyBuckets, hasLength(31));
    expect(stats.dailyBuckets.first.amountMinor, 500);
    expect(stats.dailyBuckets.last.amountMinor, 500);
  });

  test('weekly buckets start on Saturday and include only month expenses', () {
    final stats = MonthStats.calculate(
      month: DateTime(2026, 1),
      transactions: [
        _transaction(amount: 100, day: 1),
        _transaction(amount: 200, day: 3),
      ],
    );

    expect(stats.weeklyBuckets.first.start, DateTime(2025, 12, 27));
    expect(stats.weeklyBuckets.first.amountMinor, 100);
    expect(stats.weeklyBuckets[1].start, DateTime(2026, 1, 3));
    expect(stats.weeklyBuckets[1].amountMinor, 200);
  });

  test('empty month has zero totals and calendar-complete buckets', () {
    final stats = MonthStats.calculate(
      month: DateTime(2024, 2),
      transactions: const [],
    );

    expect(stats.incomeMinor, 0);
    expect(stats.expenseMinor, 0);
    expect(stats.netMinor, 0);
    expect(stats.byCategory, isEmpty);
    expect(stats.dailyBuckets, hasLength(29));
    expect(
      stats.dailyBuckets.every((bucket) => bucket.amountMinor == 0),
      isTrue,
    );
    expect(
      stats.weeklyBuckets.every((bucket) => bucket.amountMinor == 0),
      isTrue,
    );
  });
}

TransactionEntity _transaction({
  TransactionKind kind = TransactionKind.expense,
  int amount = 100,
  int categoryId = 1,
  String categoryName = 'Food',
  int year = 2026,
  int month = 1,
  int day = 1,
  int walletId = 1,
}) => TransactionEntity(
  id: 1,
  kind: kind,
  amountMinor: amount,
  categoryId: categoryId,
  categoryName: categoryName,
  categoryIconKey: 'category',
  title: null,
  createdAt: DateTime(year, month, day, 12),
  recurringRuleId: null,
  recurringDueDate: null,
  walletId: walletId,
);
