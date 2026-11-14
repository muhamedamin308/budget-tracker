import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_format.dart';
import 'budget_bloc.dart';

Future<void> showMonthlyLimitDialog(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // Background, shape and drag handle come from AppTheme.bottomSheetTheme.
      builder: (_) => const _MonthlyLimitSheet(),
    );

class _MonthlyLimitSheet extends StatefulWidget {
  const _MonthlyLimitSheet();

  @override
  State<_MonthlyLimitSheet> createState() => _MonthlyLimitSheetState();
}

class _MonthlyLimitSheetState extends State<_MonthlyLimitSheet> {
  static const _presets = [1000, 3000, 5000, 10000];

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<BudgetBloc, BudgetState>(
      listenWhen: (previous, current) =>
          current is BudgetLoaded &&
          current.isSaved &&
          (previous is! BudgetLoaded || !previous.isSaved),
      listener: (context, state) => Navigator.of(context).pop(),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: BlocBuilder<BudgetBloc, BudgetState>(
              builder: (context, state) {
                final month = switch (state) {
                  BudgetLoading(:final month) => month,
                  BudgetLoaded(:final month) => month,
                  BudgetError(:final month) => month,
                };

                if (state is BudgetLoaded && !_initialized) {
                  final limit = state.status.limitMinor;
                  _amountController.text = limit == null
                      ? ''
                      : (limit / 100).toStringAsFixed(2);
                  _initialized = true;
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(month: month),
                    const SizedBox(height: 20),
                    switch (state) {
                      BudgetLoading() => const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      BudgetError(:final message, :final month) => _ErrorPanel(
                        message: message,
                        isDark: isDark,
                        retryLabel:
                            'Retry for ${DateFormat.yMMMM().format(month)}',
                        onRetry: () => context.read<BudgetBloc>().add(
                          const BudgetRetryRequested(),
                        ),
                      ),
                      BudgetLoaded(
                        :final status,
                        :final isSaving,
                        :final errorMessage,
                      ) =>
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _StatusPill(limitMinor: status.limitMinor),
                              const SizedBox(height: 16),
                              _AmountField(controller: _amountController),
                              const SizedBox(height: 16),
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _amountController,
                                builder: (context, value, _) {
                                  final current = double.tryParse(
                                    value.text.trim(),
                                  );
                                  return Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final preset in _presets)
                                        ChoiceChip(
                                          showCheckmark: false,
                                          selected: current == preset,
                                          label: Text(
                                            NumberFormat.decimalPattern()
                                                .format(preset),
                                          ),
                                          onSelected: (_) {
                                            _amountController.text = '$preset';
                                          },
                                        ),
                                    ],
                                  );
                                },
                              ),
                              if (errorMessage != null) ...[
                                const SizedBox(height: 16),
                                _InlineError(
                                  message: errorMessage,
                                  isDark: isDark,
                                ),
                              ],
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: isSaving
                                    ? null
                                    : () => _save(context),
                                child: isSaving
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Save limit'),
                              ),
                            ],
                          ),
                        ),
                    },
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _save(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text.trim());
    final amountMinor = (amount * 100).round();
    context.read<BudgetBloc>().add(BudgetLimitSaveRequested(amountMinor));
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryEmerald.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly Limit', style: theme.textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                DateFormat.yMMMM().format(month),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: theme.inputDecorationTheme.fillColor,
          ),
          icon: const Icon(Icons.close_rounded, size: 20),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.limitMinor});

  final int? limitMinor;

  @override
  Widget build(BuildContext context) {
    final hasLimit = limitMinor != null;
    final color = hasLimit ? AppTheme.incomeGreen : AppTheme.infoBlue;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasLimit
                  ? Icons.check_circle_rounded
                  : Icons.info_outline_rounded,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                hasLimit
                    ? 'Current limit: ${formatMinor(limitMinor!)}'
                    : 'No spending limit set for this month yet.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'MONTHLY LIMIT · EGP',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          TextFormField(
            key: const ValueKey('monthly-limit-amount'),
            controller: controller,
            autofocus: true,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: theme.textTheme.headlineLarge?.copyWith(fontSize: 40),
            cursorColor: AppTheme.primaryEmerald,
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: theme.textTheme.headlineLarge?.copyWith(
                fontSize: 40,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.35,
                ),
              ),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            validator: (value) {
              final amount = double.tryParse(value?.trim() ?? '');
              if (amount == null ||
                  !amount.isFinite ||
                  amount <= 0 ||
                  (amount * 100).round() <= 0) {
                return 'Enter an amount greater than zero.';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.isDark});

  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.expenseCoral.withValues(alpha: isDark ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.expenseCoral,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.expenseCoral,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({
    required this.message,
    required this.isDark,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final bool isDark;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.expenseCoral.withValues(alpha: isDark ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.expenseCoral,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.expenseCoral,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.tonal(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.expenseCoral.withValues(alpha: 0.15),
              foregroundColor: AppTheme.expenseCoral,
            ),
            child: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}
