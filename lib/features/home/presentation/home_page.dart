import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
import '../../transactions/presentation/wallet_bloc.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<WalletBloc>()..add(const WalletStarted()),
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
    return BlocListener<MonthCubit, DateTime>(
      listener: (context, month) =>
          context.read<TransactionsBloc>().add(MonthChanged(month)),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Header(),
                    const SizedBox(height: 16),
                    EntranceAnimation(
                      child: _BalanceSection(
                        onRetry: () => context.read<WalletBloc>().add(
                          const WalletRetryRequested(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    EntranceAnimation(
                      delay: const Duration(milliseconds: 60),
                      child: _TransactionActions(
                        onAdd: (kind) => _openForm(context, kind),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const EntranceAnimation(
                      delay: Duration(milliseconds: 100),
                      child: _BudgetSection(),
                    ),
                    const SizedBox(height: 20),
                    EntranceAnimation(
                      delay: const Duration(milliseconds: 140),
                      child: BlocBuilder<MonthCubit, DateTime>(
                        builder: (context, month) =>
                            _MonthSelector(month: month),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
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
          ],
        ),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    TransactionKind kind, [
    TransactionEntity? transaction,
  ]) => showTransactionForm(context, kind: kind, transaction: transaction);
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Home', style: theme.textTheme.headlineMedium),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: 6, height: 6),
              ),
              SizedBox(width: 6),
              Text(
                'EGP Active',
                style: TextStyle(
                  color: AppTheme.primaryEmerald,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BalanceSection extends StatelessWidget {
  const _BalanceSection({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        final balanceMinor = state is WalletLoaded ? state.balanceMinor : 0;
        final isNegative = state is WalletLoaded && state.isNegative;

        final gradient = isNegative
            ? AppTheme.expenseGradient
            : isDark
            ? AppTheme.balanceGradientDark
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
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total balance',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85),
                            letterSpacing: 0.2,
                          ),
                        ),
                        if (isNegative)
                          PulsingBadge(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.warning_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Overdrawn',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (state is WalletLoading)
                      const SizedBox(
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
                      )
                    else if (state is WalletError)
                      Container(
                        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                state.message,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Retry balance',
                              onPressed: onRetry,
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formatMinor(balanceMinor),
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -1.2,
                            height: 1.05,
                          ),
                        ),
                      ),
                    if (isNegative) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Your balance is below zero.',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'Consider adding income or reducing expenses.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

class _TransactionActions extends StatelessWidget {
  const _TransactionActions({required this.onAdd});

  final ValueChanged<TransactionKind> onAdd;

  @override
  Widget build(BuildContext context) {
    final canAdd = context.watch<WalletBloc>().state is WalletLoaded;

    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            label: 'Add income',
            icon: Icons.add_rounded,
            color: AppTheme.incomeGreen,
            onPressed: canAdd ? () => onAdd(TransactionKind.income) : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionTile(
            label: 'Add expense',
            icon: Icons.remove_rounded,
            color: AppTheme.expenseCoral,
            onPressed: canAdd ? () => onAdd(TransactionKind.expense) : null,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: Material(
        color: color.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
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

class _BudgetSection extends StatelessWidget {
  const _BudgetSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, state) => switch (state) {
        BudgetLoading() => ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: const LinearProgressIndicator(),
        ),
        BudgetError(:final message) => InlineErrorBanner(
          message: message,
          retryTooltip: 'Retry budget',
          onRetry: () =>
              context.read<BudgetBloc>().add(const BudgetRetryRequested()),
        ),
        BudgetLoaded(:final status) => _BudgetStatusView(status: status),
      },
    );
  }
}

class _BudgetStatusView extends StatelessWidget {
  const _BudgetStatusView({required this.status});

  final BudgetStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (status.level == BudgetLevel.notSet) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppTheme.infoBlue.withValues(
                    alpha: isDark ? 0.2 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.speed_rounded,
                  color: AppTheme.infoBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No monthly limit set',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 14),
                ),
              ),
              TextButton.icon(
                onPressed: () => context.go('/settings'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Set a limit'),
              ),
            ],
          ),
        ),
      );
    }

    final limitMinor = status.limitMinor!;
    final statusColor = switch (status.level) {
      BudgetLevel.exceeded => AppTheme.expenseCoral,
      BudgetLevel.warning => AppTheme.warningAmber,
      _ => AppTheme.incomeGreen,
    };
    final statusIcon = switch (status.level) {
      BudgetLevel.exceeded => Icons.warning_rounded,
      BudgetLevel.warning => Icons.trending_up_rounded,
      _ => Icons.check_circle_rounded,
    };
    final message = switch (status.level) {
      BudgetLevel.warning =>
        'You have used ${(status.progress * 100).round()}% of this limit.',
      BudgetLevel.exceeded => 'Monthly limit exceeded.',
      BudgetLevel.ok || BudgetLevel.notSet => null,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Monthly budget',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (status.remainingMinor != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status.remainingMinor! >= 0
                          ? '${formatMinor(status.remainingMinor!)} left'
                          : '${formatMinor(status.remainingMinor!.abs())} over',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: formatMinor(status.spentMinor),
                    style: theme.textTheme.headlineSmall,
                  ),
                  TextSpan(
                    text: '  of ${formatMinor(limitMinor)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AnimatedGradientProgressBar(
              progress: status.progress,
              color: statusColor,
              height: 8,
              borderRadius: 6,
            ),
            if (message != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: isDark ? 0.15 : 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 15, color: statusColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final monthCubit = context.read<MonthCubit>();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous month',
            onPressed: monthCubit.canGoPrevious ? monthCubit.previous : null,
            icon: const Icon(Icons.chevron_left_rounded, size: 24),
          ),
          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Row(
                  key: ValueKey(month),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 18,
                      color: AppTheme.primaryEmerald,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat.yMMMM().format(month),
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next month',
            onPressed: monthCubit.canGoNext ? monthCubit.next : null,
            icon: const Icon(Icons.chevron_right_rounded, size: 24),
          ),
        ],
      ),
    );
  }
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
    final grouped = <DateTime, List<TransactionEntity>>{};
    for (final transaction in transactions) {
      final day = DateTime(
        transaction.createdAt.year,
        transaction.createdAt.month,
        transaction.createdAt.day,
      );
      grouped.putIfAbsent(day, () => []).add(transaction);
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            InlineErrorBanner(message: errorMessage!),
          ],
          for (final entry in grouped.entries) ...[
            _DayHeader(day: entry.key, count: entry.value.length),
            _DayCard(transactions: entry.value, onEdit: onEdit),
          ],
        ]),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day, required this.count});

  final DateTime day;
  final int count;

  String get _label {
    final now = DateTime.now();
    if (DateUtils.isSameDay(day, now)) return 'Today';
    if (DateUtils.isSameDay(day, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return DateFormat.yMMMMd().format(day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_label, style: theme.textTheme.titleSmall),
          Text(
            count == 1 ? '1 item' : '$count items',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.transactions, required this.onEdit});

  final List<TransactionEntity> transactions;
  final ValueChanged<TransactionEntity> onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < transactions.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 72),
            EntranceAnimation(
              delay: Duration(milliseconds: i < 10 ? i * 30 : 300),
              duration: const Duration(milliseconds: 320),
              offset: const Offset(0, 0.03),
              child: _TransactionTile(
                transaction: transactions[i],
                onEdit: () => onEdit(transactions[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction, required this.onEdit});

  final TransactionEntity transaction;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isIncome = transaction.kind == TransactionKind.income;
    final accentColor = isIncome ? AppTheme.incomeGreen : AppTheme.expenseCoral;

    final hasDistinctTitle =
        transaction.title != null &&
        transaction.title != transaction.categoryName;

    return Dismissible(
      key: ValueKey('transaction-${transaction.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: AppTheme.expenseCoral.withValues(alpha: isDark ? 0.2 : 0.14),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline_rounded, color: AppTheme.expenseCoral),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: AppTheme.expenseCoral,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        context.read<TransactionsBloc>().add(
          TransactionDeleted(transaction.id),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => context.read<TransactionsBloc>().add(
                TransactionDeleteUndone(transaction),
              ),
            ),
          ),
        );
      },
      child: ListTile(
        onTap: onEdit,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: isDark ? 0.2 : 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            CategoryIcons.getIcon(transaction.categoryIconKey),
            color: accentColor,
            size: 22,
          ),
        ),
        title: Text(
          transaction.title ?? transaction.categoryName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
        ),
        subtitle: hasDistinctTitle
            ? Text(
                transaction.categoryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
              )
            : null,
        trailing: Text(
          '${isIncome ? '+' : '−'}${formatMinor(transaction.amountMinor)}',
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canAdd = context.read<WalletBloc>().state is WalletLoaded;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (errorMessage != null) ...[
              InlineErrorBanner(message: errorMessage!),
              const SizedBox(height: 24),
            ],
            PulsingBadge(
              duration: const Duration(milliseconds: 2000),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withValues(
                    alpha: isDark ? 0.15 : 0.08,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  size: 40,
                  color: AppTheme.primaryEmerald,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('No transactions yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Add your starting balance to begin tracking.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton.tonalIcon(
              onPressed: canAdd
                  ? () => showTransactionForm(
                      context,
                      kind: TransactionKind.income,
                    )
                  : null,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add your starting balance'),
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppTheme.expenseCoral,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
