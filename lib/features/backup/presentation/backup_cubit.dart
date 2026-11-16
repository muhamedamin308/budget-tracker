import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/backup_crypto.dart';
import '../data/export_service.dart';
import '../domain/backup_repository.dart';

sealed class BackupState extends Equatable {
  const BackupState();

  @override
  List<Object?> get props => [];
}

class BackupInitial extends BackupState {
  const BackupInitial();
}

class BackupLoading extends BackupState {
  const BackupLoading(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class BackupSuccess extends BackupState {
  const BackupSuccess(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class BackupError extends BackupState {
  const BackupError(this.error);
  final String error;

  @override
  List<Object?> get props => [error];
}

class RestorePreviewReady extends BackupState {
  const RestorePreviewReady({
    required this.summary,
    required this.rawDecryptedJson,
  });

  final BackupSummary summary;
  final String rawDecryptedJson;

  @override
  List<Object?> get props => [summary, rawDecryptedJson];
}

class RestorePasswordRequired extends BackupState {
  const RestorePasswordRequired({
    required this.rawEncryptedJson,
  });

  final String rawEncryptedJson;

  @override
  List<Object?> get props => [rawEncryptedJson];
}

@injectable
class BackupCubit extends Cubit<BackupState> {
  BackupCubit(this._repo, this._exportService) : super(const BackupInitial());

  final BackupRepository _repo;
  final ExportService _exportService;

  Future<void> createBackup({String? password}) async {
    emit(const BackupLoading('Creating backup...'));
    try {
      final jsonStr = await _repo.createBackupJson();
      final String finalOutput;
      final String extension;

      if (password != null && password.trim().isNotEmpty) {
        finalOutput = BackupCrypto.encrypt(plainText: jsonStr, password: password.trim());
        extension = 'budgetbackup';
      } else {
        finalOutput = jsonStr;
        extension = 'json';
      }

      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'budget_tracker_backup_$dateStr.$extension';

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(finalOutput, flush: true);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/octet-stream', name: fileName)],
        subject: 'Budget Tracker Backup ($dateStr)',
      );

      emit(BackupSuccess('Backup saved and shared as $fileName'));
    } catch (e) {
      emit(BackupError('Failed to create backup: $e'));
    }
  }

  Future<void> pickAndInspectFile() async {
    emit(const BackupLoading('Reading file...'));
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result == null || result.files.single.path == null) {
        emit(const BackupInitial());
        return;
      }

      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      if (BackupCrypto.isEncrypted(content)) {
        emit(RestorePasswordRequired(rawEncryptedJson: content));
      } else {
        final summary = await _repo.inspectBackupJson(content);
        emit(RestorePreviewReady(summary: summary, rawDecryptedJson: content));
      }
    } catch (e) {
      emit(BackupError('Invalid backup file: $e'));
    }
  }

  void unlockWithPassword(String encryptedJson, String password) {
    emit(const BackupLoading('Decrypting backup...'));
    try {
      final decrypted = BackupCrypto.decrypt(
        encryptedJson: encryptedJson,
        password: password.trim(),
      );
      _repo.inspectBackupJson(decrypted).then((summary) {
        emit(RestorePreviewReady(summary: summary, rawDecryptedJson: decrypted));
      }).catchError((e) {
        emit(BackupError('Failed to parse decrypted backup: $e'));
      });
    } catch (_) {
      emit(const BackupError('Incorrect password or corrupted backup file'));
    }
  }

  Future<void> confirmRestore(String rawJson) async {
    emit(const BackupLoading('Restoring database...'));
    try {
      await _repo.restoreFromJson(rawJson);
      emit(const BackupSuccess('Database restored successfully!'));
    } catch (e) {
      emit(BackupError('Failed to restore database: $e'));
    }
  }

  Future<void> exportCsv({DateTime? month, int? walletId}) async {
    emit(const BackupLoading('Generating CSV...'));
    try {
      final csvString = await _exportService.generateCsv(month: month, walletId: walletId);
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final fileName = 'budget_tracker_transactions_$dateStr.csv';

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(csvString, flush: true);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv', name: fileName)],
        subject: 'Budget Tracker CSV Export',
      );

      emit(BackupSuccess('Exported CSV: $fileName'));
    } catch (e) {
      emit(BackupError('Failed to export CSV: $e'));
    }
  }

  Future<void> exportPdf({required DateTime month, int? walletId}) async {
    emit(const BackupLoading('Building PDF Statement...'));
    try {
      final pdfBytes = await _exportService.generateMonthlyPdf(month: month, walletId: walletId);
      final monthStr = DateFormat('yyyy_MM').format(month);
      final fileName = 'budget_statement_$monthStr.pdf';

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes, flush: true);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf', name: fileName)],
        subject: 'Budget Tracker Monthly Statement ($monthStr)',
      );

      emit(BackupSuccess('Statement exported: $fileName'));
    } catch (e) {
      emit(BackupError('Failed to generate PDF: $e'));
    }
  }

  void reset() => emit(const BackupInitial());
}
