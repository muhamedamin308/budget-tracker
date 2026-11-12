import 'package:budget_tracker/core/utils/recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clamps day 31 and handles December and leap-year rollover', () {
    expect(dueDateFor(2026, 12, 31), DateTime(2026, 12, 31, 12));
    expect(dueDateFor(2027, 1, 31), DateTime(2027, 1, 31, 12));
    expect(dueDateFor(2028, 2, 31), DateTime(2028, 2, 29, 12));
    expect(dueDateFor(2027, 2, 31), DateTime(2027, 2, 28, 12));
  });

  test(
    'backfills missed months and treats last-generated date as exclusive',
    () {
      final dates = dueDates(
        dayOfMonth: 31,
        startDate: DateTime(2026, 1, 31),
        after: DateTime(2026, 1, 31, 12),
        until: DateTime(2026, 4, 1),
      ).toList();

      expect(dates, [DateTime(2026, 2, 28, 12), DateTime(2026, 3, 31, 12)]);
    },
  );

  test('recurrence continues across December into the next year', () {
    final dates = dueDates(
      dayOfMonth: 31,
      startDate: DateTime(2026, 11, 1),
      until: DateTime(2027, 2, 1),
    ).toList();

    expect(dates, [
      DateTime(2026, 11, 30, 12),
      DateTime(2026, 12, 31, 12),
      DateTime(2027, 1, 31, 12),
    ]);
  });

  test('includes end date day and stops after the end date or today', () {
    final dates = dueDates(
      dayOfMonth: 15,
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2026, 3, 15),
      until: DateTime(2026, 4, 30, 23, 59),
    ).toList();

    expect(dates, [
      DateTime(2026, 1, 15, 12),
      DateTime(2026, 2, 15, 12),
      DateTime(2026, 3, 15, 12),
    ]);
  });

  test('rejects invalid due days', () {
    expect(() => dueDateFor(2026, 1, 0), throwsArgumentError);
    expect(
      () => dueDates(
        dayOfMonth: 32,
        startDate: DateTime(2026, 1, 1),
        until: DateTime(2026, 2, 1),
      ).toList(),
      throwsArgumentError,
    );
  });
}
