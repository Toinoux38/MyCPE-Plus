import 'dart:async';
import '../../core/constants/api_constants.dart';
import '../../core/utils/result.dart';
import '../models/auth_response.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Service for authentication operations
class AuthService {
  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;
  final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();

  /// Fires whenever an authenticated API call returns 401 (token expired/revoked).
  Stream<void> get sessionExpiredStream => _sessionExpiredController.stream;

  AuthService({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  })  : _apiClient = apiClient,
        _tokenStorage = tokenStorage {
    _apiClient.onUnauthorized = () {
      if (!_sessionExpiredController.isClosed) {
        _sessionExpiredController.add(null);
      }
    };
  }
  
  /// Login with email and password
  Future<Result<AuthResponse>> login(String email, String password) async {
    final result = await _apiClient.post<AuthResponse>(
      ApiConstants.loginEndpoint,
      body: {
        'login': email,
        'password': password,
      },
      fromJson: (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
    );
    
    // On success, store the token
    return result.when(
      success: (authResponse) async {
        await _tokenStorage.saveToken(authResponse.normalToken);
        await _tokenStorage.saveUserEmail(email);
        _apiClient.setAuthToken(authResponse.normalToken);
        return Result.success(authResponse);
      },
      failure: (message, statusCode) => Result.failure(message, statusCode: statusCode),
    );
  }
  
  /// Logout and clear stored credentials
  Future<void> logout() async {
    await _tokenStorage.clearAll();
    _apiClient.clearAuthToken();
  }
  
  /// Check if user is authenticated and restore session
  Future<bool> restoreSession() async {
    final token = await _tokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      _apiClient.setAuthToken(token);
      return true;
    }
    return false;
  }
  
  /// Get stored user email
  Future<String?> getUserEmail() async {
    return _tokenStorage.getUserEmail();
  }

  void dispose() {
    _apiClient.onUnauthorized = null;
    _sessionExpiredController.close();
  }
}
