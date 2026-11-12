import 'package:equatable/equatable.dart';

enum BudgetLevel { notSet, ok, warning, exceeded }

class BudgetStatus extends Equatable {
  const BudgetStatus({
    required this.spentMinor,
    required this.limitMinor,
    required this.level,
  });

  factory BudgetStatus.calculate({
    required int spentMinor,
    required int? limitMinor,
  }) {
    final level = switch (limitMinor) {
      null => BudgetLevel.notSet,
      final limit when spentMinor >= limit => BudgetLevel.exceeded,
      final limit when spentMinor / limit >= 0.8 => BudgetLevel.warning,
      _ => BudgetLevel.ok,
    };
    return BudgetStatus(
      spentMinor: spentMinor,
      limitMinor: limitMinor,
      level: level,
    );
  }

  final int spentMinor;
  final int? limitMinor;
  final BudgetLevel level;

  double get progress {
    final limit = limitMinor;
    if (limit == null || limit <= 0) return 0;
    return (spentMinor / limit).clamp(0, 1).toDouble();
  }

  int? get remainingMinor {
    final limit = limitMinor;
    if (limit == null) return null;
    return limit - spentMinor;
  }

  @override
  List<Object?> get props => [spentMinor, limitMinor, level];
}
