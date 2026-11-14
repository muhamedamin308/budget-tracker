import 'package:equatable/equatable.dart';

import '../../transactions/domain/transaction_entity.dart';

class RecurringRuleEntity extends Equatable {
  const RecurringRuleEntity({
    required this.id,
    required this.kind,
    required this.amountMinor,
    required this.categoryId,
    required this.categoryName,
    required this.title,
    required this.dayOfMonth,
    required this.startDate,
    required this.endDate,
    required this.lastGeneratedDue,
    required this.isActive,
    required this.walletId,
  });

  final int id;
  final TransactionKind kind;
  final int amountMinor;
  final int categoryId;
  final String categoryName;
  final String? title;
  final int dayOfMonth;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? lastGeneratedDue;
  final bool isActive;
  final int walletId;

  @override
  List<Object?> get props => [
    id,
    kind,
    amountMinor,
    categoryId,
    categoryName,
    title,
    dayOfMonth,
    startDate,
    endDate,
    lastGeneratedDue,
    isActive,
    walletId,
  ];
}

class RecurringRuleDraft {
  const RecurringRuleDraft({
    this.id,
    required this.kind,
    required this.amountMinor,
    required this.categoryId,
    required this.dayOfMonth,
    required this.startDate,
    this.endDate,
    this.title,
    this.walletId,
  });

  final int? id;
  final TransactionKind kind;
  final int amountMinor;
  final int categoryId;
  final int dayOfMonth;
  final DateTime startDate;
  final DateTime? endDate;
  final String? title;
  final int? walletId;
}
