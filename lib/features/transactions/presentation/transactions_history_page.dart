import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../../core/utils/money_format.dart';
import '../../shell/presentation/month_cubit.dart';
import '../domain/transaction_entity.dart';
import 'transactions_bloc.dart';
import 'transaction_form_sheet.dart';

enum TransactionSort { newest, oldest, highestAmount, lowestAmount }

extension on TransactionSort {
  String get label => switch (this) {
    TransactionSort.newest => 'Newest first',
    TransactionSort.oldest => 'Oldest first',
    TransactionSort.highestAmount => 'Highest amount',
    TransactionSort.lowestAmount => 'Lowest amount',
  };

  String get shortLabel => switch (this) {
    TransactionSort.newest => 'Newest',
    TransactionSort.oldest => 'Oldest',
    TransactionSort.highestAmount => 'Highest',
    TransactionSort.lowestAmount => 'Lowest',
  };

  IconData get icon => switch (this) {
    TransactionSort.newest => Icons.arrow_downward_rounded,
    TransactionSort.oldest => Icons.arrow_upward_rounded,
    TransactionSort.highestAmount => Icons.trending_up_rounded,
    TransactionSort.lowestAmount => Icons.trending_down_rounded,
  };

  bool get isByDate =>
      this == TransactionSort.newest || this == TransactionSort.oldest;
}

String _signed(int minor) {
  if (minor == 0) return formatMinor(0);
  return '${minor > 0 ? '+' : '−'}${formatMinor(minor.abs())}';
}

String _dayLabel(DateTime day) {
  final now = DateTime.now();
  if (day == DateTime(now.year, now.month, now.day)) return 'Today';
  if (day == DateTime(now.year, now.month, now.day - 1)) return 'Yesterday';
  return DateFormat('EEE, MMM d').format(day);
}

class TransactionsHistoryPage extends StatelessWidget {
  const TransactionsHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<MonthCubit>()),
        BlocProvider(
          create: (context) =>
              getIt<TransactionsBloc>()
                ..add(MonthChanged(context.read<MonthCubit>().state)),
        ),
      ],
      child: const _TransactionsHistoryView(),
    );
  }
}

class _TransactionsHistoryView extends StatefulWidget {
  const _TransactionsHistoryView();

  @override
  State<_TransactionsHistoryView> createState() =>
      _TransactionsHistoryViewState();
}

class _TransactionsHistoryViewState extends State<_TransactionsHistoryView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TransactionKind? _selectedKind;
  TransactionSort _sortOrder = TransactionSort.newest;

  bool get _hasFilters => _searchQuery.isNotEmpty || _selectedKind != null;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedKind = null;
    });
  }

  List<TransactionEntity> _applyFilters(List<TransactionEntity> all) {
    final filtered = all.where((tx) {
      if (_selectedKind != null && tx.kind != _selectedKind) return false;
      if (_searchQuery.isNotEmpty) {
        final titleMatch =
            tx.title?.toLowerCase().contains(_searchQuery) ?? false;
        final categoryMatch = tx.categoryName.toLowerCase().contains(
          _searchQuery,
        );
        if (!titleMatch && !categoryMatch) return false;
      }
      return true;
    }).toList();

    filtered.sort(
      (a, b) => switch (_sortOrder) {
        TransactionSort.newest => b.createdAt.compareTo(a.createdAt),
        TransactionSort.oldest => a.createdAt.compareTo(b.createdAt),
        TransactionSort.highestAmount => b.amountMinor.compareTo(a.amountMinor),
        TransactionSort.lowestAmount => a.amountMinor.compareTo(b.amountMinor),
      },
    );
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MonthCubit, DateTime>(
      listener: (context, month) =>
          context.read<TransactionsBloc>().add(MonthChanged(month)),
      child: Scaffold(
        appBar: AppBar(title: const Text('All transactions')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: _SearchField(
                controller: _searchController,
                hasText: _searchQuery.isNotEmpty,
                onChanged: (v) =>
                    setState(() => _searchQuery = v.trim().toLowerCase()),
                onClear: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _MonthBar(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterPill(
                            label: 'All',
                            selected: _selectedKind == null,
                            color: AppTheme.primaryEmerald,
                            onTap: () => setState(() => _selectedKind = null),
                          ),
                          const SizedBox(width: 8),
                          _FilterPill(
                            label: 'Income',
                            icon: Icons.south_west_rounded,
                            selected: _selectedKind == TransactionKind.income,
                            color: AppTheme.incomeGreen,
                            onTap: () => setState(
                              () => _selectedKind = TransactionKind.income,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _FilterPill(
                            label: 'Expense',
                            icon: Icons.north_east_rounded,
                            selected: _selectedKind == TransactionKind.expense,
                            color: AppTheme.expenseCoral,
                            onTap: () => setState(
                              () => _selectedKind = TransactionKind.expense,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SortButton(
                    value: _sortOrder,
                    onChanged: (sort) => setState(() => _sortOrder = sort),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<TransactionsBloc, TransactionsState>(
                builder: (context, state) => switch (state) {
                  TransactionsLoading() => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  TransactionsError(:final message) => _MessageView(
                    icon: Icons.cloud_off_rounded,
                    color: AppTheme.expenseCoral,
                    title: message,
                  ),
                  TransactionsLoaded(:final transactions) => _buildLoaded(
                    context,
                    _applyFilters(transactions),
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, List<TransactionEntity> filtered) {
    if (filtered.isEmpty) {
      return _MessageView(
        icon: _hasFilters
            ? Icons.search_off_rounded
            : Icons.receipt_long_outlined,
        color: AppTheme.primaryEmerald,
        title: _hasFilters
            ? 'No matching transactions'
            : 'No transactions this month',
        body: _hasFilters ? 'Try a different search or filter.' : null,
        actionLabel: _hasFilters ? 'Clear filters' : null,
        onAction: _hasFilters ? _clearFilters : null,
      );
    }

    var income = 0;
    var expense = 0;
    for (final t in filtered) {
      if (t.kind == TransactionKind.income) {
        income += t.amountMinor;
      } else {
        expense += t.amountMinor;
      }
    }

    final children = <Widget>[
      _SummaryCard(income: income, expense: expense, count: filtered.length),
      const SizedBox(height: 16),
    ];

    if (_sortOrder.isByDate) {
      final groups = <DateTime, List<TransactionEntity>>{};
      for (final t in filtered) {
        final c = t.createdAt;
        groups.putIfAbsent(DateTime(c.year, c.month, c.day), () => []).add(t);
      }
      for (final entry in groups.entries) {
        children.add(_DayGroup(day: entry.key, transactions: entry.value));
      }
    } else {
      children.add(_RowsCard(transactions: filtered, showDate: true));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      children: children,
    );
  }
}

// ---------------------------------------------------------------------------
// Controls
// ---------------------------------------------------------------------------

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hasText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool hasText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search by title or category',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: hasText
            ? IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close_rounded),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppTheme.primaryEmerald,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<MonthCubit>();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: BlocBuilder<MonthCubit, DateTime>(
        builder: (context, month) => Row(
          children: [
            IconButton(
              tooltip: 'Previous month',
              onPressed: cubit.canGoPrevious ? cubit.previous : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  DateFormat.yMMMM().format(month),
                  key: ValueKey(month),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next month',
              onPressed: cubit.canGoNext ? cubit.next : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final Color color;
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 15, color: fg),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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

class _SortButton extends StatelessWidget {
  const _SortButton({required this.value, required this.onChanged});

  final TransactionSort value;
  final ValueChanged<TransactionSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<TransactionSort>(
      tooltip: 'Sort',
      initialValue: value,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (_) => [
        for (final sort in TransactionSort.values)
          PopupMenuItem(
            value: sort,
            child: Row(
              children: [
                Icon(sort.icon, size: 18),
                const SizedBox(width: 10),
                Text(sort.label),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort_rounded, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              value.shortLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.income,
    required this.expense,
    required this.count,
  });

  final int income;
  final int expense;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget cell(String label, int amount, Color color, IconData icon) {
      return Expanded(
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 17, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatMinor(amount),
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: color,
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

    return Material(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.3 : 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                cell(
                  'Income',
                  income,
                  AppTheme.incomeGreen,
                  Icons.south_west_rounded,
                ),
                const SizedBox(width: 10),
                cell(
                  'Expenses',
                  expense,
                  AppTheme.expenseCoral,
                  Icons.north_east_rounded,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                count == 1 ? '1 transaction' : '$count transactions',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List
// ---------------------------------------------------------------------------

class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.day, required this.transactions});

  final DateTime day;
  final List<TransactionEntity> transactions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final net = transactions.fold<int>(
      0,
      (sum, t) =>
          sum +
          (t.kind == TransactionKind.income ? t.amountMinor : -t.amountMinor),
    );
    final netColor = net > 0
        ? AppTheme.incomeGreen
        : net < 0
        ? AppTheme.expenseCoral
        : theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _dayLabel(day),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: netColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _signed(net),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: netColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _RowsCard(transactions: transactions, showDate: false),
        ],
      ),
    );
  }
}

class _RowsCard extends StatelessWidget {
  const _RowsCard({required this.transactions, required this.showDate});

  final List<TransactionEntity> transactions;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline = theme.colorScheme.outlineVariant;

    return Material(
      color: theme.cardColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: outline.withValues(alpha: isDark ? 0.3 : 0.5)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < transactions.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 72,
                color: outline.withValues(alpha: 0.4),
              ),
            _TransactionRow(transaction: transactions[i], showDate: showDate),
          ],
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction, required this.showDate});

  final TransactionEntity transaction;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isIncome = transaction.kind == TransactionKind.income;
    final accent = isIncome ? AppTheme.incomeGreen : AppTheme.expenseCoral;

    final rawTitle = transaction.title;
    final hasTitle = rawTitle != null && rawTitle.isNotEmpty;
    final title = hasTitle ? rawTitle : transaction.categoryName;
    final when = showDate
        ? DateFormat('MMM d · h:mm a').format(transaction.createdAt)
        : DateFormat.jm().format(transaction.createdAt);
    final subtitle = hasTitle ? '${transaction.categoryName} · $when' : when;

    return InkWell(
      onTap: () => showTransactionForm(
        context,
        kind: transaction.kind,
        transaction: transaction,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                CategoryIcons.getIcon(transaction.categoryIconKey),
                size: 22,
                color: accent,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${isIncome ? '+' : '−'}${formatMinor(transaction.amountMinor)}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: -0.2,
                color: isIncome ? AppTheme.incomeGreen : scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty and error states
// ---------------------------------------------------------------------------

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.color,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (body != null) ...[
              const SizedBox(height: 6),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 18),
              FilledButton.tonalIcon(
                onPressed: onAction,
                icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
