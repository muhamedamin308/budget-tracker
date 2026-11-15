// lib/features/stats/presentation/stats_page.dart

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_format.dart';
import '../../../core/widgets/entrance_animation.dart';
import '../../budget/domain/budget_status.dart';
import '../../budget/presentation/budget_bloc.dart';
import '../../shell/presentation/month_cubit.dart';
import '../domain/month_stats.dart';
import 'stats_bloc.dart';

const List<Color> _palette = [
  Color(0xFF10B981),
  Color(0xFF3B82F6),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
];
const Color _othersColor = Color(0xFF94A3B8);

bool _sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

String _signed(int minor) {
  if (minor == 0) return formatMinor(0);
  return '${minor > 0 ? '+' : '−'}${formatMinor(minor.abs())}';
}

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<StatsBloc>()
            ..add(MonthChanged(context.read<MonthCubit>().state)),
      child: const _StatsPageView(),
    );
  }
}

class _StatsPageView extends StatelessWidget {
  const _StatsPageView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<MonthCubit, DateTime>(
      listener: (context, month) =>
          context.read<StatsBloc>().add(MonthChanged(month)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Insights',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Where your money went this month',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              BlocBuilder<MonthCubit, DateTime>(
                builder: (context, month) => _MonthSelector(month: month),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: BlocBuilder<StatsBloc, StatsState>(
                  builder: (context, state) => switch (state) {
                    StatsLoading() => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    StatsError(:final message) => _RetryView(
                      message: message,
                      onRetry: () => context.read<StatsBloc>().add(
                        const StatsRetryRequested(),
                      ),
                    ),
                    StatsLoaded(:final monthStats, :final bucketType) =>
                      _StatsContent(
                        monthStats: monthStats,
                        bucketType: bucketType,
                      ),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Building blocks
// ---------------------------------------------------------------------------

class _Surface extends StatelessWidget {
  const _Surface({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: theme.cardColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.3 : 0.5,
          ),
        ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon, required this.color, this.size = 38});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

// ---------------------------------------------------------------------------
// Month selector
// ---------------------------------------------------------------------------

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MonthCubit>();
    final theme = Theme.of(context);

    return _Surface(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous month',
            onPressed: cubit.canGoPrevious ? cubit.previous : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: Text(
                DateFormat.yMMMM().format(month),
                key: ValueKey(month),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
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
    );
  }
}

// ---------------------------------------------------------------------------
// Content
// ---------------------------------------------------------------------------

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.monthStats, required this.bucketType});

  final MonthStats monthStats;
  final StatsBucketType bucketType;

  @override
  Widget build(BuildContext context) {
    final hasSpending = monthStats.expenseMinor > 0;

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        EntranceAnimation(child: _HeroCard(stats: monthStats)),
        const SizedBox(height: 14),
        EntranceAnimation(
          delay: const Duration(milliseconds: 50),
          child: _BudgetCard(month: monthStats.month),
        ),
        if (hasSpending) ...[
          const SizedBox(height: 14),
          EntranceAnimation(
            delay: const Duration(milliseconds: 90),
            child: _InsightsRow(stats: monthStats),
          ),
        ],
        const SizedBox(height: 24),
        EntranceAnimation(
          delay: const Duration(milliseconds: 130),
          child: const _SectionTitle('Where it went'),
        ),
        EntranceAnimation(
          delay: const Duration(milliseconds: 140),
          child: hasSpending
              ? _CategoriesCard(stats: monthStats)
              : const _EmptyCard(
                  icon: Icons.pie_chart_outline_rounded,
                  message: 'No expenses recorded this month.',
                ),
        ),
        const SizedBox(height: 24),
        EntranceAnimation(
          delay: const Duration(milliseconds: 180),
          child: _SectionTitle(
            'Spending trend',
            trailing: _BucketToggle(
              value: bucketType,
              onChanged: (type) =>
                  context.read<StatsBloc>().add(BucketToggled(type)),
            ),
          ),
        ),
        EntranceAnimation(
          delay: const Duration(milliseconds: 190),
          child: hasSpending
              ? _TrendCard(
                  buckets: bucketType == StatsBucketType.daily
                      ? monthStats.dailyBuckets
                      : monthStats.weeklyBuckets,
                  bucketType: bucketType,
                )
              : const _EmptyCard(
                  icon: Icons.show_chart_rounded,
                  message: 'No spending trend to chart.',
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hero: net cash flow
// ---------------------------------------------------------------------------

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.stats});

  final MonthStats stats;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final net = stats.netMinor;
    final isNegative = net < 0;
    final income = stats.incomeMinor;
    final expense = stats.expenseMinor;
    final total = income + expense;
    final glow = isNegative ? AppTheme.expenseCoral : AppTheme.primaryEmerald;

    String? chip;
    if (income > 0) {
      chip = net >= 0 ? 'Saved ${(net / income * 100).round()}%' : 'Overspent';
    }

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: isDark
            ? AppTheme.darkCardGradient
            : isNegative
            ? AppTheme.expenseGradient
            : AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.45)
                : glow.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -44,
            child: _Orb(size: 150, alpha: isDark ? 0.05 : 0.09),
          ),
          Positioned(
            right: 60,
            bottom: -60,
            child: _Orb(size: 110, alpha: isDark ? 0.04 : 0.07),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Net cash flow',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    if (chip != null)
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
                          chip,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _signed(net),
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1.1,
                      height: 1.05,
                    ),
                  ),
                ),
                if (total > 0) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          if (income > 0)
                            Expanded(
                              flex: income,
                              child: Container(color: Colors.white),
                            ),
                          if (income > 0 && expense > 0)
                            const SizedBox(width: 3),
                          if (expense > 0)
                            Expanded(
                              flex: expense,
                              child: Container(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _FlowStat(
                        icon: Icons.south_west_rounded,
                        label: 'Income',
                        amount: income,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FlowStat(
                        icon: Icons.north_east_rounded,
                        label: 'Expenses',
                        amount: expense,
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

class _FlowStat extends StatelessWidget {
  const _FlowStat({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Budget ring
// ---------------------------------------------------------------------------

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, state) => switch (state) {
        BudgetLoading() => const _BudgetSkeleton(),
        BudgetError(:final month) when _sameMonth(month, this.month) =>
          _Surface(
            padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
            child: Row(
              children: [
                const Expanded(child: Text('Could not load the budget.')),
                IconButton(
                  tooltip: 'Retry budget',
                  onPressed: () => context.read<BudgetBloc>().add(
                    const BudgetRetryRequested(),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
        BudgetError() => const _BudgetSkeleton(),
        BudgetLoaded(:final month) when !_sameMonth(month, this.month) =>
          const _BudgetSkeleton(),
        BudgetLoaded(:final status) => _buildStatus(context, status),
      },
    );
  }

  Widget _buildStatus(BuildContext context, BudgetStatus status) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (status.level == BudgetLevel.notSet) {
      return _Surface(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            const _IconChip(
              icon: Icons.speed_rounded,
              color: AppTheme.primaryEmerald,
              size: 42,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'No monthly budget set',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
              ),
            ),
            FilledButton.tonal(
              onPressed: () => context.go('/settings'),
              child: const Text('Set limit'),
            ),
          ],
        ),
      );
    }

    final color = switch (status.level) {
      BudgetLevel.exceeded => AppTheme.expenseCoral,
      BudgetLevel.warning => AppTheme.warningAmber,
      _ => AppTheme.primaryEmerald,
    };
    final limit = status.limitMinor ?? 0;
    final remaining = status.remainingMinor;
    final percent = (status.progress * 100).round();
    final statusLabel = switch (status.level) {
      BudgetLevel.exceeded => 'Over budget',
      BudgetLevel.warning => 'Close to limit',
      _ => 'On track',
    };

    return _Surface(
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0,
                    end: status.progress.clamp(0.0, 1.0).toDouble(),
                  ),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 10,
                      strokeCap: StrokeCap.round,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatMinor(status.spentMinor),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Text(
                  'of ${formatMinor(limit)} budget',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                if (remaining != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    remaining >= 0
                        ? '${formatMinor(remaining)} left'
                        : '${formatMinor(remaining.abs())} over',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSkeleton extends StatelessWidget {
  const _BudgetSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick insights
// ---------------------------------------------------------------------------

class _InsightsRow extends StatelessWidget {
  const _InsightsRow({required this.stats});

  final MonthStats stats;

  @override
  Widget build(BuildContext context) {
    final daily = stats.dailyBuckets;
    final avg = daily.isEmpty ? 0 : stats.expenseMinor ~/ daily.length;
    final peak = daily.isEmpty
        ? null
        : daily.reduce((a, b) => a.amountMinor >= b.amountMinor ? a : b);
    final top = stats.byCategory.isEmpty ? null : stats.byCategory.first;
    final topShare = top == null
        ? 0
        : (top.amountMinor / stats.expenseMinor * 100).round();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _InsightTile(
              icon: Icons.calendar_view_day_rounded,
              color: AppTheme.infoBlue,
              label: 'Daily avg',
              value: formatMinor(avg),
              sub: 'per day',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _InsightTile(
              icon: Icons.bolt_rounded,
              color: AppTheme.warningAmber,
              label: 'Peak day',
              value: peak == null ? '—' : formatMinor(peak.amountMinor),
              sub: peak == null ? '' : DateFormat.MMMd().format(peak.start),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _InsightTile(
              icon: Icons.local_fire_department_rounded,
              color: AppTheme.expenseCoral,
              label: 'Top category',
              value: top?.name ?? '—',
              sub: top == null ? '' : '$topShare% of spend',
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.sub,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _Surface(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconChip(icon: icon, color: color, size: 32),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (sub.isNotEmpty)
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Categories: stacked share bar + ranked rows
// ---------------------------------------------------------------------------

class _CategoriesCard extends StatelessWidget {
  const _CategoriesCard({required this.stats});

  final MonthStats stats;

  @override
  Widget build(BuildContext context) {
    final total = stats.expenseMinor;
    final top = stats.byCategory.take(5).toList();
    final othersAmount = stats.byCategory
        .skip(5)
        .fold<int>(0, (sum, c) => sum + c.amountMinor);

    final entries = <({String name, int amount, Color color})>[
      for (var i = 0; i < top.length; i++)
        (
          name: top[i].name,
          amount: top[i].amountMinor,
          color: _palette[i % _palette.length],
        ),
      if (othersAmount > 0)
        (name: 'Others', amount: othersAmount, color: _othersColor),
    ];

    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total spent',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatMinor(total),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${stats.byCategory.length} categories',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      flex: math.max(1, entries[i].amount),
                      child: Container(color: entries[i].color),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < entries.length; i++)
            _CategoryRow(
              rank: i + 1,
              name: entries[i].name,
              amount: entries[i].amount,
              share: entries[i].amount / total,
              color: entries[i].color,
            ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.rank,
    required this.name,
    required this.amount,
    required this.share,
    required this.color,
  });

  final int rank;
  final String name;
  final int amount;
  final double share;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              initial,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatMinor(amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0,
                            end: share.clamp(0.0, 1.0).toDouble(),
                          ),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) =>
                              LinearProgressIndicator(
                                value: value,
                                minHeight: 6,
                                color: color,
                                backgroundColor: color.withValues(alpha: 0.12),
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${(share * 100).toStringAsFixed(0)}%',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
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

// ---------------------------------------------------------------------------
// Trend: area line chart
// ---------------------------------------------------------------------------

class _BucketToggle extends StatelessWidget {
  const _BucketToggle({required this.value, required this.onChanged});

  final StatsBucketType value;
  final ValueChanged<StatsBucketType> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget pill(StatsBucketType type, String label) {
      final selected = value == type;
      return GestureDetector(
        onTap: () => onChanged(type),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryEmerald : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          pill(StatsBucketType.daily, 'Daily'),
          pill(StatsBucketType.weekly, 'Weekly'),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.buckets, required this.bucketType});

  final List<SpendingBucket> buckets;
  final StatsBucketType bucketType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDaily = bucketType == StatsBucketType.daily;

    final maxAmount = buckets.fold<int>(
      0,
      (m, b) => math.max(m, b.amountMinor),
    );
    final maxY = maxAmount == 0 ? 1.0 : maxAmount * 1.2;
    final labelEvery = isDaily ? 5 : 1;

    final line = LineChartBarData(
      spots: [
        for (var i = 0; i < buckets.length; i++)
          FlSpot(i.toDouble(), buckets[i].amountMinor.toDouble()),
      ],
      isCurved: true,
      preventCurveOverShooting: true,
      curveSmoothness: 0.25,
      barWidth: 3,
      color: AppTheme.primaryEmerald,
      isStrokeCapRound: true,
      dotData: FlDotData(show: buckets.length <= 8),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryEmerald.withValues(alpha: 0.32),
            AppTheme.primaryEmerald.withValues(alpha: 0.0),
          ],
        ),
      ),
    );

    return _Surface(
      padding: const EdgeInsets.fromLTRB(10, 18, 18, 10),
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            minX: 0,
            maxX: math.max(1, buckets.length - 1).toDouble(),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (_) => FlLine(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (value != i.toDouble() ||
                        i < 0 ||
                        i >= buckets.length ||
                        i % labelEvery != 0) {
                      return const SizedBox.shrink();
                    }
                    final date = buckets[i].start;
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        isDaily
                            ? date.day.toString()
                            : DateFormat.MMMd().format(date),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => scheme.inverseSurface,
                getTooltipItems: (spots) => [
                  for (final spot in spots)
                    LineTooltipItem(
                      '${DateFormat.MMMd().format(buckets[spot.x.toInt()].start)}\n'
                      '${formatMinor(buckets[spot.x.toInt()].amountMinor)}',
                      TextStyle(
                        color: scheme.onInverseSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            lineBarsData: [line],
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
  const _EmptyCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _Surface(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primaryEmerald.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: AppTheme.primaryEmerald),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RetryView extends StatelessWidget {
  const _RetryView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
