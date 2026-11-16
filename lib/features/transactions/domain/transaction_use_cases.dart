import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failures.dart';
import '../../categories/domain/category_entity.dart';
import '../../categories/domain/category_repository.dart';
import 'transaction_entity.dart';
import 'transaction_repository.dart';

@injectable
class WatchBalance {
  const WatchBalance(this._repository);

  final TransactionRepository _repository;

  Stream<int> call() => _repository.watchBalance();
}

@injectable
class WatchMonthTransactions {
  const WatchMonthTransactions(this._repository);

  final TransactionRepository _repository;

  Stream<List<TransactionEntity>> call(DateTime month) =>
      _repository.watchMonthTransactions(month);
}

@injectable
class AddIncome {
  const AddIncome(this._repository, this._categoryRepository);

  final TransactionRepository _repository;
  final CategoryRepository _categoryRepository;

  Future<Either<Failure, Unit>> call({
    required int amountMinor,
    required int categoryId,
    int? walletId,
    required String title,
    DateTime? createdAt,
  }) async {
    final draft = TransactionDraft(
      kind: TransactionKind.income,
      amountMinor: amountMinor,
      categoryId: categoryId,
      title: title.trim(),
      createdAt: createdAt,
      walletId: walletId,
    );
    final failure = await _validateDraft(draft, _categoryRepository);
    if (failure != null) return Left(failure);
    return _repository.addTransaction(draft);
  }
}

@injectable
class AddExpense {
  const AddExpense(this._repository, this._categoryRepository);

  final TransactionRepository _repository;
  final CategoryRepository _categoryRepository;

  Future<Either<Failure, Unit>> call({
    required int amountMinor,
    required int categoryId,
    int? walletId,
    DateTime? createdAt,
  }) async {
    final draft = TransactionDraft(
      kind: TransactionKind.expense,
      amountMinor: amountMinor,
      categoryId: categoryId,
      createdAt: createdAt,
      walletId: walletId,
    );
    final failure = await _validateDraft(draft, _categoryRepository);
    if (failure != null) return Left(failure);
    return _repository.addTransaction(draft);
  }
}

@injectable
class UpdateTransaction {
  const UpdateTransaction(this._repository, this._categoryRepository);

  final TransactionRepository _repository;
  final CategoryRepository _categoryRepository;

  Future<Either<Failure, Unit>> call({
    required int id,
    required int originalCategoryId,
    required TransactionDraft draft,
  }) async {
    if (id <= 0) {
      return const Left(ValidationFailure('Select a valid transaction.'));
    }
    final failure = await _validateDraft(
      draft,
      _categoryRepository,
      allowArchivedCategoryId: originalCategoryId,
    );
    if (failure != null) return Left(failure);
    return _repository.updateTransaction(id, draft);
  }
}

@injectable
class DeleteTransaction {
  const DeleteTransaction(this._repository);

  final TransactionRepository _repository;

  Future<Either<Failure, TransactionEntity>> call(int id) {
    if (id <= 0) {
      return Future.value(
        const Left(ValidationFailure('Select a valid transaction.')),
      );
    }
    return _repository.deleteTransaction(id);
  }
}

@injectable
class RestoreTransaction {
  const RestoreTransaction(this._repository);

  final TransactionRepository _repository;

  Future<Either<Failure, Unit>> call(TransactionEntity transaction) =>
      _repository.restoreTransaction(transaction);
}

Future<Failure?> _validateDraft(
  TransactionDraft draft,
  CategoryRepository categoryRepository, {
  int? allowArchivedCategoryId,
}) async {
  if (draft.amountMinor <= 0) {
    return const ValidationFailure('Amount must be greater than zero.');
  }
  if (draft.kind == TransactionKind.income &&
      (draft.title == null || draft.title!.trim().isEmpty)) {
    return const ValidationFailure('Income title is required.');
  }
  try {
    final category = await categoryRepository.getById(draft.categoryId);
    if (category == null ||
        !_matchesType(category.type, draft.kind) ||
        (category.isArchived && category.id != allowArchivedCategoryId)) {
      return const ValidationFailure(
        'Choose an active category for this transaction.',
      );
    }
  } on Exception catch (error) {
    return PersistenceFailure('Could not validate the category: $error');
  }
  return null;
}

bool _matchesType(CategoryType categoryType, TransactionKind transactionKind) =>
    switch (transactionKind) {
      TransactionKind.income => categoryType == CategoryType.income,
      TransactionKind.expense => categoryType == CategoryType.expense,
    };
