import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../app_database.dart';

@lazySingleton
class CategoryDao extends DatabaseAccessor<AppDatabase> {
  CategoryDao(super.db);

  Stream<List<Category>> watchByType(
    TransactionType type, {
    bool includeArchived = false,
  }) => _watch(type: type, includeArchived: includeArchived);

  Stream<List<Category>> watchAll({bool includeArchived = false}) =>
      _watch(includeArchived: includeArchived);

  Future<Category?> getById(int id) => (select(
    db.categories,
  )..where((category) => category.id.equals(id))).getSingleOrNull();

  Future<Category?> getLastUsedByType(TransactionType type) async {
    final query =
        select(db.categories).join([
            innerJoin(
              db.transactions,
              db.transactions.categoryId.equalsExp(db.categories.id),
            ),
          ])
          ..where(
            db.categories.type.equals(type.index) &
                db.categories.isArchived.equals(false),
          )
          ..orderBy([
            OrderingTerm.desc(db.transactions.createdAt),
            OrderingTerm.desc(db.transactions.id),
          ])
          ..limit(1);
    final result = await query.getSingleOrNull();
    return result?.readTable(db.categories);
  }

  Stream<List<Category>> _watch({
    TransactionType? type,
    required bool includeArchived,
  }) {
    final usageCount = db.transactions.id.count();
    final query =
        select(db.categories).join([
            leftOuterJoin(
              db.transactions,
              db.transactions.categoryId.equalsExp(db.categories.id),
            ),
          ])
          ..addColumns([usageCount])
          ..groupBy([db.categories.id])
          ..orderBy([
            OrderingTerm.desc(usageCount),
            OrderingTerm.asc(db.categories.name),
          ]);
    if (type != null) {
      query.where(db.categories.type.equals(type.index));
    }
    if (!includeArchived) {
      query.where(db.categories.isArchived.equals(false));
    }
    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(db.categories)).toList(),
    );
  }

  Future<int> insert(CategoriesCompanion category) =>
      into(db.categories).insert(category);

  Future<int> rename(int id, String name) =>
      (update(db.categories)..where((category) => category.id.equals(id)))
          .write(CategoriesCompanion(name: Value(name)));

  Future<int> setArchived(int id, bool isArchived) =>
      (update(db.categories)..where((category) => category.id.equals(id)))
          .write(CategoriesCompanion(isArchived: Value(isArchived)));
}
