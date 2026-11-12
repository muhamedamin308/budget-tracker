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
      builder: (_) => const _MonthlyLimitSheet(),
    );

class _MonthlyLimitSheet extends StatefulWidget {
  const _MonthlyLimitSheet();

  @override
  State<_MonthlyLimitSheet> createState() => _MonthlyLimitSheetState();
}

class _MonthlyLimitSheetState extends State<_MonthlyLimitSheet> {
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryEmerald.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: AppTheme.primaryEmerald,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monthly Limit',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  DateFormat.yMMMM().format(month),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
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
                    const SizedBox(height: 16),
                    switch (state) {
                      BudgetLoading() => const SizedBox(
                          height: 100,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      BudgetError(:final message, :final month) => Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.expenseCoral.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.expenseCoral.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message,
                                style: const TextStyle(
                                  color: AppTheme.expenseCoral,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              FilledButton.tonal(
                                onPressed: () => context.read<BudgetBloc>().add(
                                  const BudgetRetryRequested(),
                                ),
                                child: Text('Retry for ${DateFormat.yMMMM().format(month)}'),
                              ),
                            ],
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.dividerColor.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline_rounded,
                                      size: 18,
                                      color: AppTheme.primaryEmerald,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        status.limitMinor == null
                                            ? 'No spending limit set for this month yet.'
                                            : 'Current limit: ${formatMinor(status.limitMinor!)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: const ValueKey('monthly-limit-amount'),
                                controller: _amountController,
                                autofocus: true,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Monthly Limit Amount',
                                  hintText: '0.00',
                                  prefixIcon: const Icon(
                                    Icons.payments_outlined,
                                    size: 20,
                                  ),
                                  suffixText: 'EGP',
                                  suffixStyle: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
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
                              if (errorMessage != null) ...[
                                const SizedBox(height: 10),
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
                                    errorMessage,
                                    style: const TextStyle(
                                      color: AppTheme.expenseCoral,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              FilledButton(
                                onPressed: isSaving ? null : () => _save(context),
                                child: isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Save'),
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
