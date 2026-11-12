import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failures.dart';
import '../domain/budget_status.dart';
import '../domain/budget_use_cases.dart';

@injectable
class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  BudgetBloc(this._watchStatus, this._setMonthlyLimit)
    : super(BudgetLoading(DateTime(2000))) {
    on<BudgetMonthChanged>(_onMonthChanged);
    on<BudgetRetryRequested>((event, emit) {
      final month = _month;
      if (month != null) return _watch(month, emit);
    });
    on<BudgetLimitSaveRequested>(_onLimitSaveRequested);
    on<_BudgetReceived>((event, emit) {
      if (_sameMonth(event.month, _month)) {
        final current = state;
        emit(
          BudgetLoaded(
            month: event.month,
            status: event.status,
            isSaving: current is BudgetLoaded && current.isSaving,
            isSaved: current is BudgetLoaded && current.isSaved,
            errorMessage: current is BudgetLoaded ? current.errorMessage : null,
          ),
        );
      }
    });
    on<_BudgetWatchFailed>((event, emit) {
      if (_sameMonth(event.month, _month)) {
        emit(BudgetError(month: event.month, message: event.message));
      }
    });
  }

  final WatchBudgetStatus _watchStatus;
  final SetMonthlyLimit _setMonthlyLimit;
  StreamSubscription<BudgetStatus>? _subscription;
  DateTime? _month;

  Future<void> _onMonthChanged(
    BudgetMonthChanged event,
    Emitter<BudgetState> emit,
  ) => _watch(event.month, emit);

  Future<void> _watch(DateTime month, Emitter<BudgetState> emit) async {
    _month = DateTime(month.year, month.month);
    emit(BudgetLoading(_month!));
    await _subscription?.cancel();
    if (emit.isDone) return;
    _subscription = _watchStatus(_month!).listen(
      (status) {
        if (!isClosed) add(_BudgetReceived(_month!, status));
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!isClosed) add(_BudgetWatchFailed(_month!, error.toString()));
      },
    );
  }

  Future<void> _onLimitSaveRequested(
    BudgetLimitSaveRequested event,
    Emitter<BudgetState> emit,
  ) async {
    final month = _month;
    if (month == null) return;
    final current = state;
    if (current is BudgetLoaded) {
      emit(current.copyWith(isSaving: true, isSaved: false, clearError: true));
    }

    final result = await _setMonthlyLimit(
      month: month,
      amountMinor: event.amountMinor,
    );
    result.fold((failure) => _emitFailure(emit, failure), (_) {
      final latest = state;
      if (latest is BudgetLoaded && _sameMonth(latest.month, month)) {
        emit(latest.copyWith(isSaving: false, isSaved: true, clearError: true));
      }
    });
  }

  void _emitFailure(Emitter<BudgetState> emit, Failure failure) {
    final current = state;
    if (current is BudgetLoaded) {
      emit(current.copyWith(isSaving: false, errorMessage: failure.message));
    } else {
      emit(
        BudgetError(month: _month ?? DateTime.now(), message: failure.message),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

bool _sameMonth(DateTime first, DateTime? second) =>
    second != null && first.year == second.year && first.month == second.month;

sealed class BudgetEvent extends Equatable {
  const BudgetEvent();
}

final class BudgetMonthChanged extends BudgetEvent {
  const BudgetMonthChanged(this.month);

  final DateTime month;

  @override
  List<Object?> get props => [month];
}

final class BudgetRetryRequested extends BudgetEvent {
  const BudgetRetryRequested();

  @override
  List<Object?> get props => [];
}

final class BudgetLimitSaveRequested extends BudgetEvent {
  const BudgetLimitSaveRequested(this.amountMinor);

  final int amountMinor;

  @override
  List<Object?> get props => [amountMinor];
}

final class _BudgetReceived extends BudgetEvent {
  const _BudgetReceived(this.month, this.status);

  final DateTime month;
  final BudgetStatus status;

  @override
  List<Object?> get props => [month, status];
}

final class _BudgetWatchFailed extends BudgetEvent {
  const _BudgetWatchFailed(this.month, this.message);

  final DateTime month;
  final String message;

  @override
  List<Object?> get props => [month, message];
}

sealed class BudgetState extends Equatable {
  const BudgetState();
}

final class BudgetLoading extends BudgetState {
  const BudgetLoading(this.month);

  final DateTime month;

  @override
  List<Object?> get props => [month];
}

final class BudgetLoaded extends BudgetState {
  const BudgetLoaded({
    required this.month,
    required this.status,
    this.isSaving = false,
    this.isSaved = false,
    this.errorMessage,
  });

  final DateTime month;
  final BudgetStatus status;
  final bool isSaving;
  final bool isSaved;
  final String? errorMessage;

  BudgetLoaded copyWith({
    BudgetStatus? status,
    bool? isSaving,
    bool? isSaved,
    String? errorMessage,
    bool clearError = false,
  }) => BudgetLoaded(
    month: month,
    status: status ?? this.status,
    isSaving: isSaving ?? this.isSaving,
    isSaved: isSaved ?? this.isSaved,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [month, status, isSaving, isSaved, errorMessage];
}

final class BudgetError extends BudgetState {
  const BudgetError({required this.month, required this.message});

  final DateTime month;
  final String message;

  @override
  List<Object?> get props => [month, message];
}
