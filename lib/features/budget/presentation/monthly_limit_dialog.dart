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
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryEmerald.withValues(
                                      alpha: 0.3,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monthly Limit',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                Text(
                                  DateFormat.yMMMM().format(month),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                    const SizedBox(height: 20),
                    switch (state) {
                      BudgetLoading() => const SizedBox(
                          height: 100,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      BudgetError(:final message, :final month) => Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.expenseCoral.withValues(
                              alpha: isDark ? 0.15 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.expenseCoral.withValues(alpha: 0.3),
                            ),
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
                                onPressed: () => context.read<BudgetBloc>().add(
                                  const BudgetRetryRequested(),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.expenseCoral.withValues(
                                    alpha: 0.15,
                                  ),
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
                                padding: const EdgeInsets.all(16),
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
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.2 : 0.03,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      status.limitMinor == null
                                          ? Icons.info_outline_rounded
                                          : Icons.check_circle_rounded,
                                      size: 20,
                                      color: status.limitMinor == null
                                          ? AppTheme.infoBlue
                                          : AppTheme.incomeGreen,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        status.limitMinor == null
                                            ? 'No spending limit set for this month yet.'
                                            : 'Current limit: ${formatMinor(status.limitMinor!)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                key: const ValueKey('monthly-limit-amount'),
                                controller: _amountController,
                                autofocus: true,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Monthly Limit Amount',
                                  hintText: '0.00',
                                  prefixIcon: Icon(
                                    Icons.payments_outlined,
                                    size: 22,
                                  ),
                                  suffixText: 'EGP',
                                  suffixStyle: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
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
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final preset in [1000, 3000, 5000, 10000])
                                    ActionChip(
                                      label: Text('$preset EGP'),
                                      onPressed: () {
                                        setState(() {
                                          _amountController.text = '$preset';
                                        });
                                      },
                                      backgroundColor: isDark
                                          ? const Color(0xFF1E293B)
                                          : const Color(0xFFF1F5F9),
                                      side: BorderSide(
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.1)
                                            : const Color(0xFFE2E8F0),
                                      ),
                                      labelStyle: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                              if (errorMessage != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.expenseCoral.withValues(
                                      alpha: isDark ? 0.15 : 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppTheme.expenseCoral.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
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
                                          errorMessage,
                                          style: const TextStyle(
                                            color: AppTheme.expenseCoral,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
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
                                  onPressed: isSaving ? null : () => _save(context),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppTheme.primaryEmerald,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: isSaving
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
