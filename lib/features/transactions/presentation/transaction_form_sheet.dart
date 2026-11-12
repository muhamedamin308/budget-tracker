import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_format.dart';
import '../domain/transaction_entity.dart';
import 'transaction_form_cubit.dart';
import 'wallet_bloc.dart';

Future<void> showTransactionForm(
  BuildContext context, {
  required TransactionKind kind,
  TransactionEntity? transaction,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (sheetContext) => BlocProvider(
    create: (_) =>
        getIt<TransactionFormCubit>()
          ..initialize(kind: kind, transaction: transaction),
    child: _TransactionFormSheet(transaction: transaction),
  ),
);

class _TransactionFormSheet extends StatelessWidget {
  const _TransactionFormSheet({required this.transaction});

  final TransactionEntity? transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: BlocBuilder<TransactionFormCubit, TransactionFormState>(
              builder: (context, state) {
                final isIncome = state.kind == TransactionKind.income;
                final accentColor =
                    isIncome ? AppTheme.incomeGreen : AppTheme.expenseCoral;

                final sheetTitle = transaction == null
                    ? isIncome
                        ? 'Add income'
                        : 'Add expense'
                    : 'Edit transaction';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isIncome
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                color: accentColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              sheetTitle,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
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
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          hintText: '0.00',
                          prefixIcon: Icon(Icons.attach_money_rounded),
                          suffixText: 'EGP',
                          suffixStyle: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        onChanged: context
                            .read<TransactionFormCubit>()
                            .amountChanged,
                      ),
                      if (isIncome) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          key: const ValueKey('transaction-title'),
                          initialValue: state.title,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            hintText: 'e.g. Salary, Client Work',
                            prefixIcon: Icon(Icons.title_rounded),
                          ),
                          onChanged: context
                              .read<TransactionFormCubit>()
                              .titleChanged,
                        ),
                      ],
                      const SizedBox(height: 20),
                      Text(
                        'Category',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (state.categories.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.warningAmber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.warningAmber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: AppTheme.warningAmber,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Add a category in Settings to continue.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final category in state.categories)
                              ChoiceChip(
                                label: Text(category.name),
                                selected:
                                    category.id == state.selectedCategoryId,
                                selectedColor:
                                    accentColor.withValues(alpha: 0.18),
                                side: BorderSide(
                                  color: category.id == state.selectedCategoryId
                                      ? accentColor
                                      : theme.dividerColor.withValues(alpha: 0.3),
                                  width: category.id == state.selectedCategoryId
                                      ? 1.5
                                      : 1,
                                ),
                                onSelected: (_) => context
                                    .read<TransactionFormCubit>()
                                    .categorySelected(category.id),
                              ),
                          ],
                        ),
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.expenseCoral.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            state.errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.expenseCoral,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: accentColor,
                        ),
                        onPressed:
                            state.isSubmitting || state.categories.isEmpty
                            ? null
                            : () => _save(context, state),
                        child: state.isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save'),
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
        title: const Text('Negative balance'),
        content: Text(
          'This puts your wallet at '
          '−${formatMinor(projectedBalance.abs())}. '
          'Save anyway?',
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
