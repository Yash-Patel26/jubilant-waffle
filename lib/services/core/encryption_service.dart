import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart';
import 'package:uuid/uuid.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const _uuid = Uuid();

  // Key storage constants
  static const String _userKeyPrefix = 'user_encryption_key_';
  static const String _conversationKeyPrefix = 'conversation_key_';
  static const String _masterKeyName = 'master_encryption_key';

  /// Initialize encryption service and generate master key if needed
  Future<void> initialize() async {
    try {
      // Check if master key exists, generate if not
      final masterKey = await _secureStorage.read(key: _masterKeyName);
      if (masterKey == null) {
        await _generateMasterKey();
      }
    } catch (e) {
      throw Exception('Failed to initialize encryption service: $e');
    }
  }

  /// Generate a new master encryption key
  Future<void> _generateMasterKey() async {
    try {
      // Generate a random 32-byte (256-bit) key
      final random = Random.secure();
      final masterKey = List<int>.generate(32, (i) => random.nextInt(256));
      final masterKeyBase64 = base64Encode(masterKey);

      await _secureStorage.write(key: _masterKeyName, value: masterKeyBase64);
    } catch (e) {
      throw Exception('Failed to generate master key: $e');
    }
  }

  /// Generate a unique encryption key for a user
  Future<String> generateUserKey(String userId) async {
    try {
      // Generate a random 32-byte key
      final random = Random.secure();
      final userKey = List<int>.generate(32, (i) => random.nextInt(256));
      final userKeyBase64 = base64Encode(userKey);

      // Store the key securely
      await _secureStorage.write(
        key: '$_userKeyPrefix$userId',
        value: userKeyBase64,
      );

      return userKeyBase64;
    } catch (e) {
      throw Exception('Failed to generate user key: $e');
    }
  }

  /// Generate a conversation key for two users
  Future<String> generateConversationKey(String user1Id, String user2Id) async {
    try {
      // Sort user IDs to ensure consistent key generation
      final sortedIds = [user1Id, user2Id]..sort();
      final conversationId = '${sortedIds[0]}_${sortedIds[1]}';

      // Check if conversation key already exists
      final existingKey = await _secureStorage.read(
        key: '$_conversationKeyPrefix$conversationId',
      );

      if (existingKey != null) {
        return existingKey;
      }

      // Generate a new conversation key
      final random = Random.secure();
      final conversationKey =
          List<int>.generate(32, (i) => random.nextInt(256));
      final conversationKeyBase64 = base64Encode(conversationKey);

      // Store the key securely
      await _secureStorage.write(
        key: '$_conversationKeyPrefix$conversationId',
        value: conversationKeyBase64,
      );

      return conversationKeyBase64;
    } catch (e) {
      throw Exception('Failed to generate conversation key: $e');
    }
  }

  /// Get conversation key for two users
  Future<String?> getConversationKey(String user1Id, String user2Id) async {
    try {
      final sortedIds = [user1Id, user2Id]..sort();
      final conversationId = '${sortedIds[0]}_${sortedIds[1]}';

      return await _secureStorage.read(
        key: '$_conversationKeyPrefix$conversationId',
      );
    } catch (e) {
      return null;
    }
  }

  /// Encrypt message content
  Future<Map<String, dynamic>> encryptMessage(
    String content,
    String conversationKey,
  ) async {
    try {
      // Decode the base64 conversation key
      final keyBytes = base64Decode(conversationKey);
      final key = Key(keyBytes);

      // Generate a random IV (Initialization Vector)
      final iv = IV.fromSecureRandom(16);

      // Create the encrypter
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

      // Encrypt the content
      final encrypted = encrypter.encrypt(content, iv: iv);

      // Generate a unique message ID for this encrypted message
      final messageId = _uuid.v4();

      // Create a hash of the encrypted content for integrity verification
      final contentHash = sha256.convert(encrypted.bytes).toString();

      return {
        'encrypted_content': encrypted.base64,
        'iv': base64Encode(iv.bytes),
        'message_id': messageId,
        'content_hash': contentHash,
        'encryption_version': '1.0',
        'algorithm': 'AES-256-CBC',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to encrypt message: $e');
    }
  }

  /// Decrypt message content
  Future<String> decryptMessage(
    String encryptedContent,
    String iv,
    String conversationKey,
  ) async {
    try {
      // Decode the base64 conversation key and IV
      final keyBytes = base64Decode(conversationKey);
      final ivBytes = base64Decode(iv);

      final key = Key(keyBytes);
      final ivObj = IV(ivBytes);

      // Create the encrypter
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

      // Decrypt the content
      final decrypted = encrypter.decrypt64(encryptedContent, iv: ivObj);

      return decrypted;
    } catch (e) {
      throw Exception('Failed to decrypt message: $e');
    }
  }

  /// Verify message integrity using content hash
  Future<bool> verifyMessageIntegrity(
    String encryptedContent,
    String expectedHash,
  ) async {
    try {
      final contentBytes = base64Decode(encryptedContent);
      final actualHash = sha256.convert(contentBytes).toString();

      return actualHash == expectedHash;
    } catch (e) {
      return false;
    }
  }

  /// Rotate conversation keys (for security)
  Future<String> rotateConversationKey(String user1Id, String user2Id) async {
    try {
      // Generate a new key
      final newKey = await generateConversationKey(user1Id, user2Id);

      // Mark old key for deletion (you might want to keep it temporarily for old messages)
      final sortedIds = [user1Id, user2Id]..sort();
      final conversationId = '${sortedIds[0]}_${sortedIds[1]}';

      await _secureStorage.write(
        key: '$_conversationKeyPrefix${conversationId}_old',
        value: await _secureStorage.read(
          key: '$_conversationKeyPrefix$conversationId',
        ),
      );

      return newKey;
    } catch (e) {
      throw Exception('Failed to rotate conversation key: $e');
    }
  }

  /// Delete all encryption keys for a user (for account deletion)
  Future<void> deleteUserKeys(String userId) async {
    try {
      // Delete user's personal key
      await _secureStorage.delete(key: '$_userKeyPrefix$userId');

      // Find and delete all conversation keys involving this user
      // This is a simplified approach - in production you might want to
      // handle this more carefully to avoid affecting other users
      final allKeys = await _secureStorage.readAll();

      for (final entry in allKeys.entries) {
        if (entry.key.startsWith(_conversationKeyPrefix) &&
            entry.key.contains(userId)) {
          await _secureStorage.delete(key: entry.key);
        }
      }
    } catch (e) {
      throw Exception('Failed to delete user keys: $e');
    }
  }

  /// Get encryption status for debugging
  Future<Map<String, dynamic>> getEncryptionStatus() async {
    try {
      final masterKey = await _secureStorage.read(key: _masterKeyName);
      final allKeys = await _secureStorage.readAll();

      return {
        'master_key_exists': masterKey != null,
        'total_stored_keys': allKeys.length,
        'encryption_keys': allKeys.keys
            .where((key) =>
                key.startsWith(_userKeyPrefix) ||
                key.startsWith(_conversationKeyPrefix))
            .length,
        'service_initialized': true,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'service_initialized': false,
      };
    }
  }
}
