import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_format.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../core/widgets/entrance_animation.dart';
import '../../categories/domain/category_entity.dart';
import '../../categories/domain/category_repository.dart';
import '../../transactions/domain/transaction_entity.dart';
import '../domain/recurring_rule_entity.dart';
import 'recurring_bloc.dart';

Future<void> showRecurringRules(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.96,
        child: BlocProvider(
          create: (_) => getIt<RecurringBloc>()..add(const RecurringStarted()),
          child: const RecurringRulesPage(),
        ),
      ),
    );

class RecurringRulesPage extends StatelessWidget {
  const RecurringRulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Back to settings',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recurring Rules',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'Automated monthly subscriptions & bills',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                BlocBuilder<RecurringBloc, RecurringState>(
                  builder: (context, state) => Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryEmerald.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        elevation: 0,
                        minimumSize: const Size(0, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      onPressed: state is RecurringLoaded
                          ? () => _editRule(context)
                          : null,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<RecurringBloc, RecurringState>(
                builder: (context, state) => switch (state) {
                  RecurringLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  RecurringError(:final message) => _ErrorView(
                    message: message,
                    onRetry: () => context.read<RecurringBloc>().add(
                      const RecurringRetryRequested(),
                    ),
                  ),
                  RecurringLoaded(:final rules, :final errorMessage) =>
                    _RulesList(
                      rules: rules,
                      errorMessage: errorMessage,
                      onEdit: (rule) => _editRule(context, rule),
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editRule(
    BuildContext context, [
    RecurringRuleEntity? rule,
  ]) async {
    await showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<RecurringBloc>(),
        child: _RuleEditorDialog(rule: rule),
      ),
    );
  }
}

class _RulesList extends StatelessWidget {
  const _RulesList({
    required this.rules,
    required this.errorMessage,
    required this.onEdit,
  });

  final List<RecurringRuleEntity> rules;
  final String? errorMessage;
  final ValueChanged<RecurringRuleEntity> onEdit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (rules.isEmpty) {
      return Column(
        children: [
          if (errorMessage != null)
            _ErrorBanner(
              message: errorMessage!,
              onRetry: () => context.read<RecurringBloc>().add(
                const RecurringRetryRequested(),
              ),
            ),
          const Spacer(),
          PulsingBadge(
            duration: const Duration(milliseconds: 2000),
            child: Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald.withValues(
                  alpha: isDark ? 0.15 : 0.08,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_repeat_rounded,
                size: 56,
                color: AppTheme.primaryEmerald,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No recurring rules yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Add rules to automatically record monthly subscriptions, bills, or salary.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
        ],
      );
    }

    return Column(
      children: [
        if (errorMessage != null)
          _ErrorBanner(
            message: errorMessage!,
            onRetry: () => context.read<RecurringBloc>().add(
              const RecurringRetryRequested(),
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: rules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final rule = rules[index];
              final isIncome = rule.kind == TransactionKind.income;
              final accentColor =
                  isIncome ? AppTheme.incomeGreen : AppTheme.expenseCoral;

              return EntranceAnimation(
                delay: Duration(milliseconds: index < 10 ? index * 30 : 300),
                duration: const Duration(milliseconds: 320),
                offset: const Offset(0, 0.03),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
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
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: InkWell(
                            onTap: () => onEdit(rule),
                            borderRadius: BorderRadius.circular(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rule.title ?? rule.categoryName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      formatMinor(rule.amountMinor),
                                      style: TextStyle(
                                        color: accentColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('·'),
                                    const SizedBox(width: 6),
                                    Text(
                                      rule.categoryName,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('·'),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Day ${rule.dayOfMonth}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                if (rule.endDate != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ends ${DateFormat.yMMMd().format(rule.endDate!)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: rule.isActive,
                          activeTrackColor: AppTheme.primaryEmerald,
                          onChanged: (isActive) => context
                              .read<RecurringBloc>()
                              .add(RuleToggled(id: rule.id, isActive: isActive)),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Rule options',
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          onSelected: (action) {
                            if (action == 'edit') onEdit(rule);
                            if (action == 'delete') _deleteRule(context, rule);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 18),
                                  SizedBox(width: 10),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: AppTheme.expenseCoral,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Delete',
                                    style: TextStyle(color: AppTheme.expenseCoral),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _deleteRule(
    BuildContext context,
    RecurringRuleEntity rule,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.expenseCoral.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: AppTheme.expenseCoral,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Delete recurring rule?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Existing ${rule.kind == TransactionKind.income ? 'income' : 'expense'} '
              'entries will remain in your history.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.expenseCoral.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppTheme.expenseCoral,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: TextStyle(
                        color: AppTheme.expenseCoral,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete == true && context.mounted) {
      context.read<RecurringBloc>().add(RuleDeleted(rule.id));
    }
  }
}

class _RuleEditorDialog extends StatefulWidget {
  const _RuleEditorDialog({this.rule});

  final RecurringRuleEntity? rule;

  @override
  State<_RuleEditorDialog> createState() => _RuleEditorDialogState();
}

class _RuleEditorDialogState extends State<_RuleEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _titleController;
  late final TextEditingController _dayController;
  late Future<List<CategoryEntity>> _categoriesFuture;
  late TransactionKind _kind;
  late DateTime _startDate;
  late DateTime? _endDate;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    final rule = widget.rule;
    _kind = rule?.kind ?? TransactionKind.expense;
    _categoryId = rule?.categoryId;
    _startDate = rule?.startDate ?? DateTime.now();
    _endDate = rule?.endDate;
    _amountController = TextEditingController(
      text: rule == null ? '' : (rule.amountMinor / 100).toStringAsFixed(2),
    );
    _titleController = TextEditingController(text: rule?.title);
    _dayController = TextEditingController(
      text: (rule?.dayOfMonth ?? DateTime.now().day).toString(),
    );
    _categoriesFuture = _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<RecurringBloc, RecurringState>(
      listenWhen: (previous, current) =>
          previous is RecurringLoaded &&
          current is RecurringLoaded &&
          previous.saveRevision != current.saveRevision,
      listener: (context, state) => Navigator.of(context).pop(),
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.event_repeat_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.rule == null ? 'Add recurring rule' : 'Edit rule',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: FutureBuilder<List<CategoryEntity>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.expenseCoral.withValues(
                          alpha: isDark ? 0.15 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.expenseCoral.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: AppTheme.expenseCoral,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Could not load categories',
                              style: TextStyle(
                                color: AppTheme.expenseCoral,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _categoriesFuture = _loadCategories()),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
                );
              }
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final categories = snapshot.data!
                  .where(
                    (category) =>
                        !category.isArchived &&
                        category.type == _categoryType(_kind),
                  )
                  .toList();
              return _buildForm(context, categories);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          BlocBuilder<RecurringBloc, RecurringState>(
            builder: (context, state) {
              final isSaving = state is RecurringLoaded && state.isSaving;
              return FilledButton(
                onPressed: isSaving ? null : _save,
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Rule'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, List<CategoryEntity> categories) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.rule == null) ...[
              SegmentedButton<TransactionKind>(
                segments: const [
                  ButtonSegment(
                    value: TransactionKind.expense,
                    label: Text('Expense'),
                    icon: Icon(Icons.arrow_upward_rounded, size: 16),
                  ),
                  ButtonSegment(
                    value: TransactionKind.income,
                    label: Text('Income'),
                    icon: Icon(Icons.arrow_downward_rounded, size: 16),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (selection) {
                  setState(() {
                    _kind = selection.first;
                    _categoryId = null;
                  });
                },
              ),
              const SizedBox(height: 14),
            ],
            TextFormField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount',
                suffixText: 'EGP',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: _validateAmount,
            ),
            if (_kind == TransactionKind.income) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title (e.g. Salary, Retainer)',
                  prefixIcon: Icon(Icons.title_rounded),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Income title is required.'
                    : null,
              ),
            ],
            const SizedBox(height: 12),
            if (categories.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppTheme.warningAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Add an active category in Settings to continue.',
                  style: TextStyle(color: AppTheme.warningAmber, fontSize: 13),
                ),
              ),
            DropdownButtonFormField<int>(
              key: ValueKey((_kind, _categoryId)),
              initialValue:
                  categories.any((category) => category.id == _categoryId)
                  ? _categoryId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                for (final category in categories)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ),
              ],
              onChanged: (id) => setState(() => _categoryId = id),
              validator: (id) => id == null ? 'Choose a category.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dayController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Day of month (1-31)',
                prefixIcon: Icon(Icons.calendar_today_rounded),
                helperText: 'Days 29–31 adjust to the month’s last day.',
              ),
              validator: (value) {
                final day = int.tryParse(value ?? '');
                return day == null || day < 1 || day > 31
                    ? 'Enter a day from 1 to 31.'
                    : null;
              },
            ),
            const SizedBox(height: 12),
            _DatePickerRow(
              label: 'Starts',
              date: _startDate,
              onTap: _pickStartDate,
            ),
            const SizedBox(height: 6),
            _DatePickerRow(
              label: 'Ends',
              date: _endDate,
              onTap: _pickEndDate,
              onClear: _endDate == null
                  ? null
                  : () => setState(() => _endDate = null),
            ),
            BlocBuilder<RecurringBloc, RecurringState>(
              builder: (context, state) {
                final message = switch (state) {
                  RecurringLoaded(:final errorMessage) => errorMessage,
                  RecurringError(:final message) => message,
                  _ => null,
                };
                return message == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          message,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  String? _validateAmount(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    if (amount == null ||
        !amount.isFinite ||
        amount <= 0 ||
        (amount * 100).round() <= 0) {
      return 'Enter an amount greater than zero.';
    }
    return null;
  }

  Future<void> _pickStartDate() async {
    final date = await _pickDate(_startDate);
    if (date != null) setState(() => _startDate = date);
  }

  Future<void> _pickEndDate() async {
    final date = await _pickDate(_endDate ?? _startDate);
    if (date != null) setState(() => _endDate = date);
  }

  Future<DateTime?> _pickDate(DateTime initialDate) {
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2100);
    final clampedInitialDate = initialDate.isBefore(firstDate)
        ? firstDate
        : initialDate.isAfter(lastDate)
        ? lastDate
        : initialDate;
    return showDatePicker(
      context: context,
      initialDate: clampedInitialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text.trim());
    final dayOfMonth = int.parse(_dayController.text);
    final categoryId = _categoryId;
    if (categoryId == null) return;
    context.read<RecurringBloc>().add(
      RuleSaveRequested(
        RecurringRuleDraft(
          id: widget.rule?.id,
          kind: _kind,
          amountMinor: (amount * 100).round(),
          categoryId: categoryId,
          title: _kind == TransactionKind.income
              ? _titleController.text.trim()
              : _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
          dayOfMonth: dayOfMonth,
          startDate: _startDate,
          endDate: _endDate,
        ),
      ),
    );
  }

  Future<List<CategoryEntity>> _loadCategories() =>
      getIt<CategoryRepository>().watchCategories().first;
}

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({
    required this.label,
    required this.date,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      '$label: ${date == null ? 'Never' : DateFormat.yMMMd().format(date!)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (onClear != null)
            IconButton(
              tooltip: 'Clear end date',
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppTheme.expenseCoral.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: AppTheme.expenseCoral.withValues(alpha: 0.3),
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppTheme.expenseCoral,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Retry recurring rules',
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 20),
        ),
      ],
    ),
  );
}

CategoryType _categoryType(TransactionKind kind) => switch (kind) {
  TransactionKind.income => CategoryType.income,
  TransactionKind.expense => CategoryType.expense,
};
