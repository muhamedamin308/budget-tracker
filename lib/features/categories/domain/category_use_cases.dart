import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/failures.dart';
import 'category_entity.dart';
import 'category_repository.dart';

@injectable
class WatchCategories {
  const WatchCategories(this._repository);

  final CategoryRepository _repository;

  Stream<List<CategoryEntity>> call() => _repository.watchCategories();
}

@injectable
class AddCategory {
  const AddCategory(this._repository);

  final CategoryRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String name,
    required CategoryType type,
  }) {
    final validation = _validateName(name);
    if (validation != null) return Future.value(Left(validation));
    return _repository.addCategory(name: name.trim(), type: type);
  }
}

@injectable
class RenameCategory {
  const RenameCategory(this._repository);

  final CategoryRepository _repository;

  Future<Either<Failure, Unit>> call({required int id, required String name}) {
    if (id <= 0) {
      return Future.value(
        const Left(ValidationFailure('Select a valid category.')),
      );
    }
    final validation = _validateName(name);
    if (validation != null) return Future.value(Left(validation));
    return _repository.renameCategory(id: id, name: name.trim());
  }
}

@injectable
class ArchiveCategory {
  const ArchiveCategory(this._repository);

  final CategoryRepository _repository;

  Future<Either<Failure, Unit>> call(int id) {
    if (id <= 0) {
      return Future.value(
        const Left(ValidationFailure('Select a valid category.')),
      );
    }
    return _repository.archiveCategory(id);
  }
}

Failure? _validateName(String name) {
  final trimmedName = name.trim();
  if (trimmedName.isEmpty) {
    return const ValidationFailure('Enter a category name.');
  }
  if (trimmedName.length > 40) {
    return const ValidationFailure(
      'Category names must be 40 characters or fewer.',
    );
  }
  return null;
}
