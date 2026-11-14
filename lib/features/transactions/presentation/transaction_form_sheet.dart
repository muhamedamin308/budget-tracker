// lib/features/transactions/presentation/transaction_form_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/money_format.dart';
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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
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
                final accentGradient = isIncome
                    ? AppTheme.incomeGradient
                    : AppTheme.expenseGradient;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header ────────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            gradient: accentGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(
                                  alpha: isIncome ? 0.32 : 0.28,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            isIncome
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: Colors.white,
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
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isIncome
                                    ? 'Deposit funds to your wallet'
                                    : 'Log expenditure against your budget',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
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
                    const SizedBox(height: 20),

                    if (state.isLoading)
                      const SizedBox(
                        height: 160,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      // ── Amount field ─────────────────────────────
                      _SectionLabel(
                        text: 'AMOUNT',
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
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
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 4, right: 8),
                            child: Icon(Icons.payments_outlined, size: 22),
                          ),
                          suffixText: 'EGP',
                          suffixStyle: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                letterSpacing: 0.3,
                              ),
                        ),
                        onChanged: context
                            .read<TransactionFormCubit>()
                            .amountChanged,
                      ),

                      if (isIncome) ...[
                        const SizedBox(height: 16),
                        _SectionLabel(
                          text: 'TITLE',
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          key: const ValueKey('transaction-title'),
                          initialValue: state.title,
                          decoration: const InputDecoration(
                            hintText: 'e.g., Salary, Bonus, Freelance',
                            prefixIcon: Icon(Icons.edit_note_rounded),
                          ),
                          onChanged: context
                              .read<TransactionFormCubit>()
                              .titleChanged,
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ── Category section ────────────────────────
                      _SectionLabel(
                        text: 'CATEGORY',
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 10),

                      if (state.categories.isEmpty)
                        _EmptyCategoriesCard(onOpenSettings: null)
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final category in state.categories)
                              _CategoryPill(
                                category: category,
                                selected:
                                    category.id == state.selectedCategoryId,
                                accentColor: accentColor,
                                onTap: () => context
                                    .read<TransactionFormCubit>()
                                    .categorySelected(category.id),
                              ),
                          ],
                        ),

                      if (state.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        _ErrorBanner(message: state.errorMessage!),
                      ],

                      const SizedBox(height: 24),

                      // ── Save button ─────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient:
                                state.isSubmitting || state.categories.isEmpty
                                ? LinearGradient(
                                    colors: [
                                      accentColor.withValues(alpha: 0.5),
                                      accentColor.withValues(alpha: 0.4),
                                    ],
                                  )
                                : accentGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow:
                                state.isSubmitting || state.categories.isEmpty
                                ? null
                                : [
                                    BoxShadow(
                                      color: accentColor.withValues(
                                        alpha: isIncome ? 0.35 : 0.30,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap:
                                  state.isSubmitting || state.categories.isEmpty
                                  ? null
                                  : () => _save(context, state),
                              borderRadius: BorderRadius.circular(18),
                              child: Center(
                                child: state.isSubmitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        transaction == null ? 'Save' : 'Update',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                              ),
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
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppTheme.expenseCoral.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: AppTheme.expenseCoral,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Negative balance'),
          ],
        ),
        content: Text(
          'This puts your wallet at −${formatMinor(projectedBalance.abs())}. Save anyway?',
          style: const TextStyle(fontSize: 14, height: 1.4),
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

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
        color: color.withValues(alpha: 0.75),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category pill
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.category,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final dynamic category;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bg = selected
        ? accentColor.withValues(alpha: isDark ? 0.22 : 0.14)
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
    final fg = selected ? accentColor : theme.colorScheme.onSurfaceVariant;
    final border = selected
        ? accentColor.withValues(alpha: isDark ? 0.5 : 0.35)
        : (isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CategoryIcons.getIcon(category.iconKey),
                  size: 16,
                  color: fg,
                ),
                const SizedBox(width: 7),
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: 0.05,
                    color: fg,
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

// ─────────────────────────────────────────────────────────────────────────────
// Empty categories card
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyCategoriesCard extends StatelessWidget {
  const _EmptyCategoriesCard({this.onOpenSettings});

  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(
                alpha: isDark ? 0.12 : 0.08,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.category_outlined,
              size: 28,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No categories available',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Add a category in Settings to continue.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error banner
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.error_outline_rounded,
              color: theme.colorScheme.error,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
