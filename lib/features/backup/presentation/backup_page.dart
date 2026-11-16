import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/backup_repository.dart';
import 'backup_cubit.dart';

class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<BackupCubit>(),
      child: const _BackupPageView(),
    );
  }
}

class _BackupPageView extends StatefulWidget {
  const _BackupPageView();

  @override
  State<_BackupPageView> createState() => _BackupPageViewState();
}

class _BackupPageViewState extends State<_BackupPageView> {
  DateTime _selectedExportMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Data & Backups')),
      body: BlocConsumer<BackupCubit, BackupState>(
        listener: (context, state) {
          if (state is BackupSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.primaryEmerald,
              ),
            );
          } else if (state is BackupError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: AppTheme.expenseCoral,
              ),
            );
          } else if (state is RestorePasswordRequired) {
            _showPasswordPromptDialog(context, state.rawEncryptedJson);
          } else if (state is RestorePreviewReady) {
            _showRestoreConfirmationDialog(
              context,
              state.summary,
              state.rawDecryptedJson,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is BackupLoading;

          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  _buildHeaderCard(isDark),
                  const SizedBox(height: 24),
                  Text(
                    'BACKUP & RESTORE',
                    style: theme.textTheme.titleSmall?.copyWith(
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBackupCard(context, isDark),
                  const SizedBox(height: 12),
                  _buildRestoreCard(context, isDark),
                  const SizedBox(height: 32),
                  Text(
                    'EXPORT REPORTS',
                    style: theme.textTheme.titleSmall?.copyWith(
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildExportCard(context, isDark),
                  const SizedBox(height: 40),
                ],
              ),
              if (isLoading)
                Container(
                  color: Colors.black45,
                  child: Center(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: AppTheme.primaryEmerald,
                            ),
                            const SizedBox(height: 16),
                            Text(state.message),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppTheme.primaryEmerald,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '100% Offline & Private',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'Your financial data never touches any server. Create regular backups to keep your history safe.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCard(BuildContext context, bool isDark) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0x1A0D9373),
          child: Icon(
            Icons.cloud_upload_outlined,
            color: AppTheme.primaryEmerald,
          ),
        ),
        title: const Text(
          'Create Full Backup',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Export all transactions, wallets & budgets'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => _showCreateBackupDialog(context),
      ),
    );
  }

  Widget _buildRestoreCard(BuildContext context, bool isDark) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0x1A3B82F6),
          child: Icon(
            Icons.settings_backup_restore_rounded,
            color: AppTheme.infoBlue,
          ),
        ),
        title: const Text(
          'Restore from Backup',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Select a .budgetbackup or .json file to restore'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.read<BackupCubit>().pickAndInspectFile(),
      ),
    );
  }

  Widget _buildExportCard(BuildContext context, bool isDark) {
    final monthLabel = DateFormat.yMMMM().format(_selectedExportMonth);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Statement Month',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                TextButton.icon(
                  onPressed: () => _pickMonth(context),
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Text(monthLabel),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.read<BackupCubit>().exportCsv(
                      month: _selectedExportMonth,
                    ),
                    icon: const Icon(Icons.table_chart_outlined, size: 20),
                    label: const Text('CSV Export'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryEmerald,
                    ),
                    onPressed: () => context.read<BackupCubit>().exportPdf(
                      month: _selectedExportMonth,
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                    label: const Text('PDF Report'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => context.read<BackupCubit>().exportCsv(),
                child: const Text('Export All Time to CSV'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMonth(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedExportMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _selectedExportMonth = DateTime(picked.year, picked.month);
      });
    }
  }

  void _showCreateBackupDialog(BuildContext context) {
    final passwordController = TextEditingController();
    bool protectWithPassword = false;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'A backup file containing all your data will be created and opened in your share sheet.',
              ),
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Protect with password',
                  style: TextStyle(fontSize: 14),
                ),
                value: protectWithPassword,
                activeTrackColor: AppTheme.primaryEmerald,
                onChanged: (val) {
                  setDialogState(() => protectWithPassword = val);
                },
              ),
              if (protectWithPassword) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter encryption password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final pwd = protectWithPassword
                    ? passwordController.text
                    : null;
                Navigator.of(dialogCtx).pop();
                context.read<BackupCubit>().createBackup(password: pwd);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPasswordPromptDialog(
    BuildContext context,
    String rawEncryptedJson,
  ) {
    final passwordController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Encrypted Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This backup is protected with a password. Enter it to unlock.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<BackupCubit>().reset();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final pwd = passwordController.text;
              Navigator.of(dialogCtx).pop();
              context.read<BackupCubit>().unlockWithPassword(
                rawEncryptedJson,
                pwd,
              );
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }

  void _showRestoreConfirmationDialog(
    BuildContext context,
    BackupSummary summary,
    String rawDecryptedJson,
  ) {
    final dateStr = DateFormat.yMMMd().add_jm().format(summary.exportedAt);

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirm Restore'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ Restoring will overwrite all existing data in the app with the contents of this backup.',
              style: TextStyle(
                color: AppTheme.expenseCoral,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Backup Created: $dateStr',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('• Transactions: ${summary.transactionCount}'),
            Text('• Wallets: ${summary.walletCount}'),
            Text('• Categories: ${summary.categoryCount}'),
            Text('• Recurring Rules: ${summary.recurringRuleCount}'),
            Text('• Monthly Budgets: ${summary.monthlyLimitCount}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<BackupCubit>().reset();
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.expenseCoral,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<BackupCubit>().confirmRestore(rawDecryptedJson);
            },
            child: const Text('Replace & Restore'),
          ),
        ],
      ),
    );
  }
}
