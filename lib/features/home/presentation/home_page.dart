import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/money_format.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../core/widgets/entrance_animation.dart';
import '../../../core/widgets/inline_error_banner.dart';
import '../../budget/domain/budget_status.dart';
import '../../budget/presentation/budget_bloc.dart';
import '../../shell/presentation/month_cubit.dart';
import '../../transactions/domain/transaction_entity.dart';
import '../../transactions/presentation/transaction_form_sheet.dart';
import '../../transactions/presentation/transactions_bloc.dart';
import '../../transactions/presentation/balance_bloc.dart';
import '../../wallets/presentation/wallet_cubit.dart';
import '../../wallets/presentation/wallet_selector_bar.dart';
import '../../wallets/presentation/transfer_form_sheet.dart';

abstract final class _S {
  static const balance = 'Balance';
  static const overdrawn = 'Overdrawn';
  static const belowZero = 'Below zero. Add income or reduce spending.';
  static const income = 'Income';
  static const expense = 'Expense';
  static const transfer = 'Transfer';
  static const noLimit = 'No monthly limit set';
  static const overBudget = 'Over budget';
  static const couldNotLoadBalance = 'Could not load balance';
  static const retryBalance = 'Retry balance';
  static const retry = 'Retry';
  static const previousMonth = 'Previous month';
  static const nextMonth = 'Next month';
  static const today = 'Today';
  static const yesterday = 'Yesterday';
  static const emptyTitle = 'No transactions this month';
  static const emptyBody = 'Use Income or Expense above to add one.';
  static const deleteTitle = 'Delete transaction';
  static const deleteBody = 'Are you sure you want to delete this transaction?';
  static const cancel = 'Cancel';
  static const delete = 'Delete';

  static String spentOf(String spent, String limit) => 'Spent $spent of $limit';

  static String percent(double fraction) =>
      '${(fraction * 100).toStringAsFixed(0)}%';

  static String monthSpent(String amount) => 'Spent $amount';
}

Future<void> _openForm(
  BuildContext context,
  TransactionKind kind, [
  TransactionEntity? transaction,
]) => showTransactionForm(context, kind: kind, transaction: transaction);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<WalletCubit>()),
        BlocProvider(
          create: (_) => getIt<BalanceBloc>()..add(const BalanceStarted()),
        ),
        BlocProvider(
          create: (context) =>
              getIt<TransactionsBloc>()
                ..add(MonthChanged(context.read<MonthCubit>().state)),
        ),
      ],
      child: const _HomePageView(),
    );
  }
}

class _HomePageView extends StatelessWidget {
  const _HomePageView();

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).scaffoldBackgroundColor;

    return BlocListener<MonthCubit, DateTime>(
      listener: (context, month) =>
          context.read<TransactionsBloc>().add(MonthChanged(month)),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Column(
                  children: [
                    const EntranceAnimation(child: WalletSelectorBar()),
                    const SizedBox(height: 12),
                    EntranceAnimation(
                      delay: const Duration(milliseconds: 60),
                      child: _HeroCard(
                        onAdd: (kind) => _openForm(context, kind),
                        onRetry: () => context.read<BalanceBloc>().add(
                          const BalanceRetryRequested(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _MonthBarDelegate(background: background),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            BlocBuilder<TransactionsBloc, TransactionsState>(
              builder: (context, state) => switch (state) {
                TransactionsLoading() => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                TransactionsError(:final message) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: _RetryView(
                    message: message,
                    onRetry: () => context.read<TransactionsBloc>().add(
                      const TransactionsRetryRequested(),
                    ),
                  ),
                ),
                TransactionsLoaded(:final transactions, :final errorMessage) =>
                  transactions.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyState(errorMessage: errorMessage),
                        )
                      : _TransactionsSliver(
                          transactions: transactions,
                          errorMessage: errorMessage,
                          onEdit: (transaction) =>
                              _openForm(context, transaction.kind, transaction),
                        ),
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero card: balance + budget meter + quick actions in one surface
// ---------------------------------------------------------------------------

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onAdd, required this.onRetry});

  final ValueChanged<TransactionKind> onAdd;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<BalanceBloc, BalanceState>(
      builder: (context, state) {
        final balanceMinor = switch (state) {
          BalanceLoaded(:final balanceMinor) => balanceMinor,
          _ => 0,
        };
        final isNegative = balanceMinor < 0;
        final canAdd = state is BalanceLoaded;

        final gradient = isDark
            ? AppTheme.darkCardGradient
            : isNegative
            ? AppTheme.expenseGradient
            : AppTheme.primaryGradient;
        final glow = isNegative
            ? AppTheme.expenseCoral
            : AppTheme.primaryEmerald;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.45)
                    : glow.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -36,
                top: -44,
                child: _Orb(size: 150, alpha: isDark ? 0.05 : 0.09),
              ),
              Positioned(
                right: 40,
                bottom: -56,
                child: _Orb(size: 110, alpha: isDark ? 0.04 : 0.07),
              ),
              Material(
                type: MaterialType.transparency,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _S.balance,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                              letterSpacing: 0.2,
                            ),
                          ),
                          if (isNegative) const _OverdrawnBadge(),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _AmountView(
                        state: state,
                        balanceMinor: balanceMinor,
                        onRetry: onRetry,
                      ),
                      if (isNegative) ...[
                        const SizedBox(height: 12),
                        const _HeroNote(
                          icon: Icons.info_outline_rounded,
                          text: _S.belowZero,
                        ),
                      ],
                      const SizedBox(height: 14),
                      const _BudgetMeter(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _HeroAction(
                              icon: Icons.add_rounded,
                              label: _S.income,
                              onTap: canAdd
                                  ? () => onAdd(TransactionKind.income)
                                  : null,
                            ),
                          ),
                          Expanded(
                            child: _HeroAction(
                              icon: Icons.remove_rounded,
                              label: _S.expense,
                              onTap: canAdd
                                  ? () => onAdd(TransactionKind.expense)
                                  : null,
                            ),
                          ),
                          Expanded(
                            child: _HeroAction(
                              icon: Icons.swap_horiz_rounded,
                              label: _S.transfer,
                              onTap: () => showTransferFormSheet(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AmountView extends StatelessWidget {
  const _AmountView({
    required this.state,
    required this.balanceMinor,
    required this.onRetry,
  });

  final BalanceState state;
  final int balanceMinor;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state is BalanceLoading) {
      return const SizedBox(
        height: 44,
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }

    if (state is BalanceError) {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                _S.couldNotLoadBalance,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              tooltip: _S.retryBalance,
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
          ],
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        formatMinor(balanceMinor),
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -1.2,
          height: 1.05,
        ),
      ),
    );
  }
}

class _OverdrawnBadge extends StatelessWidget {
  const _OverdrawnBadge();

  @override
  Widget build(BuildContext context) {
    return PulsingBadge(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_rounded, size: 13, color: Colors.white),
            SizedBox(width: 4),
            Text(
              _S.overdrawn,
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroNote extends StatelessWidget {
  const _HeroNote({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetMeter extends StatelessWidget {
  const _BudgetMeter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, state) {
        if (state is! BudgetLoaded) return const SizedBox.shrink();
        final status = state.status;
        final limit = status.limitMinor;

        if (limit == null) {
          return Text(
            _S.noLimit,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          );
        }

        final exceeded = status.level == BudgetLevel.exceeded;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (exceeded) ...[
                  const Icon(
                    Icons.warning_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    exceeded
                        ? _S.overBudget
                        : _S.spentOf(
                            formatMinor(status.spentMinor),
                            formatMinor(limit),
                          ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  _S.percent(status.progress),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: status.progress.clamp(0.0, 1.0).toDouble(),
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pinned month bar
// ---------------------------------------------------------------------------

class _MonthBarDelegate extends SliverPersistentHeaderDelegate {
  const _MonthBarDelegate({required this.background});

  final Color background;

  @override
  double get minExtent => 56;

  @override
  double get maxExtent => 56;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final outline = Theme.of(context).colorScheme.outlineVariant;
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          border: overlapsContent
              ? Border(
                  bottom: BorderSide(color: outline.withValues(alpha: 0.5)),
                )
              : null,
        ),
        child: const _MonthBar(),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _MonthBarDelegate oldDelegate) =>
      oldDelegate.background != background;
}

class _MonthBar extends StatelessWidget {
  const _MonthBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            tooltip: _S.previousMonth,
            onPressed: () => context.read<MonthCubit>().previous(),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          BlocBuilder<MonthCubit, DateTime>(
            builder: (context, month) => Text(
              DateFormat.yMMMM().format(month),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: _S.nextMonth,
            onPressed: () => context.read<MonthCubit>().next(),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          const Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _MonthSpent(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSpent extends StatelessWidget {
  const _MonthSpent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<TransactionsBloc, TransactionsState>(
      builder: (context, state) {
        if (state is! TransactionsLoaded) return const SizedBox.shrink();
        final spent = state.transactions
            .where((t) => t.kind == TransactionKind.expense)
            .fold<int>(0, (sum, t) => sum + t.amountMinor);
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Text(
            _S.monthSpent(formatMinor(spent)),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Transactions grouped by day
// ---------------------------------------------------------------------------

Map<DateTime, List<TransactionEntity>> _groupByDay(
  List<TransactionEntity> transactions,
) {
  final groups = <DateTime, List<TransactionEntity>>{};
  for (final transaction in transactions) {
    final created = transaction.createdAt;
    final day = DateTime(created.year, created.month, created.day);
    groups.putIfAbsent(day, () => []).add(transaction);
  }
  return groups;
}

String _dayLabel(DateTime day) {
  final now = DateTime.now();
  if (day == DateTime(now.year, now.month, now.day)) return _S.today;
  if (day == DateTime(now.year, now.month, now.day - 1)) return _S.yesterday;
  return DateFormat('EEE, MMM d').format(day);
}

String _signed(int minor) {
  if (minor == 0) return formatMinor(0);
  return '${minor > 0 ? '+' : '−'}${formatMinor(minor.abs())}';
}

class _TransactionsSliver extends StatelessWidget {
  const _TransactionsSliver({
    required this.transactions,
    required this.errorMessage,
    required this.onEdit,
  });

  final List<TransactionEntity> transactions;
  final String? errorMessage;
  final ValueChanged<TransactionEntity> onEdit;

  @override
  Widget build(BuildContext context) {
    final groups = _groupByDay(transactions);
    final banner = errorMessage;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList.list(
        children: [
          if (banner != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InlineErrorBanner(message: banner),
            ),
          for (final entry in groups.entries)
            _DayGroup(
              day: entry.key,
              transactions: entry.value,
              onEdit: onEdit,
              onDelete: (transaction) => context.read<TransactionsBloc>().add(
                TransactionDeleted(transaction.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.day,
    required this.transactions,
    required this.onEdit,
    required this.onDelete,
  });

  final DateTime day;
  final List<TransactionEntity> transactions;
  final ValueChanged<TransactionEntity> onEdit;
  final ValueChanged<TransactionEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline = theme.colorScheme.outlineVariant;
    final net = transactions.fold<int>(
      0,
      (sum, t) =>
          sum +
          (t.kind == TransactionKind.income ? t.amountMinor : -t.amountMinor),
    );
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_dayLabel(day), style: labelStyle),
                Text(_signed(net), style: labelStyle),
              ],
            ),
          ),
          Material(
            color: theme.cardColor,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: outline.withValues(alpha: isDark ? 0.3 : 0.5),
              ),
            ),
            child: Column(
              children: [
                for (var i = 0; i < transactions.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 68,
                      color: outline.withValues(alpha: 0.4),
                    ),
                  _TransactionRow(
                    transaction: transactions[i],
                    onEdit: () => onEdit(transactions[i]),
                    onDelete: () => onDelete(transactions[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  final TransactionEntity transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Future<bool> _confirmAndDelete(BuildContext context) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text(_S.deleteTitle),
            content: const Text(_S.deleteBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(_S.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text(_S.delete),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) onDelete();
    // The row leaves the list when the transactions stream emits, so the
    // Dismissible must not remove itself ("dismissed widget still in tree").
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isIncome = transaction.kind == TransactionKind.income;

    final rawTitle = transaction.title;
    final hasTitle = rawTitle != null && rawTitle.isNotEmpty;
    final title = hasTitle ? rawTitle : transaction.categoryName;
    final time = DateFormat.jm().format(transaction.createdAt);
    final subtitle = hasTitle ? '${transaction.categoryName} · $time' : time;

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppTheme.expenseCoral,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmAndDelete(context),
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isIncome
                      ? AppTheme.incomeGreen.withValues(alpha: 0.12)
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  CategoryIcons.getIcon(transaction.categoryIconKey),
                  size: 20,
                  color: isIncome
                      ? AppTheme.incomeGreen
                      : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${isIncome ? '+' : '−'}${formatMinor(transaction.amountMinor)}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: isIncome ? AppTheme.incomeGreen : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty and error states
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final banner = errorMessage;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (banner != null) ...[
              InlineErrorBanner(message: banner),
              const SizedBox(height: 16),
            ],
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 28,
                color: AppTheme.primaryEmerald,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              _S.emptyTitle,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              _S.emptyBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetryView extends StatelessWidget {
  const _RetryView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InlineErrorBanner(message: message),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(_S.retry),
            ),
          ],
        ),
      ),
    );
  }
}
