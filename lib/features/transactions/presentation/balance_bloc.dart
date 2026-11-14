import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../domain/transaction_use_cases.dart';

@injectable
class BalanceBloc extends Bloc<BalanceEvent, BalanceState> {
  BalanceBloc(this._watchBalance) : super(const BalanceLoading()) {
    on<BalanceStarted>((event, emit) => _watch(emit));
    on<BalanceRetryRequested>((event, emit) => _watch(emit));
    on<_BalanceUpdated>(
      (event, emit) => emit(BalanceLoaded(event.balanceMinor)),
    );
    on<_BalanceFailed>((event, emit) => emit(BalanceError(event.message)));
  }

  final WatchBalance _watchBalance;
  StreamSubscription<int>? _subscription;

  Future<void> _watch(Emitter<BalanceState> emit) async {
    emit(const BalanceLoading());
    await _subscription?.cancel();
    if (emit.isDone) return;
    _subscription = _watchBalance().listen(
      (balance) {
        if (!isClosed) add(_BalanceUpdated(balance));
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!isClosed) add(_BalanceFailed(error.toString()));
      },
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

sealed class BalanceEvent extends Equatable {
  const BalanceEvent();
}

final class BalanceStarted extends BalanceEvent {
  const BalanceStarted();

  @override
  List<Object?> get props => [];
}

final class BalanceRetryRequested extends BalanceEvent {
  const BalanceRetryRequested();

  @override
  List<Object?> get props => [];
}

final class _BalanceUpdated extends BalanceEvent {
  const _BalanceUpdated(this.balanceMinor);

  final int balanceMinor;

  @override
  List<Object?> get props => [balanceMinor];
}

final class _BalanceFailed extends BalanceEvent {
  const _BalanceFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

sealed class BalanceState extends Equatable {
  const BalanceState();
}

final class BalanceLoading extends BalanceState {
  const BalanceLoading();

  @override
  List<Object?> get props => [];
}

final class BalanceLoaded extends BalanceState {
  const BalanceLoaded(this.balanceMinor);

  final int balanceMinor;
  bool get isNegative => balanceMinor < 0;

  @override
  List<Object?> get props => [balanceMinor];
}

final class BalanceError extends BalanceState {
  const BalanceError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
