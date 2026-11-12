import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../domain/transaction_use_cases.dart';

@injectable
class WalletBloc extends Bloc<WalletEvent, WalletState> {
  WalletBloc(this._watchBalance) : super(const WalletLoading()) {
    on<WalletStarted>((event, emit) => _watch(emit));
    on<WalletRetryRequested>((event, emit) => _watch(emit));
    on<_BalanceUpdated>(
      (event, emit) => emit(WalletLoaded(event.balanceMinor)),
    );
    on<_BalanceFailed>((event, emit) => emit(WalletError(event.message)));
  }

  final WatchBalance _watchBalance;
  StreamSubscription<int>? _subscription;

  Future<void> _watch(Emitter<WalletState> emit) async {
    emit(const WalletLoading());
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

sealed class WalletEvent extends Equatable {
  const WalletEvent();
}

final class WalletStarted extends WalletEvent {
  const WalletStarted();

  @override
  List<Object?> get props => [];
}

final class WalletRetryRequested extends WalletEvent {
  const WalletRetryRequested();

  @override
  List<Object?> get props => [];
}

final class _BalanceUpdated extends WalletEvent {
  const _BalanceUpdated(this.balanceMinor);

  final int balanceMinor;

  @override
  List<Object?> get props => [balanceMinor];
}

final class _BalanceFailed extends WalletEvent {
  const _BalanceFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

sealed class WalletState extends Equatable {
  const WalletState();
}

final class WalletLoading extends WalletState {
  const WalletLoading();

  @override
  List<Object?> get props => [];
}

final class WalletLoaded extends WalletState {
  const WalletLoaded(this.balanceMinor);

  final int balanceMinor;
  bool get isNegative => balanceMinor < 0;

  @override
  List<Object?> get props => [balanceMinor];
}

final class WalletError extends WalletState {
  const WalletError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
