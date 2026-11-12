import 'package:bloc_test/bloc_test.dart';
import 'package:budget_tracker/features/stats/domain/month_stats.dart';
import 'package:budget_tracker/features/stats/domain/watch_month_stats.dart';
import 'package:budget_tracker/features/stats/presentation/stats_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchMonthStats extends Mock implements WatchMonthStats {}

void main() {
  final month = DateTime(2026, 11);
  final monthStats = MonthStats.calculate(month: month, transactions: const []);
  late MockWatchMonthStats watchMonthStats;

  setUp(() {
    watchMonthStats = MockWatchMonthStats();
    when(
      () => watchMonthStats(month),
    ).thenAnswer((_) => Stream.value(monthStats));
  });

  blocTest<StatsBloc, StatsState>(
    'watches the selected month and changes the chart bucket',
    build: () => StatsBloc(watchMonthStats),
    act: (bloc) async {
      bloc.add(MonthChanged(month));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const BucketToggled(StatsBucketType.weekly));
    },
    expect: () => [
      StatsLoading(month, StatsBucketType.daily),
      StatsLoaded(monthStats, StatsBucketType.daily),
      StatsLoaded(monthStats, StatsBucketType.weekly),
    ],
  );
}
