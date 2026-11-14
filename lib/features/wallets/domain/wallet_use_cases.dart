import 'package:injectable/injectable.dart';

import '../domain/wallet_entity.dart';
import '../domain/wallet_repository.dart';

@injectable
class WatchWallets {
  const WatchWallets(this._repository);

  final WalletRepository _repository;

  Stream<List<WalletEntity>> call() => _repository.watchWallets();
}

@injectable
class WatchWalletBalance {
  const WatchWalletBalance(this._repository);

  final WalletRepository _repository;

  Stream<int?> call(int walletId) => _repository.watchWalletBalance(walletId);
}

@injectable
class WatchTotalBalance {
  const WatchTotalBalance(this._repository);

  final WalletRepository _repository;

  Stream<int?> call() => _repository.watchTotalBalance();
}

@injectable
class AddWallet {
  const AddWallet(this._repository);

  final WalletRepository _repository;

  Future<void> call(WalletDraft draft) async =>
      (await _repository.addWallet(draft)).fold(
        (failure) => throw Exception(failure.message),
        (_) {},
      );
}

@injectable
class UpdateWallet {
  const UpdateWallet(this._repository);

  final WalletRepository _repository;

  Future<void> call(int id, WalletDraft draft) async =>
      (await _repository.updateWallet(id, draft)).fold(
        (failure) => throw Exception(failure.message),
        (_) {},
      );
}

@injectable
class ArchiveWallet {
  const ArchiveWallet(this._repository);

  final WalletRepository _repository;

  Future<void> call(int id) async =>
      (await _repository.archiveWallet(id)).fold(
        (failure) => throw Exception(failure.message),
        (_) {},
      );
}

@injectable
class AddTransfer {
  const AddTransfer(this._repository);

  final WalletRepository _repository;

  Future<void> call(TransferDraft draft) async =>
      (await _repository.addTransfer(draft)).fold(
        (failure) => throw Exception(failure.message),
        (_) {},
      );
}

@injectable
class DeleteTransfer {
  const DeleteTransfer(this._repository);

  final WalletRepository _repository;

  Future<void> call(int id) async =>
      (await _repository.deleteTransfer(id)).fold(
        (failure) => throw Exception(failure.message),
        (_) {},
      );
}

@injectable
class GetSelectedWalletId {
  const GetSelectedWalletId(this._repository);

  final WalletRepository _repository;

  Future<int?> call() => _repository.getSelectedWalletId();
}

@injectable
class SetSelectedWalletId {
  const SetSelectedWalletId(this._repository);

  final WalletRepository _repository;

  Future<void> call(int? walletId) async =>
      (await _repository.setSelectedWalletId(walletId)).fold(
        (failure) => throw Exception(failure.message),
        (_) {},
      );
}

@injectable
class GetLastUsedWalletId {
  const GetLastUsedWalletId(this._repository);

  final WalletRepository _repository;

  Future<int?> call() => _repository.getLastUsedWalletId();
}

@injectable
class SetLastUsedWalletId {
  const SetLastUsedWalletId(this._repository);

  final WalletRepository _repository;

  Future<void> call(int walletId) async =>
      (await _repository.setLastUsedWalletId(walletId)).fold(
        (failure) => throw Exception(failure.message),
        (_) {},
      );
}
