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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Financial Analytics',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Breakdown of spending & cash flow',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.infoBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.insights_rounded,
                      color: AppTheme.infoBlue,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
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
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryEmerald.withValues(
                          alpha: isDark ? 0.2 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        size: 15,
                        color: AppTheme.primaryEmerald,
                      ),
                    ),
                    const SizedBox(width: 8),
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
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        EntranceAnimation(
          child: _Summary(monthStats: monthStats),
        ),
        const SizedBox(height: 12),
        EntranceAnimation(
          delay: const Duration(milliseconds: 60),
          child: _BudgetProgress(month: monthStats.month),
        ),
        const SizedBox(height: 18),
        EntranceAnimation(
          delay: const Duration(milliseconds: 100),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppTheme.primaryEmerald,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Spending by Category',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
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
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _DonutChart(monthStats: monthStats),
                    const SizedBox(height: 18),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryEmerald,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Spending Trend',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 36,
                child: SegmentedButton<StatsBucketType>(
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: StatsBucketType.daily,
                      label: Text('Daily', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                    ButtonSegment(
                      value: StatsBucketType.weekly,
                      label: Text('Weekly', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                  selected: {bucketType},
                  onSelectionChanged: (selection) =>
                      context.read<StatsBloc>().add(BucketToggled(selection.first)),
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
                padding: const EdgeInsets.all(18),
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

class _Summary extends StatelessWidget {
  const _Summary({required this.monthStats});

  final MonthStats monthStats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
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
          Container(
            height: 42,
            width: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE2E8F0),
          ),
          Expanded(
            child: _SummaryMetric(
              label: 'Expenses',
              amount: monthStats.expenseMinor,
              color: AppTheme.expenseCoral,
              icon: Icons.arrow_upward_rounded,
            ),
          ),
          Container(
            height: 42,
            width: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE2E8F0),
          ),
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
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatMinor(amount),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 15.5,
              letterSpacing: -0.3,
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
                  onPressed: () =>
                      context.read<BudgetBloc>().add(const BudgetRetryRequested()),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
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
                  style: TextStyle(fontWeight: FontWeight.w600),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.speed_rounded,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Budget Utilization',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: [
                      TextSpan(
                        text: formatMinor(status.spentMinor),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: ' of ${formatMinor(status.limitMinor!)}',
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
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
                      fontWeight: FontWeight.w600,
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
    final topCategories = monthStats.byCategory.take(5).toList();
    final otherAmount = monthStats.byCategory
        .skip(5)
        .fold<int>(0, (total, category) => total + category.amountMinor);

    final sections = [
      for (var index = 0; index < topCategories.length; index++)
        PieChartSectionData(
          value: topCategories[index].amountMinor.toDouble(),
          color: _categoryPalette[index % _categoryPalette.length],
          radius: 28,
          showTitle: false,
        ),
      if (otherAmount > 0)
        PieChartSectionData(
          value: otherAmount.toDouble(),
          color: const Color(0xFF94A3B8),
          radius: 28,
          showTitle: false,
        ),
    ];

    return SizedBox(
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 65,
              sectionsSpace: 4,
              startDegreeOffset: -90,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Spent',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatMinor(monthStats.expenseMinor),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatMinor(category.amountMinor),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
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
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
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
                          colors: [
                            Color(0xFF0D9373),
                            Color(0xFF2DD4BF),
                          ],
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
                  color: AppTheme.primaryEmerald.withValues(alpha: isDark ? 0.12 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: AppTheme.primaryEmerald),
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
              color: isDark
                  ? const Color(0xFF1E293B)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
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
                  icon: const Icon(Icons.refresh_rounded),
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
