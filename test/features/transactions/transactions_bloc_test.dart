import 'package:bloc_test/bloc_test.dart';
import 'package:budget_tracker/features/transactions/domain/transaction_entity.dart';
import 'package:budget_tracker/features/transactions/domain/transaction_use_cases.dart';
import 'package:budget_tracker/features/transactions/presentation/transactions_bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchMonthTransactions extends Mock
    implements WatchMonthTransactions {}

class MockDeleteTransaction extends Mock implements DeleteTransaction {}

class MockRestoreTransaction extends Mock implements RestoreTransaction {}

void main() {
  final month = DateTime(2026, 11);
  final transaction = TransactionEntity(
    id: 1,
    kind: TransactionKind.expense,
    amountMinor: 1250,
    categoryId: 2,
    categoryName: 'Groceries',
    categoryIconKey: 'groceries',
    title: null,
    createdAt: DateTime(2026, 11, 12, 12),
    recurringRuleId: null,
    recurringDueDate: null,
  );

  late MockWatchMonthTransactions watchMonth;
  late MockDeleteTransaction deleteTransaction;
  late MockRestoreTransaction restoreTransaction;

  setUp(() {
    watchMonth = MockWatchMonthTransactions();
    deleteTransaction = MockDeleteTransaction();
    restoreTransaction = MockRestoreTransaction();
  });

  blocTest<TransactionsBloc, TransactionsState>(
    'emits month transactions from the repository stream',
    build: () {
      when(
        () => watchMonth(month),
      ).thenAnswer((_) => Stream.value([transaction]));
      return TransactionsBloc(
        watchMonth,
        deleteTransaction,
        restoreTransaction,
      );
    },
    act: (bloc) => bloc.add(MonthChanged(month)),
    expect: () => [
      const TransactionsLoading(),
      TransactionsLoaded([transaction]),
    ],
  );

  blocTest<TransactionsBloc, TransactionsState>(
    'runs delete before an immediate undo',
    build: () {
      when(
        () => watchMonth(month),
      ).thenAnswer((_) => Stream.value([transaction]));
      when(
        () => deleteTransaction(transaction.id),
      ).thenAnswer((_) async => Right(transaction));
      when(
        () => restoreTransaction(transaction),
      ).thenAnswer((_) async => Right(unit));
      return TransactionsBloc(
        watchMonth,
        deleteTransaction,
        restoreTransaction,
      );
    },
    act: (bloc) {
      bloc
        ..add(MonthChanged(month))
        ..add(TransactionDeleted(transaction.id))
        ..add(TransactionDeleteUndone(transaction));
    },
    expect: () => [
      const TransactionsLoading(),
      TransactionsLoaded([transaction]),
    ],
    verify: (_) {
      verifyInOrder([
        () => deleteTransaction(transaction.id),
        () => restoreTransaction(transaction),
      ]);
    },
  );
}
