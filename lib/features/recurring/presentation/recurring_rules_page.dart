import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_format.dart';
import '../../../core/widgets/amount_hero_field.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../core/widgets/entrance_animation.dart';
import '../../../core/widgets/inline_error_banner.dart';
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
      // Background, shape and drag handle come from AppTheme.bottomSheetTheme.
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recurring Rules',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Automated monthly subscriptions & bills',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                BlocBuilder<RecurringBloc, RecurringState>(
                  builder: (context, state) => FilledButton.icon(
                    style: FilledButton.styleFrom(
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
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.inputDecorationTheme.fillColor,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 20),
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: context.read<RecurringBloc>(),
        child: _RuleEditorSheet(rule: rule),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final retryBanner = errorMessage == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InlineErrorBanner(
              message: errorMessage!,
              retryTooltip: 'Retry recurring rules',
              onRetry: () => context.read<RecurringBloc>().add(
                const RecurringRetryRequested(),
              ),
            ),
          );

    if (rules.isEmpty) {
      return Column(
        children: [
          ?retryBanner,
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
                size: 52,
                color: AppTheme.primaryEmerald,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('No recurring rules yet', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Add rules to automatically record monthly subscriptions, bills, or salary.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const Spacer(),
        ],
      );
    }

    var incomeMinor = 0;
    var expenseMinor = 0;
    for (final rule in rules.where((r) => r.isActive)) {
      if (rule.kind == TransactionKind.income) {
        incomeMinor += rule.amountMinor;
      } else {
        expenseMinor += rule.amountMinor;
      }
    }

    return Column(
      children: [
        ?retryBanner,
        _Summary(incomeMinor: incomeMinor, expenseMinor: expenseMinor),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: rules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final rule = rules[index];
              return EntranceAnimation(
                delay: Duration(milliseconds: index < 10 ? index * 30 : 300),
                duration: const Duration(milliseconds: 320),
                offset: const Offset(0, 0.03),
                child: _RuleCard(
                  rule: rule,
                  onEdit: () => onEdit(rule),
                  onDelete: () => _deleteRule(context, rule),
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
                color: AppTheme.expenseCoral.withValues(
                  alpha: isDark ? 0.2 : 0.12,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: AppTheme.expenseCoral,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(child: Text('Delete recurring rule?')),
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
                color: AppTheme.expenseCoral.withValues(
                  alpha: isDark ? 0.16 : 0.1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppTheme.expenseCoral,
                  ),
                  SizedBox(width: 8),
                  Expanded(
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
              minimumSize: const Size(0, 44),
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

class _Summary extends StatelessWidget {
  const _Summary({required this.incomeMinor, required this.expenseMinor});

  final int incomeMinor;
  final int expenseMinor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _SummaryCell(
                  label: 'Monthly income',
                  amountMinor: incomeMinor,
                  color: AppTheme.incomeGreen,
                ),
              ),
              const VerticalDivider(width: 24),
              Expanded(
                child: _SummaryCell(
                  label: 'Monthly expenses',
                  amountMinor: expenseMinor,
                  color: AppTheme.expenseCoral,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.amountMinor,
    required this.color,
  });

  final String label;
  final int amountMinor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            formatMinor(amountMinor),
            style: theme.textTheme.titleLarge?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.onEdit,
    required this.onDelete,
  });

  final RecurringRuleEntity rule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isIncome = rule.kind == TransactionKind.income;
    final accent = isIncome ? AppTheme.incomeGreen : AppTheme.expenseCoral;
    final dim = rule.isActive ? 1.0 : 0.5;
    final hasDistinctTitle =
        rule.title != null && rule.title != rule.categoryName;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 6, 6),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Opacity(
                  opacity: dim,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isIncome
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: accent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rule.title ?? rule.categoryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontSize: 15,
                              ),
                            ),
                            if (hasDistinctTitle)
                              Text(
                                rule.categoryName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${isIncome ? '+' : '−'}${formatMinor(rule.amountMinor)}',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Opacity(
                      opacity: dim,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _MetaPill(
                            icon: Icons.event_repeat_rounded,
                            label: 'Day ${rule.dayOfMonth}',
                          ),
                          if (rule.endDate != null)
                            _MetaPill(
                              icon: Icons.flag_outlined,
                              label:
                                  'Ends ${DateFormat.yMMMd().format(rule.endDate!)}',
                            ),
                        ],
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: rule.isActive,
                    activeTrackColor: AppTheme.primaryEmerald,
                    onChanged: (isActive) => context.read<RecurringBloc>().add(
                      RuleToggled(id: rule.id, isActive: isActive),
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Rule options',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (action) {
                      if (action == 'edit') onEdit();
                      if (action == 'delete') onDelete();
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
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleEditorSheet extends StatefulWidget {
  const _RuleEditorSheet({this.rule});

  final RecurringRuleEntity? rule;

  @override
  State<_RuleEditorSheet> createState() => _RuleEditorSheetState();
}

class _RuleEditorSheetState extends State<_RuleEditorSheet> {
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
    final theme = Theme.of(context);

    return BlocListener<RecurringBloc, RecurringState>(
      listenWhen: (previous, current) =>
          previous is RecurringLoaded &&
          current is RecurringLoaded &&
          previous.saveRevision != current.saveRevision,
      listener: (context, state) => Navigator.of(context).pop(),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryEmerald.withValues(
                              alpha: 0.28,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.event_repeat_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.rule == null
                            ? 'Add recurring rule'
                            : 'Edit rule',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.inputDecorationTheme.fillColor,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FutureBuilder<List<CategoryEntity>>(
                  future: _categoriesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return InlineErrorBanner(
                        message: 'Could not load categories',
                        retryTooltip: 'Retry',
                        onRetry: () => setState(
                          () => _categoriesFuture = _loadCategories(),
                        ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, List<CategoryEntity> categories) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.rule == null) ...[
            SegmentedButton<TransactionKind>(
              showSelectedIcon: false,
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
            const SizedBox(height: 16),
          ],
          AmountHeroField(
            controller: _amountController,
            caption: _kind == TransactionKind.income
                ? 'INCOME · EGP / MONTH'
                : 'EXPENSE · EGP / MONTH',
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
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
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.warningAmber.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: AppTheme.warningAmber,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add an active category in Settings to continue.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          DropdownButtonFormField<int>(
            key: ValueKey((_kind, _categoryId)),
            isExpanded: true,
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
          Row(
            children: [
              Expanded(
                child: _DateTile(
                  label: 'Starts',
                  date: _startDate,
                  onTap: _pickStartDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateTile(
                  label: 'Ends',
                  date: _endDate,
                  onTap: _pickEndDate,
                  onClear: _endDate == null
                      ? null
                      : () => setState(() => _endDate = null),
                ),
              ),
            ],
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
                      padding: const EdgeInsets.only(top: 16),
                      child: InlineErrorBanner(message: message),
                    );
            },
          ),
          const SizedBox(height: 24),
          BlocBuilder<RecurringBloc, RecurringState>(
            builder: (context, state) {
              final isSaving = state is RecurringLoaded && state.isSaving;
              return FilledButton(
                onPressed: isSaving ? null : _save,
                child: isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save rule'),
              );
            },
          ),
        ],
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

class _DateTile extends StatelessWidget {
  const _DateTile({
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
    final theme = Theme.of(context);

    return Material(
      color: theme.inputDecorationTheme.fillColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 10, onClear == null ? 14 : 4, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      date == null ? 'Never' : DateFormat.yMMMd().format(date!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClear != null)
                IconButton(
                  tooltip: 'Clear end date',
                  onPressed: onClear,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
            ],
          ),
        ),
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
        const Icon(
          Icons.error_outline_rounded,
          size: 48,
          color: AppTheme.expenseCoral,
        ),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 18),
        FilledButton.tonalIcon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ],
    ),
  );
}

CategoryType _categoryType(TransactionKind kind) => switch (kind) {
  TransactionKind.income => CategoryType.income,
  TransactionKind.expense => CategoryType.expense,
};
