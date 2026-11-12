import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import 'category_entity.dart';

abstract interface class CategoryRepository {
  Stream<List<CategoryEntity>> watchCategories();

  Future<CategoryEntity?> getById(int id);

  Future<CategoryEntity?> getLastUsedCategory(CategoryType type);

  Future<Either<Failure, Unit>> addCategory({
    required String name,
    required CategoryType type,
    required String iconKey,
  });

  Future<Either<Failure, Unit>> renameCategory({
    required int id,
    required String name,
    required String iconKey,
  });

  Future<Either<Failure, Unit>> archiveCategory(int id);
}
