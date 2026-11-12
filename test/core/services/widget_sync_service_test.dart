import 'dart:async';

import 'package:budget_tracker/core/services/widget_sync_service.dart';
import 'package:budget_tracker/features/budget/domain/budget_repository.dart';
import 'package:budget_tracker/features/budget/domain/budget_status.dart';
import 'package:budget_tracker/features/budget/domain/budget_use_cases.dart';
import 'package:budget_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:budget_tracker/features/transactions/domain/transaction_use_cases.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRepository extends Mock
    implements TransactionRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTransactionRepository transactionRepository;
  late MockBudgetRepository budgetRepository;
  late WatchBalance watchBalance;
  late WatchBudgetStatus watchBudgetStatus;
  late StreamController<int> balanceController;
  late StreamController<BudgetStatus> budgetController;
  late WidgetSyncServiceImpl service;

  setUp(() {
    transactionRepository = MockTransactionRepository();
    budgetRepository = MockBudgetRepository();
    balanceController = StreamController<int>.broadcast();
    budgetController = StreamController<BudgetStatus>.broadcast();

    when(() => transactionRepository.watchBalance()).thenAnswer(
      (_) => balanceController.stream,
    );
    when(() => budgetRepository.watchStatus(any())).thenAnswer(
      (_) => budgetController.stream,
    );

    watchBalance = WatchBalance(transactionRepository);
    watchBudgetStatus = WatchBudgetStatus(budgetRepository);
    service = WidgetSyncServiceImpl(watchBalance, watchBudgetStatus);
  });

  tearDown(() {
    service.dispose();
    balanceController.close();
    budgetController.close();
  });

  test('service starts listening and handles stream emissions without errors', () async {
    service.startListening();

    balanceController.add(150000);
    budgetController.add(
      const BudgetStatus(
        spentMinor: 80000,
        limitMinor: 100000,
        level: BudgetLevel.ok,
      ),
    );

    await pumpEventQueue();

    expect(service.isBalanceHidden, isFalse);
    await service.setBalanceHidden(true);
    expect(service.isBalanceHidden, isTrue);

    await service.syncNow();
  });
}

