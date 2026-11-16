import 'package:flutter_test/flutter_test.dart';
import 'package:budget_tracker/features/backup/data/backup_crypto.dart';

void main() {
  group('BackupCrypto', () {
    const plainJson = '{"app":"BudgetTracker","version":1,"wallets":[{"name":"Main"}]}';
    const password = 'SuperSecretPassword123!';

    test('encrypts and decrypts correctly with the right password', () {
      final encrypted = BackupCrypto.encrypt(
        plainText: plainJson,
        password: password,
      );

      expect(BackupCrypto.isEncrypted(encrypted), isTrue);
      expect(encrypted, isNot(contains('BudgetTracker')));

      final decrypted = BackupCrypto.decrypt(
        encryptedJson: encrypted,
        password: password,
      );

      expect(decrypted, equals(plainJson));
    });

    test('fails decryption with wrong password', () {
      final encrypted = BackupCrypto.encrypt(
        plainText: plainJson,
        password: password,
      );

      expect(
        () => BackupCrypto.decrypt(
          encryptedJson: encrypted,
          password: 'WrongPassword!',
        ),
        throwsA(anything),
      );
    });

    test('isEncrypted identifies plain vs encrypted json correctly', () {
      expect(BackupCrypto.isEncrypted(plainJson), isFalse);

      final encrypted = BackupCrypto.encrypt(
        plainText: plainJson,
        password: password,
      );
      expect(BackupCrypto.isEncrypted(encrypted), isTrue);
    });
  });
}
