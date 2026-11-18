// lib/features/transactions/presentation/transaction_form_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/money_format.dart';
import '../../wallets/domain/wallet_entity.dart';
import '../../wallets/presentation/wallet_icons.dart';
import '../domain/transaction_entity.dart';
import 'transaction_form_cubit.dart';
import 'balance_bloc.dart';

Future<void> showTransactionForm(
  BuildContext context, {
  required TransactionKind kind,
  TransactionEntity? transaction,
  int? initialCategoryId,
}) {
  BalanceBloc? balanceBloc;
  try {
    balanceBloc = context.read<BalanceBloc>();
  } catch (_) {}

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      Widget content = BlocProvider(
        create: (_) =>
            getIt<TransactionFormCubit>()
              ..initialize(
                kind: kind,
                transaction: transaction,
                initialCategoryId: initialCategoryId,
              ),
        child: _TransactionFormSheet(transaction: transaction),
      );

      if (balanceBloc != null) {
        content = BlocProvider<BalanceBloc>.value(
          value: balanceBloc,
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
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: BlocBuilder<TransactionFormCubit, TransactionFormState>(
            builder: (context, state) => _buildContent(context, state),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TransactionFormState state) {
    final theme = Theme.of(context);
    final cubit = context.read<TransactionFormCubit>();
    final isIncome = state.kind == TransactionKind.income;
    final isEditing = transaction != null;

    final accent = isIncome ? AppTheme.incomeGreen : AppTheme.expenseCoral;
    final gradient = isIncome
        ? AppTheme.incomeGradient
        : AppTheme.expenseGradient;

    final title = isEditing
        ? 'Edit transaction'
        : (isIncome ? 'Add income' : 'Add expense');
    final subtitle = isIncome
        ? 'Deposit funds to your wallet'
        : 'Log spending against your budget';

    final canSave =
        !state.isSubmitting &&
        state.categories.isNotEmpty &&
        state.wallets.isNotEmpty &&
        state.selectedWalletId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
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
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
        const SizedBox(height: 18),

        if (state.isLoading)
          const SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          // Amount hero
          _AmountHero(
            accent: accent,
            initialValue: state.amountText,
            autofocus: !isEditing,
            onChanged: cubit.amountChanged,
          ),

          if (isIncome) ...[
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('transaction-title'),
              initialValue: state.title,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Salary, Bonus, Freelance',
                prefixIcon: const Icon(Icons.edit_note_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onChanged: cubit.titleChanged,
            ),
          ],

          // Wallet
          const SizedBox(height: 22),
          _SectionLabel(text: isIncome ? 'To wallet' : 'From wallet', icon: Icons.wallet_rounded),
          const SizedBox(height: 10),
          if (state.wallets.isEmpty)
            const _EmptyCard(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No wallets available',
              body: 'Add a wallet in the Wallets screen to continue.',
            )
          else
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: state.wallets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final wallet = state.wallets[i];
                  return _WalletCard(
                    wallet: wallet,
                    selected: wallet.id == state.selectedWalletId,
                    accent: accent,
                    onTap: () => cubit.walletSelected(wallet.id),
                  );
                },
              ),
            ),

          // Category
          const SizedBox(height: 22),
          _SectionLabel(
            text: 'Category',
            icon: Icons.category_rounded,
            trailing: state.categories.isEmpty
                ? null
                : '${state.categories.length}',
          ),
          const SizedBox(height: 10),
          if (state.categories.isEmpty)
            const _EmptyCard(
              icon: Icons.category_outlined,
              title: 'No categories available',
              body: 'Add a category in Settings to continue.',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in state.categories)
                  _CategoryPill(
                    category: category,
                    selected: category.id == state.selectedCategoryId,
                    accent: accent,
                    onTap: () => cubit.categorySelected(category.id),
                  ),
              ],
            ),

          if (state.errorMessage != null) ...[
            const SizedBox(height: 16),
            _ErrorBanner(message: state.errorMessage!),
          ],

          // Save
          const SizedBox(height: 24),
          _SaveButton(
            enabled: canSave,
            loading: state.isSubmitting,
            accent: accent,
            gradient: gradient,
            label: isEditing
                ? 'Update'
                : (isIncome ? 'Save income' : 'Save expense'),
            onTap: () => _save(context, state),
          ),
        ],
      ],
    );
  }

  Future<void> _save(BuildContext context, TransactionFormState state) async {
    if (state.kind == TransactionKind.expense) {
      final amount = double.tryParse(state.amountText.trim());
      BalanceState? balanceState;
      try {
        balanceState = context.read<BalanceBloc>().state;
      } catch (_) {
        // BalanceBloc is not available in the current context
      }

      if (amount != null &&
          amount.isFinite &&
          balanceState is BalanceLoaded &&
          !balanceState.isNegative) {
        final amountMinor = (amount * 100).round();
        final restoredExpense = transaction?.kind == TransactionKind.expense
            ? transaction!.amountMinor
            : 0;
        final projectedBalance =
            balanceState.balanceMinor + restoredExpense - amountMinor;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.expenseCoral.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_rounded,
            color: AppTheme.expenseCoral,
            size: 26,
          ),
        ),
        title: const Text('Negative balance'),
        content: Text(
          'This puts your wallet at −${formatMinor(projectedBalance.abs())}. '
          'Save anyway?',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
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

// ---------------------------------------------------------------------------
// Amount hero
// ---------------------------------------------------------------------------

class _AmountHero extends StatelessWidget {
  const _AmountHero({
    required this.accent,
    required this.initialValue,
    required this.autofocus,
    required this.onChanged,
  });

  final Color accent;
  final String initialValue;
  final bool autofocus;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            'AMOUNT',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: accent.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextFormField(
                  key: const ValueKey('transaction-amount'),
                  initialValue: initialValue,
                  autofocus: autofocus,
                  textAlign: TextAlign.center,
                  cursorColor: accent,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.35,
                      ),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'EGP',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.icon, this.trailing});

  final String text;
  final IconData icon;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              trailing!,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Wallet card
// ---------------------------------------------------------------------------

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.wallet,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final WalletEntity wallet;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconColor = WalletIcons.color(wallet.iconKey);
    final balance = wallet.balanceMinor ?? 0;

    return Semantics(
      button: true,
      selected: selected,
      label: '${wallet.name}, ${formatMinor(balance)}',
      excludeSemantics: true,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? accent
                : scheme.outlineVariant.withValues(alpha: 0.7),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 130, maxWidth: 190),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        WalletIcons.icon(wallet.iconKey),
                        size: 20,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wallet.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            formatMinor(balance),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: balance < 0
                                  ? AppTheme.expenseCoral
                                  : scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.check_circle_rounded, size: 18, color: accent),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category pill
// ---------------------------------------------------------------------------

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.category,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final dynamic category;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? accent : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: category.name as String,
      excludeSemantics: true,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.12)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selected
                        ? Icons.check_rounded
                        : CategoryIcons.getIcon(category.iconKey),
                    size: 17,
                    color: fg,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    category.name as String,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Save button
// ---------------------------------------------------------------------------

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.enabled,
    required this.loading,
    required this.accent,
    required this.gradient,
    required this.label,
    required this.onTap,
  });

  final bool enabled;
  final bool loading;
  final Color accent;
  final Gradient gradient;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      decoration: BoxDecoration(
        gradient: enabled || loading ? gradient : null,
        color: enabled || loading ? null : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.32),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: enabled ? Colors.white : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          color: enabled
                              ? Colors.white
                              : scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.2,
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

// ---------------------------------------------------------------------------
// Empty and error states
// ---------------------------------------------------------------------------

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    color: scheme.onSurfaceVariant,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colors.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.onErrorContainer,
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
