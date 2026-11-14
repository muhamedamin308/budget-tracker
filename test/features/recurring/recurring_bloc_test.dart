import 'package:bloc_test/bloc_test.dart';
import 'package:budget_tracker/features/recurring/domain/recurring_rule_entity.dart';
import 'package:budget_tracker/features/recurring/domain/recurring_use_cases.dart';
import 'package:budget_tracker/features/recurring/presentation/recurring_bloc.dart';
import 'package:budget_tracker/features/transactions/domain/transaction_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchRules extends Mock implements WatchRules {}

class MockSaveRule extends Mock implements SaveRule {}

class MockSetRuleActive extends Mock implements SetRuleActive {}

class MockDeleteRule extends Mock implements DeleteRule {}

void main() {
  final rule = RecurringRuleEntity(
    id: 2,
    kind: TransactionKind.expense,
    amountMinor: 7500,
    categoryId: 3,
    categoryName: 'Groceries',
    title: null,
    dayOfMonth: 31,
    startDate: DateTime(2026, 1, 1),
    endDate: null,
    lastGeneratedDue: null,
    isActive: true,
    walletId: 1,
  );
  late MockWatchRules watchRules;
  late MockSaveRule saveRule;
  late MockSetRuleActive setRuleActive;
  late MockDeleteRule deleteRule;

  setUp(() {
    watchRules = MockWatchRules();
    saveRule = MockSaveRule();
    setRuleActive = MockSetRuleActive();
    deleteRule = MockDeleteRule();
    when(() => watchRules()).thenAnswer((_) => Stream.value([rule]));
    when(
      () => setRuleActive(rule.id, false),
    ).thenAnswer((_) async => Right(unit));
  });

  blocTest<RecurringBloc, RecurringState>(
    'watches rules and dispatches active-state changes',
    build: () => RecurringBloc(watchRules, saveRule, setRuleActive, deleteRule),
    act: (bloc) async {
      bloc.add(const RecurringStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const RuleToggled(id: 2, isActive: false));
    },
    expect: () => [
      const RecurringLoading(),
      RecurringLoaded([rule]),
    ],
    verify: (_) => verify(() => setRuleActive(rule.id, false)).called(1),
  );
}
