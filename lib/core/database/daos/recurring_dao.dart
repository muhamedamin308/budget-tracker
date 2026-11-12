import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../app_database.dart';
import '../../utils/recurrence.dart';

@lazySingleton
class RecurringDao extends DatabaseAccessor<AppDatabase> {
  RecurringDao(super.db);

  Stream<List<RecurringRule>> watchRules({bool activeOnly = false}) {
    final query = select(db.recurringRules);
    if (activeOnly) {
      query.where((rule) => rule.isActive.equals(true));
    }
    query.orderBy([(rule) => OrderingTerm.asc(rule.id)]);
    return query.watch();
  }

  Stream<List<({RecurringRule rule, Category category})>>
  watchRulesWithCategory() {
    final query = select(db.recurringRules).join([
      innerJoin(
        db.categories,
        db.categories.id.equalsExp(db.recurringRules.categoryId),
      ),
    ])..orderBy([OrderingTerm.asc(db.recurringRules.id)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => (
              rule: row.readTable(db.recurringRules),
              category: row.readTable(db.categories),
            ),
          )
          .toList(),
    );
  }

  Future<int> insert(RecurringRulesCompanion rule) =>
      into(db.recurringRules).insert(rule);

  Future<int> updateById(int id, RecurringRulesCompanion rule) => (update(
    db.recurringRules,
  )..where((row) => row.id.equals(id))).write(rule);

  Future<int> deleteById(int id) =>
      (delete(db.recurringRules)..where((rule) => rule.id.equals(id))).go();

  Future<int> setActive(int id, bool isActive) =>
      (update(db.recurringRules)..where((rule) => rule.id.equals(id))).write(
        RecurringRulesCompanion(isActive: Value(isActive)),
      );

  Future<void> generateDueRecurring(DateTime until) => db.transaction(() async {
    final rules = await (select(
      db.recurringRules,
    )..where((rule) => rule.isActive.equals(true))).get();
    for (final rule in rules) {
      final dates = dueDates(
        dayOfMonth: rule.dayOfMonth,
        startDate: rule.startDate,
        after: rule.lastGeneratedDue,
        endDate: rule.endDate,
        until: until,
      ).toList();
      for (final dueDate in dates) {
        await into(db.transactions).insert(
          TransactionsCompanion.insert(
            type: rule.type,
            amountMinor: rule.amountMinor,
            categoryId: rule.categoryId,
            title: Value(rule.title),
            createdAt: dueDate,
            recurringRuleId: Value(rule.id),
            recurringDueDate: Value(dueDate),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
      if (dates.isNotEmpty) {
        await (update(
          db.recurringRules,
        )..where((candidate) => candidate.id.equals(rule.id))).write(
          RecurringRulesCompanion(lastGeneratedDue: Value(dates.last)),
        );
      }
    }
  });
}
