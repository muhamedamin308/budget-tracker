import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class BackupCrypto {
  const BackupCrypto();

  static const int _saltLength = 16;
  static const int _keyLength = 32;
  static const int _iterations = 10000;

  /// Encrypts plain text JSON with AES-256 (CBC with PKCS7 padding) derived from a password via PBKDF2.
  static String encrypt({
    required String plainText,
    required String password,
  }) {
    final salt = _randomBytes(_saltLength);
    final ivBytes = _randomBytes(16);

    final keyBytes = _deriveKey(password, salt);
    final key = enc.Key(Uint8List.fromList(keyBytes));
    final iv = enc.IV(Uint8List.fromList(ivBytes));

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    final payload = {
      'encrypted': true,
      'salt': enc.Encrypted(Uint8List.fromList(salt)).base64,
      'iv': iv.base64,
      'ciphertext': encrypted.base64,
    };

    return jsonEncode(payload);
  }

  /// Decrypts payload JSON using the provided password. Throws if password is wrong or ciphertext corrupted.
  static String decrypt({
    required String encryptedJson,
    required String password,
  }) {
    final Map<String, dynamic> map = jsonDecode(encryptedJson) as Map<String, dynamic>;
    if (map['encrypted'] != true) {
      throw const FormatException('Payload is not encrypted');
    }

    final salt = enc.Encrypted.fromBase64(map['salt'] as String).bytes;
    final iv = enc.IV.fromBase64(map['iv'] as String);
    final ciphertext = map['ciphertext'] as String;

    final keyBytes = _deriveKey(password, salt);
    final key = enc.Key(Uint8List.fromList(keyBytes));

    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    return encrypter.decrypt64(ciphertext, iv: iv);
  }

  /// Returns true if the json string is marked as encrypted.
  static bool isEncrypted(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded['encrypted'] == true;
      }
    } catch (_) {}
    return false;
  }

  static List<int> _deriveKey(String password, List<int> salt) {
    // PBKDF2 implementation with HMAC-SHA256
    final hmac = Hmac(sha256, utf8.encode(password));
    final derivedKey = <int>[];
    var blockIndex = 1;

    while (derivedKey.length < _keyLength) {
      final block = _pbkdf2Block(hmac, salt, _iterations, blockIndex);
      derivedKey.addAll(block);
      blockIndex++;
    }

    return derivedKey.sublist(0, _keyLength);
  }

  static List<int> _pbkdf2Block(
    Hmac hmac,
    List<int> salt,
    int iterations,
    int blockIndex,
  ) {
    final blockBytes = Uint8List(4)
      ..buffer.asByteData().setUint32(0, blockIndex, Endian.big);

    var u = hmac.convert([...salt, ...blockBytes]).bytes;
    final output = List<int>.from(u);

    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < output.length; j++) {
        output[j] ^= u[j];
      }
    }

    return output;
  }

  static List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}
