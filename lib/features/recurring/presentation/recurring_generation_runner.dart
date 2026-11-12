import 'package:flutter/foundation.dart';

import '../domain/recurring_use_cases.dart';

Future<void> runRecurringGeneration(GenerateDueRecurring generate) async {
  final result = await generate();
  result.fold(
    (failure) => FlutterError.reportError(
      FlutterErrorDetails(
        exception: StateError(failure.message),
        library: 'budget tracker recurring transactions',
        context: ErrorDescription('Generating due recurring transactions'),
      ),
    ),
    (_) {},
  );
}
