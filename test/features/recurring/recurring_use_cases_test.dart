import 'package:budget_tracker/features/categories/domain/category_entity.dart';
import 'package:budget_tracker/features/categories/domain/category_repository.dart';
import 'package:budget_tracker/features/recurring/domain/recurring_repository.dart';
import 'package:budget_tracker/features/recurring/domain/recurring_rule_entity.dart';
import 'package:budget_tracker/features/recurring/domain/recurring_use_cases.dart';
import 'package:budget_tracker/features/transactions/domain/transaction_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRecurringRepository extends Mock implements RecurringRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class FakeRecurringRuleDraft extends Fake implements RecurringRuleDraft {}

void main() {
  late MockRecurringRepository recurringRepository;
  late MockCategoryRepository categoryRepository;

  setUp(() {
    registerFallbackValue(FakeRecurringRuleDraft());
    recurringRepository = MockRecurringRepository();
    categoryRepository = MockCategoryRepository();
  });

  test('validates recurring rules and normalizes dates and title', () async {
    when(
      () => categoryRepository.getById(3),
    ).thenAnswer((_) async => _category(CategoryType.income));
    when(
      () => recurringRepository.saveRule(any()),
    ).thenAnswer((_) async => Right(unit));

    final result = await SaveRule(recurringRepository, categoryRepository)(
      RecurringRuleDraft(
        kind: TransactionKind.income,
        amountMinor: 12500,
        categoryId: 3,
        dayOfMonth: 31,
        startDate: DateTime(2026, 11, 12, 16),
        title: '  Salary  ',
      ),
    );

    expect(result.isRight(), isTrue);
    final savedDraft =
        verify(() => recurringRepository.saveRule(captureAny())).captured.single
            as RecurringRuleDraft;
    expect(savedDraft.title, 'Salary');
    expect(savedDraft.startDate, DateTime(2026, 11, 12));
  });

  test(
    'rejects invalid amount and mismatched or archived categories',
    () async {
      final saveRule = SaveRule(recurringRepository, categoryRepository);
      final invalidAmount = await saveRule(
        RecurringRuleDraft(
          kind: TransactionKind.expense,
          amountMinor: 0,
          categoryId: 3,
          dayOfMonth: 1,
          startDate: DateTime(2026, 11),
        ),
      );
      expect(invalidAmount.isLeft(), isTrue);
      verifyNever(() => categoryRepository.getById(any()));

      when(
        () => categoryRepository.getById(3),
      ).thenAnswer((_) async => _category(CategoryType.income));
      final wrongType = await saveRule(
        RecurringRuleDraft(
          kind: TransactionKind.expense,
          amountMinor: 100,
          categoryId: 3,
          dayOfMonth: 1,
          startDate: DateTime(2026, 11),
        ),
      );
      expect(wrongType.isLeft(), isTrue);
      verifyNever(() => recurringRepository.saveRule(any()));

      when(() => categoryRepository.getById(3)).thenAnswer(
        (_) async => _category(CategoryType.expense, archived: true),
      );
      final archived = await saveRule(
        RecurringRuleDraft(
          kind: TransactionKind.expense,
          amountMinor: 100,
          categoryId: 3,
          dayOfMonth: 1,
          startDate: DateTime(2026, 11),
        ),
      );
      expect(archived.isLeft(), isTrue);
      verifyNever(() => recurringRepository.saveRule(any()));
    },
  );

  test('generation stops at the end of the supplied local day', () async {
    when(
      () => recurringRepository.generateDueRecurring(any()),
    ).thenAnswer((_) async => Right(unit));
    final now = DateTime(2026, 11, 12, 11, 47);

    final result = await GenerateDueRecurring(recurringRepository)(now: now);

    expect(result.isRight(), isTrue);
    verify(
      () => recurringRepository.generateDueRecurring(
        DateTime(2026, 11, 12, 23, 59, 59, 999, 999),
      ),
    ).called(1);
  });
}

CategoryEntity _category(CategoryType type, {bool archived = false}) =>
    CategoryEntity(
      id: 3,
      name: type == CategoryType.income ? 'Salary' : 'Food',
      type: type,
      iconKey: 'category',
      isDefault: true,
      isArchived: archived,
    );
