import 'package:intl/intl.dart';

String formatMinor(int amountMinor) =>
    '${NumberFormat('#,##0.00', 'en').format(amountMinor / 100)} EGP';

/// Parses user input ("12", "12.5", "12,05") into piastres. Null when invalid.
int? parseMinor(String input) {
  final text = input.trim().replaceAll(',', '.');
  if (text.isEmpty) return null;
  final parts = text.split('.');
  if (parts.length > 2) return null;

  final whole = int.tryParse(parts[0].isEmpty ? '0' : parts[0]);
  if (whole == null || whole < 0) return null;

  var fraction = 0;
  if (parts.length == 2 && parts[1].isNotEmpty) {
    if (parts[1].length > 2) return null;
    final parsed = int.tryParse(parts[1].padRight(2, '0'));
    if (parsed == null) return null;
    fraction = parsed;
  }
  return whole * 100 + fraction;
}