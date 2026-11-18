import 'dart:async';

import 'package:home_widget/home_widget.dart';
import 'package:injectable/injectable.dart';

import '../../features/budget/domain/budget_status.dart';
import '../../features/budget/domain/budget_use_cases.dart';
import '../../features/transactions/domain/transaction_use_cases.dart';
import '../database/daos/category_dao.dart';
import '../utils/money_format.dart';

abstract interface class WidgetSyncService {
  void startListening();
  Future<void> syncNow();
  Future<bool> requestPinWidget();
  Future<bool> isPinWidgetSupported();
  bool get isBalanceHidden;
  Future<void> setBalanceHidden(bool hidden);
  void dispose();
}

@Singleton(as: WidgetSyncService)
class WidgetSyncServiceImpl implements WidgetSyncService {
  WidgetSyncServiceImpl(
    this._watchBalance,
    this._watchBudgetStatus,
    this._categoryDao,
  );

  final WatchBalance _watchBalance;
  final WatchBudgetStatus _watchBudgetStatus;
  final CategoryDao _categoryDao;

  static const String _androidWidgetName = 'BudgetWidgetProvider';
  static const String _balanceTextKey = 'balance_text';
  static const String _balanceIsNegativeKey = 'balance_is_negative';
  static const String _budgetStatusTextKey = 'budget_status_text';
  static const String _budgetProgressKey = 'budget_progress_percent';
  static const String _isBalanceHiddenKey = 'is_balance_hidden';

  StreamSubscription<int>? _balanceSub;
  StreamSubscription<BudgetStatus>? _budgetSub;

  int _lastBalanceMinor = 0;
  BudgetStatus? _lastBudgetStatus;
  bool _isBalanceHidden = false;
  bool _initialized = false;

  @override
  bool get isBalanceHidden => _isBalanceHidden;

  @override
  void startListening() {
    if (_initialized) return;
    _initialized = true;

    unawaited(_initAndListen());
  }

  Future<void> _initAndListen() async {
    try {
      final savedHidden = await HomeWidget.getWidgetData<bool>(_isBalanceHiddenKey);
      _isBalanceHidden = savedHidden ?? false;
    } catch (_) {}

    _balanceSub = _watchBalance().listen(
      (balanceMinor) {
        _lastBalanceMinor = balanceMinor;
        unawaited(_pushToWidget());
      },
      onError: (_) {},
    );

    final now = DateTime.now();
    _budgetSub = _watchBudgetStatus(DateTime(now.year, now.month)).listen(
      (budgetStatus) {
        _lastBudgetStatus = budgetStatus;
        unawaited(_pushToWidget());
      },
      onError: (_) {},
    );
  }

  @override
  Future<void> setBalanceHidden(bool hidden) async {
    _isBalanceHidden = hidden;
    try {
      await HomeWidget.saveWidgetData<bool>(_isBalanceHiddenKey, hidden);
    } catch (_) {}
    await _pushToWidget();
  }

  @override
  Future<void> syncNow() => _pushToWidget();

  Future<void> _pushToWidget() async {
    try {
      final balanceStr = _isBalanceHidden
          ? '••••••'
          : formatMinor(_lastBalanceMinor);

      final isNegative = _lastBalanceMinor < 0;

      final budgetStatus = _lastBudgetStatus;
      String budgetStatusText;
      int budgetProgressPercent;

      if (budgetStatus == null || budgetStatus.level == BudgetLevel.notSet) {
        budgetStatusText = 'Budget: No limit set';
        budgetProgressPercent = 0;
      } else {
        final percent = (budgetStatus.progress * 100).round();
        budgetProgressPercent = percent;
        budgetStatusText =
            'Spent ${formatMinor(budgetStatus.spentMinor)} of ${formatMinor(budgetStatus.limitMinor!)} ($percent%)';
      }

      await HomeWidget.saveWidgetData<String>(_balanceTextKey, balanceStr);
      await HomeWidget.saveWidgetData<bool>(_balanceIsNegativeKey, isNegative);
      await HomeWidget.saveWidgetData<String>(_budgetStatusTextKey, budgetStatusText);
      await HomeWidget.saveWidgetData<int>(_budgetProgressKey, budgetProgressPercent);

      // Push top 3 categories for quick logging chips
      try {
        final topCategories = await _categoryDao.getTopUsedExpenseCategories(limit: 3);
        for (var i = 0; i < 3; i++) {
          if (i < topCategories.length) {
            final cat = topCategories[i];
            await HomeWidget.saveWidgetData<int>('cat_${i}_id', cat.id);
            await HomeWidget.saveWidgetData<String>('cat_${i}_name', cat.name);
            await HomeWidget.saveWidgetData<String>('cat_${i}_icon', cat.iconKey);
          } else {
            await HomeWidget.saveWidgetData<int>('cat_${i}_id', -1);
            await HomeWidget.saveWidgetData<String>('cat_${i}_name', '');
            await HomeWidget.saveWidgetData<String>('cat_${i}_icon', '');
          }
        }
      } catch (_) {}

      await HomeWidget.updateWidget(androidName: _androidWidgetName);
    } catch (_) {
      // In tests or non-supported platforms, ignore silently
    }
  }

  @override
  Future<bool> requestPinWidget() async {
    try {
      await HomeWidget.requestPinWidget(androidName: _androidWidgetName);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isPinWidgetSupported() async {
    try {
      final supported = await HomeWidget.isRequestPinWidgetSupported();
      return supported ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _balanceSub?.cancel();
    _budgetSub?.cancel();
    _initialized = false;
  }
}
