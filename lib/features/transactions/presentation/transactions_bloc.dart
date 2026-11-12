import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failures.dart';
import '../domain/transaction_entity.dart';
import '../domain/transaction_use_cases.dart';

@injectable
class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  TransactionsBloc(this._watchMonth, this._delete, this._restore)
    : super(const TransactionsLoading()) {
    on<MonthChanged>((event, emit) => _watch(event.month, emit));
    on<TransactionsRetryRequested>((event, emit) {
      final month = _month;
      if (month != null) return _watch(month, emit);
    });
    on<_TransactionsReceived>(
      (event, emit) => emit(TransactionsLoaded(event.transactions)),
    );
    on<_TransactionsWatchFailed>(
      (event, emit) => emit(TransactionsError(event.message)),
    );
    on<TransactionDeleted>(_onDeleted);
    on<TransactionDeleteUndone>(_onDeleteUndone);
  }

  final WatchMonthTransactions _watchMonth;
  final DeleteTransaction _delete;
  final RestoreTransaction _restore;
  StreamSubscription<List<TransactionEntity>>? _subscription;
  DateTime? _month;
  Future<void> _lastMutation = Future<void>.value();

  Future<void> _watch(DateTime month, Emitter<TransactionsState> emit) async {
    _month = DateTime(month.year, month.month);
    emit(const TransactionsLoading());
    await _subscription?.cancel();
    if (emit.isDone) return;
    _subscription = _watchMonth(_month!).listen(
      (transactions) {
        if (!isClosed) add(_TransactionsReceived(transactions));
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!isClosed) add(_TransactionsWatchFailed(error.toString()));
      },
    );
  }

  Future<void> _onDeleted(
    TransactionDeleted event,
    Emitter<TransactionsState> emit,
  ) => _serialize(() async {
    final result = await _delete(event.id);
    result.fold((failure) => _emitFailure(emit, failure), (_) {});
  });

  Future<void> _onDeleteUndone(
    TransactionDeleteUndone event,
    Emitter<TransactionsState> emit,
  ) => _serialize(() async {
    final result = await _restore(event.transaction);
    result.fold((failure) => _emitFailure(emit, failure), (_) {});
  });

  Future<void> _serialize(Future<void> Function() mutation) {
    final previous = _lastMutation;
    final completer = Completer<void>();
    _lastMutation = completer.future;
    return () async {
      try {
        await previous;
        await mutation();
      } finally {
        completer.complete();
      }
    }();
  }

  void _emitFailure(Emitter<TransactionsState> emit, Failure failure) {
    final currentState = state;
    if (currentState is TransactionsLoaded) {
      emit(currentState.copyWith(errorMessage: failure.message));
    } else {
      emit(TransactionsError(failure.message));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

sealed class TransactionsEvent extends Equatable {
  const TransactionsEvent();
}

final class MonthChanged extends TransactionsEvent {
  const MonthChanged(this.month);

  final DateTime month;

  @override
  List<Object?> get props => [month];
}

final class TransactionsRetryRequested extends TransactionsEvent {
  const TransactionsRetryRequested();

  @override
  List<Object?> get props => [];
}

final class TransactionDeleted extends TransactionsEvent {
  const TransactionDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

final class TransactionDeleteUndone extends TransactionsEvent {
  const TransactionDeleteUndone(this.transaction);

  final TransactionEntity transaction;

  @override
  List<Object?> get props => [transaction];
}

final class _TransactionsReceived extends TransactionsEvent {
  const _TransactionsReceived(this.transactions);

  final List<TransactionEntity> transactions;

  @override
  List<Object?> get props => [transactions];
}

final class _TransactionsWatchFailed extends TransactionsEvent {
  const _TransactionsWatchFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

sealed class TransactionsState extends Equatable {
  const TransactionsState();
}

final class TransactionsLoading extends TransactionsState {
  const TransactionsLoading();

  @override
  List<Object?> get props => [];
}

final class TransactionsLoaded extends TransactionsState {
  const TransactionsLoaded(this.transactions, {this.errorMessage});

  final List<TransactionEntity> transactions;
  final String? errorMessage;

  TransactionsLoaded copyWith({String? errorMessage}) =>
      TransactionsLoaded(transactions, errorMessage: errorMessage);

  @override
  List<Object?> get props => [transactions, errorMessage];
}

final class TransactionsError extends TransactionsState {
  const TransactionsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
