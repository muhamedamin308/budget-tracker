import 'package:budget_tracker/core/utils/money_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats minor units as grouped EGP amounts', () {
    expect(formatMinor(123450), '1,234.50 EGP');
    expect(formatMinor(-50000), '-500.00 EGP');
  });
}
