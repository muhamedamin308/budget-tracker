import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/category_dao.dart';
import '../../../core/error/failures.dart';
import '../domain/category_entity.dart';
import '../domain/category_repository.dart';

@LazySingleton(as: CategoryRepository)
class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl(this._categoryDao);

  final CategoryDao _categoryDao;

  @override
  Stream<List<CategoryEntity>> watchCategories() => _categoryDao.watchAll().map(
    (categories) => categories.map(_toEntity).toList(),
  );

  @override
  Future<CategoryEntity?> getById(int id) async {
    final category = await _categoryDao.getById(id);
    return category == null ? null : _toEntity(category);
  }

  @override
  Future<CategoryEntity?> getLastUsedCategory(CategoryType type) async {
    final category = await _categoryDao.getLastUsedByType(
      _toDatabaseType(type),
    );
    return category == null ? null : _toEntity(category);
  }

  @override
  Future<Either<Failure, Unit>> addCategory({
    required String name,
    required CategoryType type,
  }) => _persist(
    () => _categoryDao.insert(
      CategoriesCompanion.insert(
        name: name,
        type: _toDatabaseType(type),
        iconKey: 'custom',
      ),
    ),
    'Could not add the category',
  );

  @override
  Future<Either<Failure, Unit>> renameCategory({
    required int id,
    required String name,
  }) => _persist(
    () => _categoryDao.rename(id, name),
    'Could not rename the category',
  );

  @override
  Future<Either<Failure, Unit>> archiveCategory(int id) => _persist(
    () => _categoryDao.setArchived(id, true),
    'Could not archive the category',
  );

  Future<Either<Failure, Unit>> _persist(
    Future<int> Function() operation,
    String failureMessage,
  ) async {
    try {
      final changedRows = await operation();
      if (changedRows == 0) {
        return Left(PersistenceFailure('$failureMessage: category not found.'));
      }
      return Right(unit);
    } on Exception catch (error) {
      return Left(PersistenceFailure('$failureMessage: $error'));
    }
  }

  CategoryEntity _toEntity(Category category) => CategoryEntity(
    id: category.id,
    name: category.name,
    type: CategoryType.values[category.type.index],
    iconKey: category.iconKey,
    isDefault: category.isDefault,
    isArchived: category.isArchived,
  );

  TransactionType _toDatabaseType(CategoryType type) => switch (type) {
    CategoryType.income => TransactionType.income,
    CategoryType.expense => TransactionType.expense,
  };
}
