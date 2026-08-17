import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';

/// Service for securely storing and retrieving sensitive data
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      resetOnError: true,
    ),
  );

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    await _storage.write(
      key: StorageKeys.accessToken,
      value: token,
    );
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: StorageKeys.accessToken);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(
      key: StorageKeys.refreshToken,
      value: token,
    );
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: StorageKeys.refreshToken);
  }

  /// Save token expiration time
  Future<void> saveTokenExpiresAt(DateTime expiresAt) async {
    await _storage.write(
      key: StorageKeys.tokenExpiresAt,
      value: expiresAt.toIso8601String(),
    );
  }

  /// Get token expiration time
  Future<DateTime?> getTokenExpiresAt() async {
    final expiresAtStr =
        await _storage.read(key: StorageKeys.tokenExpiresAt);
    if (expiresAtStr == null) return null;
    return DateTime.tryParse(expiresAtStr);
  }

  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    final expiresAt = await getTokenExpiresAt();
    if (expiresAt == null) return true;
    return DateTime.now().isAfter(expiresAt);
  }

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await _storage.write(
      key: StorageKeys.userId,
      value: userId,
    );
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: StorageKeys.userId);
  }

  /// Save user name
  Future<void> saveUserName(String userName) async {
    await _storage.write(
      key: StorageKeys.userName,
      value: userName,
    );
  }

  /// Get user name
  Future<String?> getUserName() async {
    return await _storage.read(key: StorageKeys.userName);
  }

  /// Save user email
  Future<void> saveUserEmail(String userEmail) async {
    await _storage.write(
      key: StorageKeys.userEmail,
      value: userEmail,
    );
  }

  /// Get user email
  Future<String?> getUserEmail() async {
    return await _storage.read(key: StorageKeys.userEmail);
  }

  /// Save preference value
  Future<void> savePref(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Get preference value
  Future<String?> getPref(String key) async {
    return await _storage.read(key: key);
  }

  /// Delete specific key
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Clear all stored data (used for logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
