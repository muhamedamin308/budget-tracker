// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

part 'app_database.g.dart';

enum TransactionType { income, expense }

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 40)();
  IntColumn get type => intEnum<TransactionType>()();
  TextColumn get iconKey => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {name, type},
  ];
}

class RecurringRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get type => intEnum<TransactionType>()();
  IntColumn get amountMinor =>
      integer().check(amountMinor.isBiggerThanValue(0))();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get title => text().nullable()();
  IntColumn get dayOfMonth =>
      integer().check(dayOfMonth.isBetweenValues(1, 31))();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get lastGeneratedDue => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

@DataClassName('TransactionRow')
@TableIndex(name: 'tx_created_at', columns: {#createdAt})
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get type => intEnum<TransactionType>()();
  IntColumn get amountMinor =>
      integer().check(amountMinor.isBiggerThanValue(0))();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get title => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get recurringRuleId => integer().nullable().references(
    RecurringRules,
    #id,
    onDelete: KeyAction.setNull,
  )();
  DateTimeColumn get recurringDueDate => dateTime().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {recurringRuleId, recurringDueDate},
  ];
}

class MonthlyLimits extends Table {
  TextColumn get yearMonth => text().withLength(min: 7, max: 7)();
  IntColumn get limitMinor =>
      integer().check(limitMinor.isBiggerThanValue(0))();

  @override
  Set<Column<Object>> get primaryKey => {yearMonth};
}

@DriftDatabase(
  tables: [Categories, RecurringRules, Transactions, MonthlyLimits],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedDefaultCategories();
    },
    beforeOpen: (_) async => customStatement('PRAGMA foreign_keys = ON'),
  );

  Future<void> _seedDefaultCategories() async {
    const categoriesToSeed = [
      (name: 'Salary', type: TransactionType.income, iconKey: 'salary'),
      (name: 'Bonus', type: TransactionType.income, iconKey: 'bonus'),
      (name: 'Freelance', type: TransactionType.income, iconKey: 'freelance'),
      (name: 'Gift', type: TransactionType.income, iconKey: 'gift'),
      (name: 'Refund', type: TransactionType.income, iconKey: 'refund'),
      (name: 'Other', type: TransactionType.income, iconKey: 'other'),
      (name: 'Transport', type: TransactionType.expense, iconKey: 'transport'),
      (
        name: 'Food & Drinks',
        type: TransactionType.expense,
        iconKey: 'food_drinks',
      ),
      (name: 'Groceries', type: TransactionType.expense, iconKey: 'groceries'),
      (
        name: 'Bills & Utilities',
        type: TransactionType.expense,
        iconKey: 'bills_utilities',
      ),
      (name: 'Rent', type: TransactionType.expense, iconKey: 'rent'),
      (name: 'Health', type: TransactionType.expense, iconKey: 'health'),
      (name: 'Shopping', type: TransactionType.expense, iconKey: 'shopping'),
      (
        name: 'Entertainment',
        type: TransactionType.expense,
        iconKey: 'entertainment',
      ),
      (name: 'Education', type: TransactionType.expense, iconKey: 'education'),
      (
        name: 'Subscriptions',
        type: TransactionType.expense,
        iconKey: 'subscriptions',
      ),
      (name: 'Other', type: TransactionType.expense, iconKey: 'other'),
    ];

    await batch((batch) {
      batch.insertAll(
        categories,
        categoriesToSeed
            .map(
              (category) => CategoriesCompanion.insert(
                name: category.name,
                type: category.type,
                iconKey: category.iconKey,
                isDefault: const Value(true),
              ),
            )
            .toList(),
      );
    });
  }
}
