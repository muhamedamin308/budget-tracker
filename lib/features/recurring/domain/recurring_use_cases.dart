import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failures.dart';
import '../../categories/domain/category_entity.dart';
import '../../categories/domain/category_repository.dart';
import '../../transactions/domain/transaction_entity.dart';
import 'recurring_repository.dart';
import 'recurring_rule_entity.dart';

@injectable
class WatchRules {
  const WatchRules(this._repository);

  final RecurringRepository _repository;

  Stream<List<RecurringRuleEntity>> call() => _repository.watchRules();
}

@injectable
class SaveRule {
  const SaveRule(this._repository, this._categoryRepository);

  final RecurringRepository _repository;
  final CategoryRepository _categoryRepository;

  Future<Either<Failure, Unit>> call(RecurringRuleDraft draft) async {
    if (draft.id != null && draft.id! <= 0) {
      return const Left(ValidationFailure('Select a valid recurring rule.'));
    }
    if (draft.amountMinor <= 0) {
      return const Left(ValidationFailure('Amount must be greater than zero.'));
    }
    if (draft.dayOfMonth < 1 || draft.dayOfMonth > 31) {
      return const Left(ValidationFailure('Due day must be between 1 and 31.'));
    }
    if (draft.kind == TransactionKind.income &&
        (draft.title == null || draft.title!.trim().isEmpty)) {
      return const Left(ValidationFailure('Income title is required.'));
    }
    final startDay = DateTime(
      draft.startDate.year,
      draft.startDate.month,
      draft.startDate.day,
    );
    final endDate = draft.endDate;
    if (endDate != null &&
        DateTime(endDate.year, endDate.month, endDate.day).isBefore(startDay)) {
      return const Left(
        ValidationFailure('End date must be on or after start.'),
      );
    }
    try {
      final category = await _categoryRepository.getById(draft.categoryId);
      if (category == null ||
          category.isArchived ||
          !_matchesType(category.type, draft.kind)) {
        return const Left(
          ValidationFailure('Choose an active category of the same type.'),
        );
      }
    } on Exception catch (error) {
      return Left(
        PersistenceFailure('Could not validate the category: $error'),
      );
    }
    return _repository.saveRule(
      RecurringRuleDraft(
        id: draft.id,
        kind: draft.kind,
        amountMinor: draft.amountMinor,
        categoryId: draft.categoryId,
        dayOfMonth: draft.dayOfMonth,
        startDate: startDay,
        endDate: endDate == null
            ? null
            : DateTime(endDate.year, endDate.month, endDate.day),
        title: draft.title?.trim(),
      ),
    );
  }

  bool _matchesType(CategoryType categoryType, TransactionKind kind) =>
      switch (kind) {
        TransactionKind.income => categoryType == CategoryType.income,
        TransactionKind.expense => categoryType == CategoryType.expense,
      };
}

@injectable
class SetRuleActive {
  const SetRuleActive(this._repository);

  final RecurringRepository _repository;

  Future<Either<Failure, Unit>> call(int id, bool isActive) {
    if (id <= 0) {
      return Future.value(
        const Left(ValidationFailure('Select a valid recurring rule.')),
      );
    }
    return _repository.setRuleActive(id, isActive);
  }
}

@injectable
class DeleteRule {
  const DeleteRule(this._repository);

  final RecurringRepository _repository;

  Future<Either<Failure, Unit>> call(int id) {
    if (id <= 0) {
      return Future.value(
        const Left(ValidationFailure('Select a valid recurring rule.')),
      );
    }
    return _repository.deleteRule(id);
  }
}

@injectable
class GenerateDueRecurring {
  const GenerateDueRecurring(this._repository);

  final RecurringRepository _repository;

  Future<Either<Failure, Unit>> call({DateTime? now}) {
    final current = now ?? DateTime.now();
    final endOfToday = DateTime(
      current.year,
      current.month,
      current.day,
      23,
      59,
      59,
      999,
      999,
    );
    return _repository.generateDueRecurring(endOfToday);
  }
}
