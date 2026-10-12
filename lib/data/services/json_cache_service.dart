import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A cached API response and when it was fetched.
class CachedJson {
  final dynamic json;
  final DateTime savedAt;

  const CachedJson(this.json, this.savedAt);
}

/// Stores raw API responses (grades, absences) to show them offline.
/// Uses the encrypted storage: this is personal data.
class JsonCacheService {
  final FlutterSecureStorage _storage;

  JsonCacheService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  Future<CachedJson?> read(String key) async {
    try {
      final raw = await _storage.read(key: key);
      if (raw == null) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return CachedJson(
        decoded['json'],
        DateTime.parse(decoded['saved_at'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String key, dynamic json) async {
    try {
      await _storage.write(
        key: key,
        value: jsonEncode({
          'json': json,
          'saved_at': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {
      // Cache is best-effort.
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      // Silently fail
    }
  }
}
