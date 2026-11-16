import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icons.dart';
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

String _signed(int minor) {
  if (minor == 0) return formatMinor(0);
  return '${minor > 0 ? '+' : '−'}${formatMinor(minor.abs())}';
}

Color _accentFor(TransactionKind kind) => kind == TransactionKind.income
    ? AppTheme.incomeGreen
    : AppTheme.expenseCoral;

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
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryEmerald.withValues(alpha: 0.3),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recurring rules',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'Monthly subscriptions, bills & salary',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
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
                      onAdd: () => _editRule(context),
                    ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
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

// ---------------------------------------------------------------------------
// List
// ---------------------------------------------------------------------------

class _RulesList extends StatelessWidget {
  const _RulesList({
    required this.rules,
    required this.errorMessage,
    required this.onEdit,
    required this.onAdd,
  });

  final List<RecurringRuleEntity> rules;
  final String? errorMessage;
  final ValueChanged<RecurringRuleEntity> onEdit;
  final VoidCallback onAdd;

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
                size: 48,
                color: AppTheme.primaryEmerald,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No recurring rules yet',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Add rules to automatically record monthly subscriptions, '
              'bills, or salary.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 50),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add first rule'),
          ),
          const Spacer(),
        ],
      );
    }

    var incomeMinor = 0;
    var expenseMinor = 0;
    var activeCount = 0;
    for (final rule in rules.where((r) => r.isActive)) {
      activeCount++;
      if (rule.kind == TransactionKind.income) {
        incomeMinor += rule.amountMinor;
      } else {
        expenseMinor += rule.amountMinor;
      }
    }

    return Column(
      children: [
        ?retryBanner,
        _Summary(
          incomeMinor: incomeMinor,
          expenseMinor: expenseMinor,
          activeCount: activeCount,
          totalCount: rules.length,
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: rules.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == rules.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: OutlinedButton.icon(
                    onPressed: onAdd,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add recurring rule'),
                  ),
                );
              }
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
    final shouldDelete = await showDialog<bool>(
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
            Icons.delete_rounded,
            color: AppTheme.expenseCoral,
            size: 26,
          ),
        ),
        title: const Text('Delete recurring rule?'),
        content: Text(
          'Existing ${rule.kind == TransactionKind.income ? 'income' : 'expense'} '
          'entries will remain in your history. This action cannot be undone.',
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

// ---------------------------------------------------------------------------
// Summary hero
// ---------------------------------------------------------------------------

class _Summary extends StatelessWidget {
  const _Summary({
    required this.incomeMinor,
    required this.expenseMinor,
    required this.activeCount,
    required this.totalCount,
  });

  final int incomeMinor;
  final int expenseMinor;
  final int activeCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final net = incomeMinor - expenseMinor;
    final isNegative = net < 0;
    final glow = isNegative ? AppTheme.expenseCoral : AppTheme.primaryEmerald;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: isDark
            ? AppTheme.darkCardGradient
            : isNegative
            ? AppTheme.expenseGradient
            : AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45)
                : glow.withValues(alpha: 0.3),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -42,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.09),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Net per month',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$activeCount of $totalCount active',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _signed(net),
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1,
                      height: 1.05,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryChip(
                        icon: Icons.south_west_rounded,
                        label: 'Income',
                        amount: incomeMinor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryChip(
                        icon: Icons.north_east_rounded,
                        label: 'Expenses',
                        amount: expenseMinor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.amount,
  });

  final IconData icon;
  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.22),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatMinor(amount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
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

// ---------------------------------------------------------------------------
// Rule card
// ---------------------------------------------------------------------------

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
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isIncome = rule.kind == TransactionKind.income;
    final accent = _accentFor(rule.kind);
    final dim = rule.isActive ? 1.0 : 0.5;
    final hasDistinctTitle =
        rule.title != null && rule.title != rule.categoryName;

    return Material(
      color: theme.cardColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.3 : 0.5),
        ),
      ),
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
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          isIncome
                              ? Icons.south_west_rounded
                              : Icons.north_east_rounded,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            if (hasDistinctTitle)
                              Text(
                                rule.categoryName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: scheme.onSurfaceVariant,
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
                            icon: Icons.calendar_today_rounded,
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
                  if (!rule.isActive)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        'Paused',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurfaceVariant,
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
                            Icon(Icons.edit_rounded, size: 18),
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
                              Icons.delete_rounded,
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: scheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Editor sheet
// ---------------------------------------------------------------------------

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
  bool _categoryMissing = false;

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
    final accent = _accentFor(_kind);

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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.event_repeat_rounded,
                        color: accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        widget.rule == null
                            ? 'Add recurring rule'
                            : 'Edit rule',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
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
    final scheme = theme.colorScheme;
    final accent = _accentFor(_kind);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.rule == null) ...[
            Row(
              children: [
                Expanded(
                  child: _KindChoice(
                    label: 'Expense',
                    icon: Icons.north_east_rounded,
                    color: AppTheme.expenseCoral,
                    selected: _kind == TransactionKind.expense,
                    onTap: () => _setKind(TransactionKind.expense),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _KindChoice(
                    label: 'Income',
                    icon: Icons.south_west_rounded,
                    color: AppTheme.incomeGreen,
                    selected: _kind == TransactionKind.income,
                    onTap: () => _setKind(TransactionKind.income),
                  ),
                ),
              ],
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
            const SizedBox(height: 14),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Title (e.g. Salary, Retainer)',
                prefixIcon: const Icon(Icons.title_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Income title is required.'
                  : null,
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(
                Icons.category_rounded,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Category',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (categories.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningAmber.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
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
                        color: scheme.onSurface,
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
                for (final category in categories)
                  _CategoryChip(
                    name: category.name,
                    iconKey: category.iconKey,
                    selected: category.id == _categoryId,
                    accent: accent,
                    onTap: () => setState(() {
                      _categoryId = category.id;
                      _categoryMissing = false;
                    }),
                  ),
              ],
            ),
          if (_categoryMissing)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 0, 0),
              child: Text(
                'Choose a category.',
                style: TextStyle(fontSize: 12.5, color: scheme.error),
              ),
            ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _dayController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Day of month (1-31)',
              prefixIcon: const Icon(Icons.calendar_today_rounded),
              helperText: 'Days 29–31 adjust to the month’s last day.',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            validator: (value) {
              final day = int.tryParse(value ?? '');
              return day == null || day < 1 || day > 31
                  ? 'Enter a day from 1 to 31.'
                  : null;
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DateTile(
                  label: 'Starts',
                  icon: Icons.play_circle_outline_rounded,
                  date: _startDate,
                  onTap: _pickStartDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateTile(
                  label: 'Ends',
                  icon: Icons.flag_outlined,
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
              return _SaveButton(
                saving: isSaving,
                label: widget.rule == null ? 'Save rule' : 'Update rule',
                accent: accent,
                gradient: _kind == TransactionKind.income
                    ? AppTheme.incomeGradient
                    : AppTheme.expenseGradient,
                onTap: _save,
              );
            },
          ),
        ],
      ),
    );
  }

  void _setKind(TransactionKind kind) {
    if (kind == _kind) return;
    setState(() {
      _kind = kind;
      _categoryId = null;
      _categoryMissing = false;
    });
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
    final formValid = _formKey.currentState!.validate();
    final categoryId = _categoryId;
    if (categoryId == null) {
      setState(() => _categoryMissing = true);
    }
    if (!formValid || categoryId == null) return;

    final amount = double.parse(_amountController.text.trim());
    final dayOfMonth = int.parse(_dayController.text);
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

class _KindChoice extends StatelessWidget {
  const _KindChoice({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? color : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected
                ? color
                : scheme.outlineVariant.withValues(alpha: 0.7),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.name,
    required this.iconKey,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String name;
  final String iconKey;
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
      label: name,
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
                        : CategoryIcons.getIcon(iconKey),
                    size: 17,
                    color: fg,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    name,
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

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.icon,
    required this.date,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final IconData icon;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14, 10, onClear == null ? 14 : 4, 10),
          child: Row(
            children: [
              Icon(icon, size: 20, color: scheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        fontSize: 10.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date == null ? 'Never' : DateFormat.yMMMd().format(date!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
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

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.saving,
    required this.label,
    required this.accent,
    required this.gradient,
    required this.onTap,
  });

  final bool saving;
  final String label;
  final Color accent;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: saving
            ? null
            : [
                BoxShadow(
                  color: accent.withValues(alpha: 0.32),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: saving ? null : onTap,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: saving
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
                      const Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppTheme.expenseCoral.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.error_outline_rounded,
            size: 34,
            color: AppTheme.expenseCoral,
          ),
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
