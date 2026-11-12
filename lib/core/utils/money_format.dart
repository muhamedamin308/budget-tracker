import 'package:intl/intl.dart';

String formatMinor(int amountMinor) =>
    '${NumberFormat('#,##0.00', 'en').format(amountMinor / 100)} EGP';
