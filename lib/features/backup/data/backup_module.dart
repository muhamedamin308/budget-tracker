import 'package:injectable/injectable.dart';

import '../../../core/database/app_database.dart';
import 'export_service.dart';

@module
abstract class BackupModule {
  @lazySingleton
  ExportService exportService(AppDatabase db) => ExportService(db);
}
