import 'package:flutter/material.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'features/recurring/domain/recurring_use_cases.dart';
import 'features/recurring/presentation/recurring_generation_runner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  await runRecurringGeneration(getIt<GenerateDueRecurring>());
  runApp(const BudgetTrackerApp());
}
