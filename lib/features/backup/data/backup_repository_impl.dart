import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../core/database/app_database.dart';
import '../domain/backup_repository.dart';

@LazySingleton(as: BackupRepository)
class BackupRepositoryImpl implements BackupRepository {
  const BackupRepositoryImpl(this._db);

  final AppDatabase _db;

  static const int currentBackupVersion = 1;

  @override
  Future<String> createBackupJson() async {
    final wallets = await _db.select(_db.wallets).get();
    final categories = await _db.select(_db.categories).get();
    final transactions = await _db.select(_db.transactions).get();
    final transfers = await _db.select(_db.transfers).get();
    final recurringRules = await _db.select(_db.recurringRules).get();
    final monthlyLimits = await _db.select(_db.monthlyLimits).get();
    final appSettings = await _db.select(_db.appSettings).get();

    final payload = {
      'version': currentBackupVersion,
      'app': 'BudgetTracker',
      'exportedAt': DateTime.now().toIso8601String(),
      'data': {
        'wallets': wallets
            .map((w) => {
                  'id': w.id,
                  'name': w.name,
                  'iconKey': w.iconKey,
                  'sortOrder': w.sortOrder,
                  'isArchived': w.isArchived,
                })
            .toList(),
        'categories': categories
            .map((c) => {
                  'id': c.id,
                  'name': c.name,
                  'type': c.type.index,
                  'iconKey': c.iconKey,
                  'isDefault': c.isDefault,
                  'isArchived': c.isArchived,
                })
            .toList(),
        'transactions': transactions
            .map((t) => {
                  'id': t.id,
                  'type': t.type.index,
                  'amountMinor': t.amountMinor,
                  'categoryId': t.categoryId,
                  'walletId': t.walletId,
                  'title': t.title,
                  'createdAt': t.createdAt.toIso8601String(),
                  'recurringRuleId': t.recurringRuleId,
                  'recurringDueDate': t.recurringDueDate?.toIso8601String(),
                })
            .toList(),
        'transfers': transfers
            .map((tr) => {
                  'id': tr.id,
                  'fromWalletId': tr.fromWalletId,
                  'toWalletId': tr.toWalletId,
                  'amountMinor': tr.amountMinor,
                  'createdAt': tr.createdAt.toIso8601String(),
                  'note': tr.note,
                })
            .toList(),
        'recurringRules': recurringRules
            .map((r) => {
                  'id': r.id,
                  'type': r.type.index,
                  'amountMinor': r.amountMinor,
                  'categoryId': r.categoryId,
                  'walletId': r.walletId,
                  'title': r.title,
                  'dayOfMonth': r.dayOfMonth,
                  'startDate': r.startDate.toIso8601String(),
                  'endDate': r.endDate?.toIso8601String(),
                  'lastGeneratedDue': r.lastGeneratedDue?.toIso8601String(),
                  'isActive': r.isActive,
                })
            .toList(),
        'monthlyLimits': monthlyLimits
            .map((m) => {
                  'yearMonth': m.yearMonth,
                  'limitMinor': m.limitMinor,
                })
            .toList(),
        'appSettings': appSettings
            .map((s) => {
                  'key': s.key,
                  'value': s.value,
                })
            .toList(),
      },
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  @override
  Future<BackupSummary> inspectBackupJson(String rawJson) async {
    final Map<String, dynamic> root = jsonDecode(rawJson) as Map<String, dynamic>;
    if (root['app'] != 'BudgetTracker') {
      throw const FormatException('Invalid backup: App identifier does not match BudgetTracker');
    }

    final exportedAt = DateTime.tryParse(root['exportedAt'] as String? ?? '') ?? DateTime.now();
    final data = root['data'] as Map<String, dynamic>? ?? {};

    final wallets = (data['wallets'] as List?) ?? [];
    final categories = (data['categories'] as List?) ?? [];
    final transactions = (data['transactions'] as List?) ?? [];
    final recurringRules = (data['recurringRules'] as List?) ?? [];
    final monthlyLimits = (data['monthlyLimits'] as List?) ?? [];

    return BackupSummary(
      exportedAt: exportedAt,
      walletCount: wallets.length,
      categoryCount: categories.length,
      transactionCount: transactions.length,
      recurringRuleCount: recurringRules.length,
      monthlyLimitCount: monthlyLimits.length,
    );
  }

  @override
  Future<void> restoreFromJson(String rawJson) async {
    final Map<String, dynamic> root = jsonDecode(rawJson) as Map<String, dynamic>;
    if (root['app'] != 'BudgetTracker') {
      throw const FormatException('Invalid backup: App identifier does not match BudgetTracker');
    }

    final data = root['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const FormatException('Malformed backup: Missing data payload');
    }

    // Execute atomic restore
    await _db.transaction(() async {
      // Clear dependent child tables first to respect foreign keys
      await _db.delete(_db.transfers).go();
      await _db.delete(_db.transactions).go();
      await _db.delete(_db.recurringRules).go();
      await _db.delete(_db.monthlyLimits).go();
      await _db.delete(_db.appSettings).go();
      await _db.delete(_db.categories).go();
      await _db.delete(_db.wallets).go();

      // 1. Wallets
      final rawWallets = (data['wallets'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final w in rawWallets) {
        await _db.into(_db.wallets).insert(
              WalletsCompanion(
                id: Value(w['id'] as int),
                name: Value(w['name'] as String),
                iconKey: Value(w['iconKey'] as String),
                sortOrder: Value(w['sortOrder'] as int? ?? 0),
                isArchived: Value(w['isArchived'] as bool? ?? false),
              ),
            );
      }

      // 2. Categories
      final rawCategories = (data['categories'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final c in rawCategories) {
        await _db.into(_db.categories).insert(
              CategoriesCompanion(
                id: Value(c['id'] as int),
                name: Value(c['name'] as String),
                type: Value(TransactionType.values[c['type'] as int]),
                iconKey: Value(c['iconKey'] as String),
                isDefault: Value(c['isDefault'] as bool? ?? false),
                isArchived: Value(c['isArchived'] as bool? ?? false),
              ),
            );
      }

      // 3. Recurring Rules
      final rawRules = (data['recurringRules'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final r in rawRules) {
        await _db.into(_db.recurringRules).insert(
              RecurringRulesCompanion(
                id: Value(r['id'] as int),
                type: Value(TransactionType.values[r['type'] as int]),
                amountMinor: Value(r['amountMinor'] as int),
                categoryId: Value(r['categoryId'] as int),
                walletId: Value(r['walletId'] as int? ?? 1),
                title: Value(r['title'] as String?),
                dayOfMonth: Value(r['dayOfMonth'] as int),
                startDate: Value(DateTime.parse(r['startDate'] as String)),
                endDate: Value(r['endDate'] != null ? DateTime.parse(r['endDate'] as String) : null),
                lastGeneratedDue: Value(r['lastGeneratedDue'] != null
                    ? DateTime.parse(r['lastGeneratedDue'] as String)
                    : null),
                isActive: Value(r['isActive'] as bool? ?? true),
              ),
            );
      }

      // 4. Transactions
      final rawTransactions = (data['transactions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final t in rawTransactions) {
        await _db.into(_db.transactions).insert(
              TransactionsCompanion(
                id: Value(t['id'] as int),
                type: Value(TransactionType.values[t['type'] as int]),
                amountMinor: Value(t['amountMinor'] as int),
                categoryId: Value(t['categoryId'] as int),
                walletId: Value(t['walletId'] as int? ?? 1),
                title: Value(t['title'] as String?),
                createdAt: Value(DateTime.parse(t['createdAt'] as String)),
                recurringRuleId: Value(t['recurringRuleId'] as int?),
                recurringDueDate: Value(t['recurringDueDate'] != null
                    ? DateTime.parse(t['recurringDueDate'] as String)
                    : null),
              ),
            );
      }

      // 5. Transfers
      final rawTransfers = (data['transfers'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final tr in rawTransfers) {
        await _db.into(_db.transfers).insert(
              TransfersCompanion(
                id: Value(tr['id'] as int),
                fromWalletId: Value(tr['fromWalletId'] as int),
                toWalletId: Value(tr['toWalletId'] as int),
                amountMinor: Value(tr['amountMinor'] as int),
                createdAt: Value(DateTime.parse(tr['createdAt'] as String)),
                note: Value(tr['note'] as String?),
              ),
            );
      }

      // 6. Monthly Limits
      final rawLimits = (data['monthlyLimits'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final m in rawLimits) {
        await _db.into(_db.monthlyLimits).insert(
              MonthlyLimitsCompanion(
                yearMonth: Value(m['yearMonth'] as String),
                limitMinor: Value(m['limitMinor'] as int),
              ),
            );
      }

      // 7. App Settings
      final rawSettings = (data['appSettings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      for (final s in rawSettings) {
        await _db.into(_db.appSettings).insert(
              AppSettingsCompanion(
                key: Value(s['key'] as String),
                value: Value(s['value'] as String),
              ),
            );
      }
    });
  }
}
