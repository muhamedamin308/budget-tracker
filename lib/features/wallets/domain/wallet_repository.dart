import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import 'wallet_entity.dart';

abstract class WalletRepository {
  Stream<List<WalletEntity>> watchWallets();
  Stream<int?> watchWalletBalance(int walletId);
  Stream<int?> watchTotalBalance();
  Future<Either<Failure, Unit>> addWallet(WalletDraft draft);
  Future<Either<Failure, Unit>> updateWallet(int id, WalletDraft draft);
  Future<Either<Failure, Unit>> archiveWallet(int id);
  Future<Either<Failure, Unit>> addTransfer(TransferDraft draft);
  Future<Either<Failure, Unit>> deleteTransfer(int id);
  Future<int?> getSelectedWalletId();
  Future<Either<Failure, Unit>> setSelectedWalletId(int? walletId);
  Future<int?> getLastUsedWalletId();
  Future<Either<Failure, Unit>> setLastUsedWalletId(int walletId);
}
