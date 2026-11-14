import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../app_database.dart';

@lazySingleton
class WalletDao extends DatabaseAccessor<AppDatabase> {
  WalletDao(super.db);

  Stream<List<Wallet>> watchActiveWallets() {
    final query = select(db.wallets)
      ..where((wallet) => wallet.isArchived.equals(false))
      ..orderBy([(wallet) => OrderingTerm.asc(wallet.sortOrder)]);
    return query.watch();
  }

  Stream<List<Wallet>> watchAllWallets() {
    final query = select(db.wallets)
      ..orderBy([(wallet) => OrderingTerm.asc(wallet.sortOrder)]);
    return query.watch();
  }

  Stream<Wallet?> watchWalletById(int id) {
    final query = select(db.wallets)..where((wallet) => wallet.id.equals(id));
    return query.watchSingleOrNull();
  }

  Stream<int?> watchWalletBalance(int walletId) {
    return customSelect(
      '''
        SELECT COALESCE(
          SUM(CASE 
            WHEN type = ? THEN amount_minor 
            ELSE -amount_minor 
          END), 0
        ) +
        COALESCE(
          (SELECT COALESCE(SUM(amount_minor), 0) 
           FROM transfers 
           WHERE to_wallet_id = ?),
          0
        ) -
        COALESCE(
          (SELECT COALESCE(SUM(amount_minor), 0) 
           FROM transfers 
           WHERE from_wallet_id = ?),
          0
        ) AS balance_minor
        FROM transactions
        WHERE wallet_id = ?
      ''',
      variables: [
        Variable<int>(TransactionType.income.index),
        Variable<int>(walletId),
        Variable<int>(walletId),
        Variable<int>(walletId),
      ],
      readsFrom: {db.transactions, db.transfers},
    ).watchSingle().map((row) => row.read<int>('balance_minor'));
  }

  Stream<int?> watchTotalBalance() {
    return customSelect(
      '''
        SELECT COALESCE(
          SUM(CASE 
            WHEN type = ? THEN amount_minor 
            ELSE -amount_minor 
          END), 0
        ) AS balance_minor
        FROM transactions
      ''',
      variables: [Variable<int>(TransactionType.income.index)],
      readsFrom: {db.transactions},
    ).watchSingle().map((row) => row.read<int>('balance_minor'));
  }

  Stream<List<WalletWithBalance>> watchWalletsWithBalance() {
    return customSelect(
      '''
        SELECT 
          w.id,
          w.name,
          w.icon_key,
          w.sort_order,
          w.is_archived,
          COALESCE(
            (
              SELECT COALESCE(SUM(CASE 
                WHEN t.type = ? THEN t.amount_minor 
                ELSE -t.amount_minor 
              END), 0)
              FROM transactions t
              WHERE t.wallet_id = w.id
            ) +
            COALESCE(
              (SELECT COALESCE(SUM(amount_minor), 0) 
               FROM transfers 
               WHERE to_wallet_id = w.id),
              0
            ) -
            COALESCE(
              (SELECT COALESCE(SUM(amount_minor), 0) 
               FROM transfers 
               WHERE from_wallet_id = w.id),
              0
            ),
            0
          ) as balance_minor
        FROM wallets w
        ORDER BY w.sort_order
      ''',
      variables: [Variable<int>(TransactionType.income.index)],
      readsFrom: {db.wallets, db.transactions, db.transfers},
    ).watch().map((rows) => rows.map((row) {
      return WalletWithBalance(
        id: row.read<int>('id'),
        name: row.read<String>('name'),
        iconKey: row.read<String>('icon_key'),
        sortOrder: row.read<int>('sort_order'),
        isArchived: row.read<bool>('is_archived'),
        balanceMinor: row.read<int>('balance_minor'),
      );
    }).toList());
  }

  Future<int> insert(WalletsCompanion wallet) =>
      into(db.wallets).insert(wallet);

  Future<int> updateById(int id, WalletsCompanion wallet) => (update(
    db.wallets,
  )..where((row) => row.id.equals(id))).write(wallet);

  Future<int> archiveById(int id) => (update(
    db.wallets,
  )..where((row) => row.id.equals(id))).write(
        WalletsCompanion(isArchived: const Value(true)));

  Future<int> insertTransfer(TransfersCompanion transfer) =>
      into(db.transfers).insert(transfer);

  Future<int> deleteTransferById(int id) => (delete(
    db.transfers,
  )..where((transfer) => transfer.id.equals(id))).go();

  Future<String?> getSetting(String key) async {
    final result = await (select(db.appSettings)
          ..where((setting) => setting.key.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  Future<void> setSetting(String key, String value) async {
    final existing = await (select(db.appSettings)
          ..where((setting) => setting.key.equals(key)))
        .getSingleOrNull();
    if (existing == null) {
      await into(db.appSettings).insert(
        AppSettingsCompanion.insert(key: key, value: value),
      );
    } else {
      await (update(db.appSettings)
            ..where((setting) => setting.key.equals(key)))
          .write(AppSettingsCompanion(value: Value(value)));
    }
  }
}

class WalletWithBalance {
  const WalletWithBalance({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.sortOrder,
    required this.isArchived,
    required this.balanceMinor,
  });

  final int id;
  final String name;
  final String iconKey;
  final int sortOrder;
  final bool isArchived;
  final int balanceMinor;
}
