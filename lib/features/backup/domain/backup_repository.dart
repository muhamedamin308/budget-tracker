class BackupSummary {
  const BackupSummary({
    required this.exportedAt,
    required this.walletCount,
    required this.categoryCount,
    required this.transactionCount,
    required this.recurringRuleCount,
    required this.monthlyLimitCount,
  });

  final DateTime exportedAt;
  final int walletCount;
  final int categoryCount;
  final int transactionCount;
  final int recurringRuleCount;
  final int monthlyLimitCount;
}

abstract class BackupRepository {
  /// Generates the raw JSON string of all database tables.
  Future<String> createBackupJson();

  /// Inspects raw backup JSON and returns a summary for user confirmation.
  Future<BackupSummary> inspectBackupJson(String rawJson);

  /// Atomically restores database state from the valid backup JSON.
  Future<void> restoreFromJson(String rawJson);
}
