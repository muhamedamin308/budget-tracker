import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../domain/month_stats.dart';
import '../domain/watch_month_stats.dart';

@injectable
class StatsBloc extends Bloc<StatsEvent, StatsState> {
  StatsBloc(this._watchMonthStats)
    : super(StatsLoading(DateTime(2000), StatsBucketType.daily)) {
    on<MonthChanged>(_onMonthChanged);
    on<StatsRetryRequested>((event, emit) {
      final month = _month;
      if (month != null) return _watch(month, emit);
    });
    on<BucketToggled>((event, emit) {
      _bucketType = event.bucketType;
      final current = state;
      if (current is StatsLoaded) {
        emit(current.copyWith(bucketType: event.bucketType));
      }
    });
    on<_MonthStatsReceived>((event, emit) {
      if (_sameMonth(event.month, _month)) {
        emit(StatsLoaded(event.monthStats, _bucketType));
      }
    });
    on<_MonthStatsFailed>((event, emit) {
      if (_sameMonth(event.month, _month)) {
        emit(StatsError(event.month, event.message));
      }
    });
  }

  final WatchMonthStats _watchMonthStats;
  StreamSubscription<MonthStats>? _subscription;
  DateTime? _month;
  StatsBucketType _bucketType = StatsBucketType.daily;

  Future<void> _onMonthChanged(MonthChanged event, Emitter<StatsState> emit) =>
      _watch(event.month, emit);

  Future<void> _watch(DateTime month, Emitter<StatsState> emit) async {
    final watchMonth = DateTime(month.year, month.month);
    final previousSubscription = _subscription;
    _subscription = null;
    _month = watchMonth;
    emit(StatsLoading(watchMonth, _bucketType));
    await previousSubscription?.cancel();
    if (emit.isDone || !_sameMonth(watchMonth, _month)) return;
    _subscription = _watchMonthStats(watchMonth).listen(
      (monthStats) {
        if (!isClosed) add(_MonthStatsReceived(watchMonth, monthStats));
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!isClosed) add(_MonthStatsFailed(watchMonth, error.toString()));
      },
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}

bool _sameMonth(DateTime first, DateTime? second) =>
    second != null && first.year == second.year && first.month == second.month;

sealed class StatsEvent extends Equatable {
  const StatsEvent();
}

final class MonthChanged extends StatsEvent {
  const MonthChanged(this.month);

  final DateTime month;

  @override
  List<Object?> get props => [month];
}

final class BucketToggled extends StatsEvent {
  const BucketToggled(this.bucketType);

  final StatsBucketType bucketType;

  @override
  List<Object?> get props => [bucketType];
}

final class StatsRetryRequested extends StatsEvent {
  const StatsRetryRequested();

  @override
  List<Object?> get props => [];
}

final class _MonthStatsReceived extends StatsEvent {
  const _MonthStatsReceived(this.month, this.monthStats);

  final DateTime month;
  final MonthStats monthStats;

  @override
  List<Object?> get props => [month, monthStats];
}

final class _MonthStatsFailed extends StatsEvent {
  const _MonthStatsFailed(this.month, this.message);

  final DateTime month;
  final String message;

  @override
  List<Object?> get props => [month, message];
}

sealed class StatsState extends Equatable {
  const StatsState();
}

final class StatsLoading extends StatsState {
  const StatsLoading(this.month, this.bucketType);

  final DateTime month;
  final StatsBucketType bucketType;

  @override
  List<Object?> get props => [month, bucketType];
}

final class StatsLoaded extends StatsState {
  const StatsLoaded(this.monthStats, this.bucketType);

  final MonthStats monthStats;
  final StatsBucketType bucketType;

  StatsLoaded copyWith({StatsBucketType? bucketType}) =>
      StatsLoaded(monthStats, bucketType ?? this.bucketType);

  @override
  List<Object?> get props => [monthStats, bucketType];
}

final class StatsError extends StatsState {
  const StatsError(this.month, this.message);

  final DateTime month;
  final String message;

  @override
  List<Object?> get props => [month, message];
}
