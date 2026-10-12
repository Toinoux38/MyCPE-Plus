import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/utils/result.dart';

/// HTTP client wrapper for API requests
class ApiClient {
  final http.Client _client;
  String? _authToken;

  /// Called when an authenticated request receives a 401 (session expired).
  VoidCallback? onUnauthorized;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  
  /// Set authentication token for subsequent requests
  void setAuthToken(String? token) {
    _authToken = token;
  }
  
  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }
  
  /// Get default headers
  Map<String, String> get _defaultHeaders {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }
  
  /// Build full URL from endpoint
  Uri _buildUrl(String endpoint, [Map<String, String>? queryParams]) {
    final url = '${ApiConstants.baseUrl}$endpoint';
    final uri = Uri.parse(url);
    
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    
    return uri;
  }
  
  /// Perform GET request
  Future<Result<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final uri = _buildUrl(endpoint, queryParams);
      
      final response = await _client
          .get(uri, headers: _defaultHeaders)
          .timeout(ApiConstants.requestTimeout);
      
      return _handleResponse(response, fromJson);
    } on SocketException {
      return Result.failure('No internet connection');
    } on http.ClientException catch (e) {
      return Result.failure('Network error: ${e.message}');
    } catch (e) {
      return Result.failure('Unexpected error: $e');
    }
  }
  
  /// Perform POST request
  Future<Result<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    required T Function(dynamic json) fromJson,
  }) async {
    try {
      final uri = _buildUrl(endpoint);
      
      final response = await _client
          .post(
            uri,
            headers: _defaultHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConstants.requestTimeout);
      
      return _handleResponse(response, fromJson);
    } on SocketException {
      return Result.failure('No internet connection');
    } on http.ClientException catch (e) {
      return Result.failure('Network error: ${e.message}');
    } catch (e) {
      return Result.failure('Unexpected error: $e');
    }
  }
  
  /// Handle HTTP response
  Result<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic json) fromJson,
  ) {
    final statusCode = response.statusCode;
    
    if (statusCode >= 200 && statusCode < 300) {
      try {
        final dynamic json = jsonDecode(response.body);
        return Result.success(fromJson(json));
      } catch (e) {
        return Result.failure('Failed to parse response: $e');
      }
    }
    
    // Handle specific error codes
    switch (statusCode) {
      case 401:
        // Only fire if a token was present — login failures don't count.
        if (_authToken != null) onUnauthorized?.call();
        return Result.failure('Invalid credentials', statusCode: 401);
      case 403:
        return Result.failure('Access denied', statusCode: 403);
      case 404:
        return Result.failure('Resource not found', statusCode: 404);
      case 500:
        return Result.failure('Server error', statusCode: 500);
      default:
        return Result.failure('Request failed with status $statusCode', statusCode: statusCode);
    }
  }
  
  /// Dispose client resources
  void dispose() {
    _client.close();
  }
}
