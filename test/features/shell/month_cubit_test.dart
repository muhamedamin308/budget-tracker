import 'package:budget_tracker/features/shell/presentation/month_cubit.dart';
import 'package:budget_tracker/features/transactions/domain/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  test(
    'previous month navigation stops at the first transaction month',
    () async {
      final repository = MockTransactionRepository();
      final currentMonth = DateTime.now();
      final firstMonth = DateTime(currentMonth.year, currentMonth.month - 2);
      when(
        () => repository.watchFirstTransactionMonth(),
      ).thenAnswer((_) => Stream.value(firstMonth));
      final cubit = MonthCubit(repository);
      addTearDown(cubit.close);

      await Future<void>.delayed(Duration.zero);
      expect(cubit.canGoPrevious, isTrue);

      cubit
        ..previous()
        ..previous();

      expect(cubit.state, firstMonth);
      expect(cubit.canGoPrevious, isFalse);
      cubit.previous();
      expect(cubit.state, firstMonth);
    },
  );
}
