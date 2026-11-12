import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_format.dart';
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Home',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _BalanceSection(
                onRetry: () => context.read<WalletBloc>().add(
                  const WalletRetryRequested(),
                ),
              ),
              const SizedBox(height: 8),
              const _BudgetSection(),
              const SizedBox(height: 8),
              BlocBuilder<MonthCubit, DateTime>(
                builder: (context, month) => _MonthSelector(month: month),
              ),
              const SizedBox(height: 8),
              _TransactionActions(onAdd: (kind) => _openForm(context, kind)),
              const SizedBox(height: 8),
              Expanded(
                child: BlocBuilder<TransactionsBloc, TransactionsState>(
                  builder: (context, state) => switch (state) {
                    TransactionsLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    TransactionsError(:final message) => _RetryView(
                      message: message,
                      onRetry: () => context.read<TransactionsBloc>().add(
                        const TransactionsRetryRequested(),
                      ),
                    ),
                    TransactionsLoaded(
                      :final transactions,
                      :final errorMessage,
                    ) =>
                      _TransactionsList(
                        transactions: transactions,
                        errorMessage: errorMessage,
                        onEdit: (transaction) =>
                            _openForm(context, transaction.kind, transaction),
                      ),
                  },
                ),
              ),
            ],
          ),
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

class _BalanceSection extends StatelessWidget {
  const _BalanceSection({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        final balanceMinor = state is WalletLoaded ? state.balanceMinor : 0;
        final isNegative = state is WalletLoaded && state.isNegative;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0F2A24), Color(0xFF081B17)],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0D9373), Color(0xFF05654F)],
                  ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : const Color(0xFF0D9373).withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your balance',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  if (isNegative)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.expenseCoral,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Overdrawn',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              if (state is WalletLoading)
                const SizedBox(
                  height: 36,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              else if (state is WalletError)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Retry balance',
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                )
              else
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatMinor(balanceMinor),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isNegative ? colors.error : Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              if (isNegative) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Your balance is below zero.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BudgetSection extends StatelessWidget {
  const _BudgetSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, state) => switch (state) {
        BudgetLoading() => const LinearProgressIndicator(),
        BudgetError(:final message) => Row(
          children: [
            Expanded(child: Text(message)),
            IconButton(
              tooltip: 'Retry budget',
              onPressed: () =>
                  context.read<BudgetBloc>().add(const BudgetRetryRequested()),
              icon: const Icon(Icons.refresh),
            ),
          ],
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
    if (status.level == BudgetLevel.notSet) {
      return Row(
        children: [
          const Expanded(child: Text('No monthly limit set')),
          TextButton(
            onPressed: () => context.go('/settings'),
            child: const Text('Set a limit'),
          ),
        ],
      );
    }

    final limitMinor = status.limitMinor!;
    final colors = Theme.of(context).colorScheme;
    final message = switch (status.level) {
      BudgetLevel.warning =>
        'You have used ${(status.progress * 100).round()}% of this limit.',
      BudgetLevel.exceeded => 'Monthly limit exceeded.',
      BudgetLevel.ok || BudgetLevel.notSet => null,
    };
    final backgroundColor = status.level == BudgetLevel.exceeded
        ? colors.errorContainer
        : colors.secondaryContainer;
    final foregroundColor = status.level == BudgetLevel.exceeded
        ? colors.onErrorContainer
        : colors.onSecondaryContainer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${formatMinor(status.spentMinor)} of ${formatMinor(limitMinor)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (status.remainingMinor != null)
              Text(
                status.remainingMinor! >= 0
                    ? '${formatMinor(status.remainingMinor!)} left'
                    : '${formatMinor(status.remainingMinor!.abs())} over',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: status.progress,
            minHeight: 6,
          ),
        ),
        if (message != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message,
              style: TextStyle(color: foregroundColor, fontSize: 12),
            ),
          ),
      ],
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
          child: SizedBox(
            height: 48,
            child: FilledButton.tonalIcon(
              onPressed: canAdd ? () => onAdd(TransactionKind.income) : null,
              icon: const Icon(Icons.add),
              label: const Text('Add income'),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: canAdd ? () => onAdd(TransactionKind.expense) : null,
              icon: const Icon(Icons.remove),
              label: const Text('Add expense'),
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionsList extends StatelessWidget {
  const _TransactionsList({
    required this.transactions,
    required this.errorMessage,
    required this.onEdit,
  });

  final List<TransactionEntity> transactions;
  final String? errorMessage;
  final ValueChanged<TransactionEntity> onEdit;

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  if (errorMessage != null) _InlineError(message: errorMessage!),
                  const Spacer(),
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 40,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No transactions yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add your starting balance to begin.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: context.read<WalletBloc>().state is WalletLoaded
                        ? () =>
                              showTransactionForm(context, kind: TransactionKind.income)
                        : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Add your starting balance'),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final grouped = <DateTime, List<TransactionEntity>>{};
    for (final transaction in transactions) {
      final day = DateTime(
        transaction.createdAt.year,
        transaction.createdAt.month,
        transaction.createdAt.day,
      );
      grouped.putIfAbsent(day, () => []).add(transaction);
    }

    return Column(
      children: [
        if (errorMessage != null) _InlineError(message: errorMessage!),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              for (final entry in grouped.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 4),
                  child: Text(
                    DateFormat.yMMMMd().format(entry.key),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: entry.value.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final transaction = entry.value[index];
                      return _TransactionTile(
                        transaction: transaction,
                        onEdit: () => onEdit(transaction),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction, required this.onEdit});

  final TransactionEntity transaction;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.kind == TransactionKind.income;
    final colors = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey('transaction-${transaction.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: colors.errorContainer,
        child: Icon(Icons.delete_outline, color: colors.onErrorContainer),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: CircleAvatar(
          backgroundColor: colors.secondaryContainer,
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: colors.onSecondaryContainer,
          ),
        ),
        title: Text(
          transaction.title ?? transaction.categoryName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(transaction.categoryName),
        trailing: Text(
          '${isIncome ? '+' : '−'}${formatMinor(transaction.amountMinor)}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: isIncome ? colors.primary : colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        onTap: onEdit,
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: TextStyle(color: colors.onErrorContainer)),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
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
    return Row(
      children: [
        IconButton(
          tooltip: 'Previous month',
          onPressed: monthCubit.canGoPrevious ? monthCubit.previous : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: Center(
            child: Text(
              DateFormat.yMMMM().format(month),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Next month',
          onPressed: monthCubit.canGoNext ? monthCubit.next : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
