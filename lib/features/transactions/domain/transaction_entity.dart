import 'package:equatable/equatable.dart';

enum TransactionKind { income, expense }

class TransactionEntity extends Equatable {
  const TransactionEntity({
    required this.id,
    required this.kind,
    required this.amountMinor,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIconKey,
    required this.title,
    required this.createdAt,
    required this.recurringRuleId,
    required this.recurringDueDate,
  });

  final int id;
  final TransactionKind kind;
  final int amountMinor;
  final int categoryId;
  final String categoryName;
  final String categoryIconKey;
  final String? title;
  final DateTime createdAt;
  final int? recurringRuleId;
  final DateTime? recurringDueDate;

  @override
  List<Object?> get props => [
    id,
    kind,
    amountMinor,
    categoryId,
    categoryName,
    categoryIconKey,
    title,
    createdAt,
    recurringRuleId,
    recurringDueDate,
  ];
}

class TransactionDraft {
  const TransactionDraft({
    required this.kind,
    required this.amountMinor,
    required this.categoryId,
    this.title,
    this.createdAt,
  });

  final TransactionKind kind;
  final int amountMinor;
  final int categoryId;
  final String? title;
  final DateTime? createdAt;
}
