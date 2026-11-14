import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../domain/wallet_entity.dart';
import '../domain/wallet_use_cases.dart';

class WalletState extends Equatable {
  const WalletState({
    this.wallets = const [],
    this.selectedWalletId,
    this.totalBalanceMinor = 0,
    this.isLoading = true,
    this.errorMessage,
  });

  final List<WalletEntity> wallets;
  final int? selectedWalletId;
  final int totalBalanceMinor;
  final bool isLoading;
  final String? errorMessage;

  WalletEntity? get selectedWallet {
    if (selectedWalletId == null) return null;
    for (final w in wallets) {
      if (w.id == selectedWalletId) return w;
    }
    return null;
  }

  WalletState copyWith({
    List<WalletEntity>? wallets,
    Object? selectedWalletId = _sentinel,
    int? totalBalanceMinor,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) {
    return WalletState(
      wallets: wallets ?? this.wallets,
      selectedWalletId: selectedWalletId == _sentinel
          ? this.selectedWalletId
          : selectedWalletId as int?,
      totalBalanceMinor: totalBalanceMinor ?? this.totalBalanceMinor,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
        wallets,
        selectedWalletId,
        totalBalanceMinor,
        isLoading,
        errorMessage,
      ];
}

const Object _sentinel = Object();

@injectable
class WalletCubit extends Cubit<WalletState> {
  WalletCubit(
    this._watchWallets,
    this._watchTotalBalance,
    this._addWallet,
    this._updateWallet,
    this._archiveWallet,
    this._addTransfer,
    this._getSelectedWalletId,
    this._setSelectedWalletId,
  ) : super(const WalletState()) {
    _init();
  }

  final WatchWallets _watchWallets;
  final WatchTotalBalance _watchTotalBalance;
  final AddWallet _addWallet;
  final UpdateWallet _updateWallet;
  final ArchiveWallet _archiveWallet;
  final AddTransfer _addTransfer;
  final GetSelectedWalletId _getSelectedWalletId;
  final SetSelectedWalletId _setSelectedWalletId;

  StreamSubscription<List<WalletEntity>>? _walletsSub;
  StreamSubscription<int?>? _totalBalanceSub;

  Future<void> _init() async {
    final selectedId = await _getSelectedWalletId();

    _walletsSub = _watchWallets().listen((wallets) {
      emit(state.copyWith(
        wallets: wallets,
        isLoading: false,
      ));
    });

    _totalBalanceSub = _watchTotalBalance().listen((total) {
      emit(state.copyWith(
        totalBalanceMinor: total ?? 0,
      ));
    });

    emit(state.copyWith(selectedWalletId: () => selectedId));
  }

  Future<void> selectWallet(int? walletId) async {
    emit(state.copyWith(selectedWalletId: () => walletId));
    await _setSelectedWalletId(walletId);
  }

  Future<bool> createWallet({
    required String name,
    required String iconKey,
  }) async {
    try {
      final sortOrder = state.wallets.length;
      await _addWallet(WalletDraft(
        name: name,
        iconKey: iconKey,
        sortOrder: sortOrder,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: () => e.toString()));
      return false;
    }
  }

  Future<bool> editWallet({
    required int id,
    required String name,
    required String iconKey,
  }) async {
    try {
      final existing = state.wallets.firstWhere((w) => w.id == id);
      await _updateWallet(
        id,
        WalletDraft(
          name: name,
          iconKey: iconKey,
          sortOrder: existing.sortOrder,
        ),
      );
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: () => e.toString()));
      return false;
    }
  }

  Future<bool> archiveWallet(int id) async {
    try {
      await _archiveWallet(id);
      if (state.selectedWalletId == id) {
        await selectWallet(null);
      }
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: () => e.toString()));
      return false;
    }
  }

  Future<bool> createTransfer(TransferDraft draft) async {
    try {
      await _addTransfer(draft);
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: () => e.toString()));
      return false;
    }
  }

  @override
  Future<void> close() async {
    await _walletsSub?.cancel();
    await _totalBalanceSub?.cancel();
    return super.close();
  }
}
