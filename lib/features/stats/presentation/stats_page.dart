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
import '../../../core/widgets/app_animations.dart';
import '../../../core/widgets/entrance_animation.dart';
import '../../budget/domain/budget_status.dart';
import '../../budget/presentation/budget_bloc.dart';
import '../../shell/presentation/month_cubit.dart';
import '../domain/month_stats.dart';
import 'stats_bloc.dart';

const List<Color> _categoryPalette = [
  Color(0xFF0D9373),
  Color(0xFF3B82F6),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
  Color(0xFF06B6D4),
];

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
    final isDark = theme.brightness == Brightness.dark;

    return BlocListener<MonthCubit, DateTime>(
      listener: (context, month) =>
          context.read<StatsBloc>().add(MonthChanged(month)),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Financial Analytics',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Breakdown of spending & cash flow',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.infoBlue.withValues(
                            alpha: isDark ? 0.28 : 0.16,
                          ),
                          AppTheme.infoBlue.withValues(
                            alpha: isDark ? 0.12 : 0.05,
                          ),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.infoBlue.withValues(
                          alpha: isDark ? 0.3 : 0.2,
                        ),
                      ),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: AppTheme.infoBlue,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              EntranceAnimation(
                child: BlocBuilder<MonthCubit, DateTime>(
                  builder: (context, month) => _MonthSelector(month: month),
                ),
              ),
              const SizedBox(height: 12),
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

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final monthCubit = context.read<MonthCubit>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Previous month',
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(38, 38),
            ),
            onPressed: monthCubit.canGoPrevious ? monthCubit.previous : null,
            icon: const Icon(Icons.chevron_left_rounded, size: 22),
          ),
          Expanded(
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Row(
                  key: ValueKey(month),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryEmerald.withValues(
                          alpha: isDark ? 0.22 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        size: 16,
                        color: AppTheme.primaryEmerald,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      DateFormat.yMMMM().format(month),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next month',
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(38, 38),
            ),
            onPressed: monthCubit.canGoNext ? monthCubit.next : null,
            icon: const Icon(Icons.chevron_right_rounded, size: 22),
          ),
        ],
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.monthStats, required this.bucketType});

  final MonthStats monthStats;
  final StatsBucketType bucketType;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        EntranceAnimation(child: _Summary(monthStats: monthStats)),
        const SizedBox(height: 12),
        EntranceAnimation(
          delay: const Duration(milliseconds: 60),
          child: _BudgetProgress(month: monthStats.month),
        ),
        const SizedBox(height: 20),
        EntranceAnimation(
          delay: const Duration(milliseconds: 100),
          child: const _SectionHeader(
            label: 'SPENDING BY CATEGORY',
            accent: AppTheme.primaryEmerald,
          ),
        ),
        const SizedBox(height: 10),
        if (monthStats.expenseMinor == 0)
          const EntranceAnimation(
            delay: Duration(milliseconds: 140),
            child: _EmptySection(
              icon: Icons.pie_chart_outline_rounded,
              message: 'No expenses recorded this month.',
            ),
          )
        else
          EntranceAnimation(
            delay: const Duration(milliseconds: 140),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                child: Column(
                  children: [
                    _DonutChart(monthStats: monthStats),
                    const SizedBox(height: 18),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _CategoryList(monthStats: monthStats),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 22),
        EntranceAnimation(
          delay: const Duration(milliseconds: 180),
          child: Row(
            children: [
              const Expanded(
                child: _SectionHeader(
                  label: 'SPENDING TREND',
                  accent: AppTheme.primaryEmerald,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 34,
                child: SegmentedButton<StatsBucketType>(
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: StatsBucketType.daily,
                      label: Text('Daily'),
                    ),
                    ButtonSegment(
                      value: StatsBucketType.weekly,
                      label: Text('Weekly'),
                    ),
                  ],
                  selected: {bucketType},
                  onSelectionChanged: (selection) => context
                      .read<StatsBloc>()
                      .add(BucketToggled(selection.first)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (monthStats.expenseMinor == 0)
          const EntranceAnimation(
            delay: Duration(milliseconds: 220),
            child: _EmptySection(
              icon: Icons.bar_chart_rounded,
              message: 'No spending trend to chart for this month.',
            ),
          )
        else
          EntranceAnimation(
            delay: const Duration(milliseconds: 220),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
                child: _SpendingBarChart(
                  buckets: bucketType == StatsBucketType.daily
                      ? monthStats.dailyBuckets
                      : monthStats.weeklyBuckets,
                  bucketType: bucketType,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.monthStats});

  final MonthStats monthStats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF0FDF9), Color(0xFFFFFFFF)],
              ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryMetric(
              label: 'Income',
              amount: monthStats.incomeMinor,
              color: AppTheme.incomeGreen,
              icon: Icons.arrow_downward_rounded,
            ),
          ),
          _SummaryDivider(isDark: isDark),
          Expanded(
            child: _SummaryMetric(
              label: 'Expenses',
              amount: monthStats.expenseMinor,
              color: AppTheme.expenseCoral,
              icon: Icons.arrow_upward_rounded,
            ),
          ),
          _SummaryDivider(isDark: isDark),
          Expanded(
            child: _SummaryMetric(
              label: 'Net Cash',
              amount: monthStats.netMinor,
              color: monthStats.netMinor < 0
                  ? AppTheme.expenseCoral
                  : AppTheme.incomeGreen,
              icon: monthStats.netMinor < 0
                  ? Icons.trending_down_rounded
                  : Icons.trending_up_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      width: 1,
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFE2E8F0),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final int amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.1,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatMinor(amount),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: -0.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetProgress extends StatelessWidget {
  const _BudgetProgress({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, state) => switch (state) {
        BudgetLoading() => const LinearProgressIndicator(),
        BudgetError(:final month) when _sameMonth(month, this.month) => Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Expanded(child: Text('Could not load the budget.')),
                IconButton(
                  tooltip: 'Retry budget',
                  onPressed: () => context.read<BudgetBloc>().add(
                    const BudgetRetryRequested(),
                  ),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
        ),
        BudgetError() => const LinearProgressIndicator(),
        BudgetLoaded(:final month) when !_sameMonth(month, this.month) =>
          const LinearProgressIndicator(),
        BudgetLoaded(:final status) => _buildStatus(context, status),
      },
    );
  }

  Widget _buildStatus(BuildContext context, BudgetStatus status) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (status.level == BudgetLevel.notSet) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: colors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'No monthly budget set',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/settings'),
                child: const Text('Set limit'),
              ),
            ],
          ),
        ),
      );
    }

    final statusColor = switch (status.level) {
      BudgetLevel.exceeded => AppTheme.expenseCoral,
      BudgetLevel.warning => AppTheme.warningAmber,
      _ => AppTheme.incomeGreen,
    };

    final percentage = (status.progress * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: isDark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    Icons.speed_rounded,
                    size: 15,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Budget Utilization',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: formatMinor(status.spentMinor),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: null,
                          ),
                        ),
                        TextSpan(
                          text: ' of ${formatMinor(status.limitMinor!)}',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                if (status.remainingMinor != null)
                  Text(
                    status.remainingMinor! >= 0
                        ? '${formatMinor(status.remainingMinor!)} left'
                        : '${formatMinor(status.remainingMinor!.abs())} over',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedGradientProgressBar(
              progress: status.progress,
              color: statusColor,
              height: 8,
              borderRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutChart extends StatelessWidget {
  const _DonutChart({required this.monthStats});

  final MonthStats monthStats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topCategories = monthStats.byCategory.take(5).toList();
    final otherAmount = monthStats.byCategory
        .skip(5)
        .fold<int>(0, (total, category) => total + category.amountMinor);

    final sections = [
      for (var index = 0; index < topCategories.length; index++)
        PieChartSectionData(
          value: topCategories[index].amountMinor.toDouble(),
          color: _categoryPalette[index % _categoryPalette.length],
          radius: 30,
          showTitle: false,
        ),
      if (otherAmount > 0)
        PieChartSectionData(
          value: otherAmount.toDouble(),
          color: const Color(0xFF94A3B8),
          radius: 30,
          showTitle: false,
        ),
    ];

    return SizedBox(
      height: 210,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 68,
              sectionsSpace: 4,
              startDegreeOffset: -90,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TOTAL SPENT',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.75,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatMinor(monthStats.expenseMinor),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.monthStats});

  final MonthStats monthStats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < monthStats.byCategory.length; index++)
          _CategoryRow(
            category: monthStats.byCategory[index],
            percentage:
                monthStats.byCategory[index].amountMinor /
                monthStats.expenseMinor *
                100,
            color: index < 5
                ? _categoryPalette[index % _categoryPalette.length]
                : const Color(0xFF94A3B8),
          ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.percentage,
    required this.color,
  });

  final CategorySpending category;
  final double percentage;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 5,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formatMinor(category.amountMinor),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedGradientProgressBar(
            progress: (percentage / 100).clamp(0.0, 1.0),
            color: color,
            height: 6,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }
}

class _SpendingBarChart extends StatelessWidget {
  const _SpendingBarChart({required this.buckets, required this.bucketType});

  final List<SpendingBucket> buckets;
  final StatsBucketType bucketType;

  @override
  Widget build(BuildContext context) {
    final maxAmount = buckets.fold<int>(
      0,
      (maximum, bucket) => math.max(maximum, bucket.amountMinor),
    );
    final maxY = maxAmount == 0 ? 1.0 : maxAmount * 1.15;
    final interval = bucketType == StatsBucketType.daily ? 4 : 1;
    final chartWidth = math.max(300.0, buckets.length * 36.0).toDouble();

    return SizedBox(
      height: 220,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: chartWidth,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 4 ? maxY / 4 : 1,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.15),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 ||
                          index >= buckets.length ||
                          index % interval != 0) {
                        return const SizedBox.shrink();
                      }
                      final date = buckets[index].start;
                      final label = bucketType == StatsBucketType.daily
                          ? date.day.toString()
                          : DateFormat.MMMd().format(date);
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var index = 0; index < buckets.length; index++)
                  BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: buckets[index].amountMinor.toDouble(),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFF0D9373), Color(0xFF2DD4BF)],
                        ),
                        width: bucketType == StatsBucketType.daily ? 12 : 24,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald.withValues(
                    alpha: isDark ? 0.12 : 0.08,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 46, color: AppTheme.primaryEmerald),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                    Icons.cloud_off_rounded,
                    size: 32,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

bool _sameMonth(DateTime first, DateTime second) =>
    first.year == second.year && first.month == second.month;
