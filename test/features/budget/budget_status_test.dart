import 'package:budget_tracker/features/budget/domain/budget_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classifies budget at under-80, 80, under-100, and 100 percent', () {
    expect(
      BudgetStatus.calculate(spentMinor: 7999, limitMinor: 10000).level,
      BudgetLevel.ok,
    );
    expect(
      BudgetStatus.calculate(spentMinor: 8000, limitMinor: 10000).level,
      BudgetLevel.warning,
    );
    expect(
      BudgetStatus.calculate(spentMinor: 9999, limitMinor: 10000).level,
      BudgetLevel.warning,
    );
    expect(
      BudgetStatus.calculate(spentMinor: 10000, limitMinor: 10000).level,
      BudgetLevel.exceeded,
    );
  });

  test('missing limit is notSet and exceeded progress is capped', () {
    final notSet = BudgetStatus.calculate(spentMinor: 500, limitMinor: null);
    final exceeded = BudgetStatus.calculate(
      spentMinor: 12500,
      limitMinor: 10000,
    );

    expect(notSet.level, BudgetLevel.notSet);
    expect(notSet.progress, 0);
    expect(exceeded.progress, 1);
    expect(exceeded.remainingMinor, -2500);
  });
}
