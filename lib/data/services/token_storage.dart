import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

/// Service for secure token storage
class TokenStorage {
  final FlutterSecureStorage _storage;
  
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );
  
  /// Save authentication token
  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }
  
  /// Get stored authentication token
  Future<String?> getToken() async {
    return _storage.read(key: AppConstants.tokenKey);
  }
  
  /// Delete stored token
  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.tokenKey);
  }
  
  /// Save user email
  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: AppConstants.userEmailKey, value: email);
  }
  
  /// Get stored user email
  Future<String?> getUserEmail() async {
    return _storage.read(key: AppConstants.userEmailKey);
  }
  
  /// Clear the session (keeps app settings like theme and language)
  Future<void> clearAll() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userEmailKey);
  }
  
  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
