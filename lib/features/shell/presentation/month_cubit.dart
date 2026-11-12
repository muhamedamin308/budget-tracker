import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../transactions/domain/transaction_repository.dart';

@injectable
class MonthCubit extends Cubit<DateTime> {
  MonthCubit(this._transactionRepository)
    : super(_firstOfMonth(DateTime.now())) {
    _subscription = _transactionRepository.watchFirstTransactionMonth().listen(
      (month) {
        _firstTransactionMonth = month;
        if (month != null && state.isBefore(month)) emit(month);
      },
      onError: (Object error, StackTrace stackTrace) =>
          addError(error, stackTrace),
    );
  }

  final TransactionRepository _transactionRepository;
  StreamSubscription<DateTime?>? _subscription;
  DateTime? _firstTransactionMonth;

  bool get canGoPrevious {
    final previousMonth = DateTime(state.year, state.month - 1);
    final firstMonth = _firstTransactionMonth;
    return firstMonth == null || !previousMonth.isBefore(firstMonth);
  }

  bool get canGoNext => state.isBefore(_firstOfMonth(DateTime.now()));

  void previous() {
    if (canGoPrevious) emit(DateTime(state.year, state.month - 1));
  }

  void next() {
    final nextMonth = DateTime(state.year, state.month + 1);
    if (canGoNext) emit(nextMonth);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }

  static DateTime _firstOfMonth(DateTime date) =>
      DateTime(date.year, date.month);
}
