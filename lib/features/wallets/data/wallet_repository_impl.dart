import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/wallet_dao.dart';
import '../../../core/error/failures.dart';
import '../domain/wallet_entity.dart';
import '../domain/wallet_repository.dart';

@LazySingleton(as: WalletRepository)
class WalletRepositoryImpl implements WalletRepository {
  const WalletRepositoryImpl(this._walletDao);

  final WalletDao _walletDao;

  @override
  Stream<List<WalletEntity>> watchWallets() =>
      _walletDao.watchWalletsWithBalance().map(
            (rows) => rows
                .map(
                  (row) => WalletEntity(
                    id: row.id,
                    name: row.name,
                    iconKey: row.iconKey,
                    sortOrder: row.sortOrder,
                    isArchived: row.isArchived,
                    balanceMinor: row.balanceMinor,
                  ),
                )
                .toList(),
          );

  @override
  Stream<int?> watchWalletBalance(int walletId) =>
      _walletDao.watchWalletBalance(walletId);

  @override
  Stream<int?> watchTotalBalance() => _walletDao.watchTotalBalance();

  @override
  Future<Either<Failure, Unit>> addWallet(WalletDraft draft) =>
      _persist(
        () => _walletDao.insert(
          WalletsCompanion.insert(
            name: draft.name,
            iconKey: draft.iconKey,
            sortOrder: Value(draft.sortOrder),
          ),
        ),
        'Could not add the wallet',
      );

  @override
  Future<Either<Failure, Unit>> updateWallet(int id, WalletDraft draft) =>
      _persist(
        () => _walletDao.updateById(
          id,
          WalletsCompanion(
            name: Value(draft.name),
            iconKey: Value(draft.iconKey),
            sortOrder: Value(draft.sortOrder),
          ),
        ),
        'Could not update the wallet',
      );

  @override
  Future<Either<Failure, Unit>> archiveWallet(int id) async {
    try {
      final balance = await _walletDao.watchWalletBalance(id).first;
      if (balance != null && balance != 0) {
        return const Left(
          ValidationFailure('Cannot archive a wallet with a non-zero balance.'),
        );
      }
      final changedRows = await _walletDao.archiveById(id);
      if (changedRows == 0) {
        return const Left(PersistenceFailure('Wallet not found.'));
      }
      return const Right(unit);
    } on Exception catch (error) {
      return Left(PersistenceFailure('Could not archive the wallet: $error'));
    }
  }

  @override
  Future<Either<Failure, Unit>> addTransfer(TransferDraft draft) async {
    try {
      if (draft.fromWalletId == draft.toWalletId) {
        return const Left(
          ValidationFailure('Cannot transfer to the same wallet.'),
        );
      }
      if (draft.amountMinor <= 0) {
        return const Left(
          ValidationFailure('Transfer amount must be positive.'),
        );
      }
      final changedRows = await _walletDao.insertTransfer(
        TransfersCompanion.insert(
          fromWalletId: draft.fromWalletId,
          toWalletId: draft.toWalletId,
          amountMinor: draft.amountMinor,
          note: Value(draft.note),
          createdAt: draft.createdAt ?? DateTime.now(),
        ),
      );
      if (changedRows == 0) {
        return const Left(PersistenceFailure('Could not create the transfer.'));
      }
      return const Right(unit);
    } on Exception catch (error) {
      return Left(PersistenceFailure('Could not create the transfer: $error'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteTransfer(int id) => _persist(
        () => _walletDao.deleteTransferById(id),
        'Could not delete the transfer',
      );

  @override
  Future<int?> getSelectedWalletId() async {
    final value = await _walletDao.getSetting('selected_wallet_id');
    return value != null ? int.tryParse(value) : null;
  }

  @override
  Future<Either<Failure, Unit>> setSelectedWalletId(int? walletId) async {
    try {
      if (walletId == null) {
        await _walletDao.setSetting('selected_wallet_id', 'all');
      } else {
        await _walletDao.setSetting('selected_wallet_id', walletId.toString());
      }
      return const Right(unit);
    } on Exception catch (error) {
      return Left(PersistenceFailure('Could not save wallet selection: $error'));
    }
  }

  @override
  Future<int?> getLastUsedWalletId() async {
    final value = await _walletDao.getSetting('last_used_wallet_id');
    return value != null ? int.tryParse(value) : null;
  }

  @override
  Future<Either<Failure, Unit>> setLastUsedWalletId(int walletId) async {
    try {
      await _walletDao.setSetting('last_used_wallet_id', walletId.toString());
      return const Right(unit);
    } on Exception catch (error) {
      return Left(PersistenceFailure('Could not save last used wallet: $error'));
    }
  }

  Future<Either<Failure, Unit>> _persist(
    Future<int> Function() operation,
    String message,
  ) async {
    try {
      final changedRows = await operation();
      if (changedRows == 0) {
        return Left(PersistenceFailure('$message: not found.'));
      }
      return const Right(unit);
    } on Exception catch (error) {
      return Left(PersistenceFailure('$message: $error'));
    }
  }
}
