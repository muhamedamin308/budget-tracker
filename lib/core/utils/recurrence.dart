import 'dart:math';

DateTime dueDateFor(int year, int month, int dayOfMonth) {
  if (dayOfMonth < 1 || dayOfMonth > 31) {
    throw ArgumentError.value(dayOfMonth, 'dayOfMonth', 'Must be from 1 to 31');
  }
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, min(dayOfMonth, lastDay), 12);
}

Iterable<DateTime> dueDates({
  required int dayOfMonth,
  required DateTime startDate,
  DateTime? after,
  DateTime? endDate,
  required DateTime until,
}) sync* {
  final anchor = after ?? startDate;
  final startDay = DateTime(startDate.year, startDate.month, startDate.day);
  final endDay = endDate == null
      ? null
      : DateTime(endDate.year, endDate.month, endDate.day);
  var year = anchor.year;
  var month = anchor.month;

  while (true) {
    final due = dueDateFor(year, month, dayOfMonth);
    if (due.isAfter(until)) return;
    if (endDay != null &&
        DateTime(due.year, due.month, due.day).isAfter(endDay)) {
      return;
    }
    if (!due.isBefore(startDay) && (after == null || due.isAfter(after))) {
      yield due;
    }
    month++;
    if (month > 12) {
      month = 1;
      year++;
    }
  }
}
