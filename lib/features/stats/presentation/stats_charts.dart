// lib/features/stats/presentation/stats_charts.dart

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money_format.dart';
import '../../budget/presentation/budget_bloc.dart';
import '../domain/month_stats.dart';

// ---------------------------------------------------------------------------
// Shared
// ---------------------------------------------------------------------------

/// Days up to and including today (future days of the current month are
/// dropped so they don't flatten averages or cumulative lines).
List<SpendingBucket> _elapsed(List<SpendingBucket> all) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return all.where((b) => !b.start.isAfter(today)).toList();
}

const _weekdayShort = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const _weekdayFull = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

class ChartCard extends StatelessWidget {
  const ChartCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget child;

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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15.5,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Interactive donut
// ---------------------------------------------------------------------------

class CategorySlice {
  const CategorySlice({
    required this.name,
    required this.amount,
    required this.color,
  });

  final String name;
  final int amount;
  final Color color;
}

class CategoryDonutCard extends StatefulWidget {
  const CategoryDonutCard({
    super.key,
    required this.slices,
    required this.total,
  });

  final List<CategorySlice> slices;
  final int total;

  @override
  State<CategoryDonutCard> createState() => _CategoryDonutCardState();
}

class _CategoryDonutCardState extends State<CategoryDonutCard> {
  int _selected = -1;

  void _toggle(int i) => setState(() => _selected = i == _selected ? -1 : i);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final slices = widget.slices;
    final total = widget.total;
    final sel = _selected >= 0 && _selected < slices.length
        ? slices[_selected]
        : null;

    return ChartCard(
      icon: Icons.donut_large_rounded,
      color: AppTheme.primaryEmerald,
      title: 'Where it went',
      subtitle: 'Tap a slice to focus it',
      child: Column(
        children: [
          SizedBox(
            height: 214,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 3,
                    centerSpaceRadius: 68,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        if (event is! FlTapUpEvent) return;
                        final i =
                            response?.touchedSection?.touchedSectionIndex ?? -1;
                        if (i >= 0) {
                          _toggle(i);
                        } else {
                          setState(() => _selected = -1);
                        }
                      },
                    ),
                    sections: [
                      for (var i = 0; i < slices.length; i++)
                        PieChartSectionData(
                          value: slices[i].amount.toDouble(),
                          color: slices[i].color.withValues(
                            alpha: sel == null || i == _selected ? 1 : 0.3,
                          ),
                          radius: i == _selected ? 36 : 26,
                          showTitle: false,
                        ),
                    ],
                  ),
                ),
                IgnorePointer(
                  child: SizedBox(
                    width: 112,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        key: ValueKey(_selected),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            sel?.name.toUpperCase() ?? 'TOTAL SPENT',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: sel?.color ?? scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              formatMinor(sel?.amount ?? total),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          if (sel != null)
                            Text(
                              '${(sel.amount / total * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < slices.length; i++)
            _LegendRow(
              slice: slices[i],
              share: slices[i].amount / total,
              selected: i == _selected,
              dimmed: sel != null && i != _selected,
              onTap: () => _toggle(i),
            ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.slice,
    required this.share,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final CategorySlice slice;
  final double share;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: dimmed ? 0.45 : 1,
      child: Material(
        color: selected
            ? slice.color.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: slice.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    slice.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '${(share * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formatMinor(slice.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
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

// ---------------------------------------------------------------------------
// 2. Budget pace (cumulative spending vs budget line)
// ---------------------------------------------------------------------------

class SpendingPaceCard extends StatelessWidget {
  const SpendingPaceCard({super.key, required this.stats});

  final MonthStats stats;

  @override
  Widget build(BuildContext context) {
    final all = stats.dailyBuckets;
    final days = all.length;
    final elapsed = math.min(_elapsed(all).length, days);
    if (days == 0 || elapsed == 0) return const SizedBox.shrink();

    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, state) {
        final m = stats.month;
        final limit =
            state is BudgetLoaded &&
                state.month.year == m.year &&
                state.month.month == m.month
            ? state.status.limitMinor
            : null;
        return _build(context, all, days, elapsed, limit);
      },
    );
  }

  Widget _build(
    BuildContext context,
    List<SpendingBucket> all,
    int days,
    int elapsed,
    int? limit,
  ) {
    final scheme = Theme.of(context).colorScheme;

    var run = 0;
    final actual = <FlSpot>[];
    for (var i = 0; i < elapsed; i++) {
      run += all[i].amountMinor;
      actual.add(FlSpot(i.toDouble(), run.toDouble()));
    }
    final spent = run;
    final projected = (spent / elapsed * days).round();

    final pace = limit == null
        ? <FlSpot>[]
        : [
            for (var i = 0; i < days; i++)
              FlSpot(i.toDouble(), limit * (i + 1) / days),
          ];

    final paceNow = limit == null ? 0.0 : limit * elapsed / days;
    final diff = limit == null ? 0 : (spent - paceNow).round();
    final over = diff > 0;
    final lineColor = limit != null && spent > limit
        ? AppTheme.expenseCoral
        : AppTheme.primaryEmerald;

    var maxY = math.max(spent, limit ?? 0).toDouble() * 1.15;
    if (maxY <= 0) maxY = 1;

    return ChartCard(
      icon: Icons.show_chart_rounded,
      color: AppTheme.infoBlue,
      title: 'Budget pace',
      subtitle: limit == null
          ? 'Cumulative spending this month'
          : 'Your spending vs. an even budget',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(
                icon: Icons.auto_graph_rounded,
                text: 'Projected ${formatMinor(projected)}',
                color: AppTheme.infoBlue,
              ),
              if (limit != null)
                _Pill(
                  icon: over
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  text: over
                      ? '${formatMinor(diff)} over pace'
                      : '${formatMinor(-diff)} under pace',
                  color: over ? AppTheme.expenseCoral : AppTheme.incomeGreen,
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                minX: 0,
                maxX: math.max(1, days - 1).toDouble(),
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
                      reservedSize: 26,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (value != i.toDouble() ||
                            i < 0 ||
                            i >= days ||
                            !(i == 0 || (i + 1) % 5 == 0)) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            '${i + 1}',
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
                        if (spot.barIndex != 0)
                          null
                        else
                          LineTooltipItem(
                            'Day ${spot.x.toInt() + 1}\n'
                            '${formatMinor(spot.y.round())}',
                            TextStyle(
                              color: scheme.onInverseSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                    ],
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: actual,
                    isCurved: true,
                    preventCurveOverShooting: true,
                    curveSmoothness: 0.2,
                    barWidth: 3.5,
                    color: lineColor,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, _) => spot.x == actual.last.x,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          lineColor.withValues(alpha: 0.3),
                          lineColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                  if (limit != null)
                    LineChartBarData(
                      spots: pace,
                      barWidth: 2,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      dashArray: [6, 5],
                      dotData: const FlDotData(show: false),
                    ),
                ],
              ),
            ),
          ),
          if (limit != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _LegendDot(color: lineColor, label: 'Actual'),
                const SizedBox(width: 16),
                _LegendDot(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  label: 'Budget pace',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Weekday pattern
// ---------------------------------------------------------------------------

class WeekdayPatternCard extends StatelessWidget {
  const WeekdayPatternCard({super.key, required this.buckets});

  final List<SpendingBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final sums = List<int>.filled(7, 0);
    final counts = List<int>.filled(7, 0);
    for (final b in _elapsed(buckets)) {
      final d = b.start.weekday - 1;
      sums[d] += b.amountMinor;
      counts[d]++;
    }
    final avgs = [
      for (var i = 0; i < 7; i++) counts[i] == 0 ? 0.0 : sums[i] / counts[i],
    ];
    final maxV = avgs.reduce(math.max);
    if (maxV <= 0) return const SizedBox.shrink();
    final peak = avgs.indexOf(maxV);
    final maxY = maxV * 1.25;

    return ChartCard(
      icon: Icons.calendar_view_week_rounded,
      color: AppTheme.warningAmber,
      title: 'Weekday pattern',
      subtitle: 'You spend most on ${_weekdayFull[peak]}s',
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            alignment: BarChartAlignment.spaceBetween,
            gridData: const FlGridData(show: false),
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
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      _weekdayShort[value.toInt()],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: value.toInt() == peak
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: value.toInt() == peak
                            ? AppTheme.warningAmber
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => scheme.inverseSurface,
                getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                    BarTooltipItem(
                      '${_weekdayFull[groupIndex]}\n'
                      '${formatMinor(rod.toY.round())} avg',
                      TextStyle(
                        color: scheme.onInverseSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < 7; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: avgs[i],
                      width: 26,
                      color: i == peak
                          ? AppTheme.warningAmber
                          : AppTheme.warningAmber.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(9),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY,
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: 0.45,
                        ),
                      ),
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

// ---------------------------------------------------------------------------
// 4. Calendar heatmap
// ---------------------------------------------------------------------------

class SpendingCalendarCard extends StatefulWidget {
  const SpendingCalendarCard({super.key, required this.buckets});

  final List<SpendingBucket> buckets;

  @override
  State<SpendingCalendarCard> createState() => _SpendingCalendarCardState();
}

class _SpendingCalendarCardState extends State<SpendingCalendarCard> {
  int? _day;

  @override
  Widget build(BuildContext context) {
    final buckets = widget.buckets;
    if (buckets.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final first = buckets.first.start;
    final monthStart = DateTime(first.year, first.month, 1);
    final daysInMonth = DateTime(first.year, first.month + 1, 0).day;
    final byDay = <int, int>{
      for (final b in buckets) b.start.day: b.amountMinor,
    };
    final maxV = byDay.values.fold<int>(0, math.max);
    final lead = monthStart.weekday - 1;
    final now = DateTime.now();

    Widget cell(int day) {
      final amount = byDay[day] ?? 0;
      final ratio = maxV == 0 ? 0.0 : amount / maxV;
      final selected = _day == day;
      final isToday =
          now.year == first.year && now.month == first.month && now.day == day;

      return GestureDetector(
        onTap: () => setState(() => _day = selected ? null : day),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: amount == 0
                ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : AppTheme.expenseCoral.withValues(alpha: 0.18 + 0.82 * ratio),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? scheme.onSurface
                  : isToday
                  ? AppTheme.primaryEmerald
                  : Colors.transparent,
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: ratio > 0.55 ? Colors.white : scheme.onSurface,
            ),
          ),
        ),
      );
    }

    final selectedDay = _day;
    final info = selectedDay == null
        ? 'Tap a day to see what you spent'
        : '${DateFormat.MMMd().format(DateTime(first.year, first.month, selectedDay))}'
              ' · ${formatMinor(byDay[selectedDay] ?? 0)}';

    return ChartCard(
      icon: Icons.grid_view_rounded,
      color: AppTheme.expenseCoral,
      title: 'Spending calendar',
      subtitle: 'Darker days mean more spending',
      child: Column(
        children: [
          Row(
            children: [
              for (final d in _weekdayShort)
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (var i = 0; i < lead; i++) const SizedBox.shrink(),
              for (var d = 1; d <= daysInMonth; d++) cell(d),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    info,
                    key: ValueKey(selectedDay),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: selectedDay == null
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                    ),
                  ),
                ),
              ),
              Text(
                'Less',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 6),
              for (final a in const [0.18, 0.45, 0.72, 1.0])
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.expenseCoral.withValues(alpha: a),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              const SizedBox(width: 3),
              Text(
                'More',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
