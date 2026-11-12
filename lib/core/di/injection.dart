import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../database/app_database.dart';
import 'injection.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();

@module
abstract class DatabaseModule {
  @lazySingleton
  AppDatabase get appDatabase =>
      AppDatabase(driftDatabase(name: 'budget_tracker'));
}
