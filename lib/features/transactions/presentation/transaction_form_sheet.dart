import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/money_format.dart';
import '../../../core/widgets/app_animations.dart';
import '../domain/transaction_entity.dart';
import 'transaction_form_cubit.dart';
import 'wallet_bloc.dart';

Future<void> showTransactionForm(
  BuildContext context, {
  required TransactionKind kind,
  TransactionEntity? transaction,
}) {
  WalletBloc? walletBloc;
  try {
    walletBloc = context.read<WalletBloc>();
  } catch (_) {}

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (sheetContext) {
      Widget content = BlocProvider(
        create: (_) =>
            getIt<TransactionFormCubit>()
              ..initialize(kind: kind, transaction: transaction),
        child: _TransactionFormSheet(transaction: transaction),
      );

      if (walletBloc != null) {
        content = BlocProvider<WalletBloc>.value(
          value: walletBloc,
          child: content,
        );
      }

      return content;
    },
  );
}

class _TransactionFormSheet extends StatelessWidget {
  const _TransactionFormSheet({required this.transaction});

  final TransactionEntity? transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<TransactionFormCubit, TransactionFormState>(
      listenWhen: (previous, current) =>
          previous.isSubmitted != current.isSubmitted && current.isSubmitted,
      listener: (context, state) => Navigator.of(context).pop(),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: BlocBuilder<TransactionFormCubit, TransactionFormState>(
              builder: (context, state) {
                final isIncome = state.kind == TransactionKind.income;
                final sheetTitle = transaction == null
                    ? isIncome
                          ? 'Add income'
                          : 'Add expense'
                    : 'Edit transaction';
                final accentColor = isIncome
                    ? AppTheme.incomeGreen
                    : AppTheme.expenseCoral;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(
                              alpha: isDark ? 0.2 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: accentColor.withValues(
                                alpha: isDark ? 0.35 : 0.2,
                              ),
                            ),
                          ),
                          child: Icon(
                            isIncome
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: accentColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sheetTitle,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              Text(
                                isIncome
                                    ? 'Deposit funds to your wallet'
                                    : 'Log expenditure against your budget',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    if (state.isLoading)
                      const SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      TextFormField(
                        key: const ValueKey('transaction-amount'),
                        initialValue: state.amountText,
                        autofocus: transaction == null,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          hintText: '0.00',
                          prefixIcon: const Icon(Icons.payments_outlined),
                          suffixText: 'EGP',
                          suffixStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        onChanged: context
                            .read<TransactionFormCubit>()
                            .amountChanged,
                      ),
                      if (isIncome) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const ValueKey('transaction-title'),
                          initialValue: state.title,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            hintText: 'e.g., Salary, Bonus, Freelance',
                            prefixIcon: Icon(Icons.edit_note_rounded),
                          ),
                          onChanged: context
                              .read<TransactionFormCubit>()
                              .titleChanged,
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Category',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (state.categories.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.category_outlined,
                                size: 40,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No categories available',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add a category in Settings to continue.',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final category in state.categories)
                              ChoiceChip(
                                avatar: Icon(
                                  CategoryIcons.getIcon(category.iconKey),
                                  size: 18,
                                  color: category.id == state.selectedCategoryId
                                      ? accentColor
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                label: Text(category.name),
                                selected:
                                    category.id == state.selectedCategoryId,
                                selectedColor: accentColor.withValues(
                                  alpha: isDark ? 0.25 : 0.15,
                                ),
                                checkmarkColor: accentColor,
                                labelStyle: TextStyle(
                                  fontWeight:
                                      category.id == state.selectedCategoryId
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                onSelected: (_) => context
                                    .read<TransactionFormCubit>()
                                    .categorySelected(category.id),
                              ),
                          ],
                        ),
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: theme.colorScheme.error.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                color: theme.colorScheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  state.errorMessage!,
                                  style: TextStyle(
                                    color: theme.colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed:
                              state.isSubmitting || state.categories.isEmpty
                              ? null
                              : () => _save(context, state),
                          style: FilledButton.styleFrom(
                            backgroundColor: accentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: state.isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Save',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, TransactionFormState state) async {
    if (state.kind == TransactionKind.expense) {
      final amount = double.tryParse(state.amountText.trim());
      WalletState? walletState;
      try {
        walletState = context.read<WalletBloc>().state;
      } catch (_) {
        // WalletBloc is not available in the current context
      }

      if (amount != null &&
          amount.isFinite &&
          walletState is WalletLoaded &&
          !walletState.isNegative) {
        final amountMinor = (amount * 100).round();
        final restoredExpense = transaction?.kind == TransactionKind.expense
            ? transaction!.amountMinor
            : 0;
        final projectedBalance =
            walletState.balanceMinor + restoredExpense - amountMinor;
        if (projectedBalance < 0) {
          final confirmed = await _confirmNegativeBalance(
            context,
            projectedBalance,
          );
          if (!confirmed || !context.mounted) return;
        }
      }
    }
    if (!context.mounted) return;
    await context.read<TransactionFormCubit>().submit();
  }

  Future<bool> _confirmNegativeBalance(
    BuildContext context,
    int projectedBalance,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.expenseCoral.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: AppTheme.expenseCoral,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Negative balance'),
          ],
        ),
        content: Text(
          'This puts your wallet at −${formatMinor(projectedBalance.abs())}. Save anyway?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.expenseCoral,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Save anyway'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}
