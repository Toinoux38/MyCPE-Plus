import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/planning_event.dart';

/// Persisted planning data: the events, plus when each day was last fetched.
///
/// A day present in [fetchedAt] is known (possibly with no course); a day
/// absent from it has never been synced and must not be shown as empty.
class PlanningSnapshot {
  final List<PlanningEvent> events;
  final Map<DateTime, DateTime> fetchedAt;

  const PlanningSnapshot({required this.events, required this.fetchedAt});

  static const empty = PlanningSnapshot(events: [], fetchedAt: {});
}

/// Service for caching planning data locally
class PlanningCacheService {
  static const String _cacheKey = 'planning_cache_v2';
  // Keys written by older versions of the app.
  static const List<String> _legacyKeys = [
    'planning_cache',
    'planning_last_sync',
    'planning_cache_range',
  ];

  final FlutterSecureStorage _storage;

  PlanningCacheService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  Future<PlanningSnapshot> load() async {
    try {
      final jsonString = await _storage.read(key: _cacheKey);
      if (jsonString == null) {
        // Old caches have no per-day sync info: drop them and refetch.
        for (final key in _legacyKeys) {
          await _storage.delete(key: key);
        }
        return PlanningSnapshot.empty;
      }

      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final events = (decoded['events'] as List<dynamic>)
          .map((e) => PlanningEvent.fromJson(e as Map<String, dynamic>))
          .toList();
      final fetchedAt = (decoded['fetched_at'] as Map<String, dynamic>).map(
        (day, at) => MapEntry(DateTime.parse(day), DateTime.parse(at as String)),
      );
      return PlanningSnapshot(events: events, fetchedAt: fetchedAt);
    } catch (_) {
      return PlanningSnapshot.empty;
    }
  }

  Future<void> save(PlanningSnapshot snapshot) async {
    try {
      final jsonString = jsonEncode({
        'events': snapshot.events.map((e) => e.toJson()).toList(),
        'fetched_at': snapshot.fetchedAt.map(
          (day, at) => MapEntry(
            day.toIso8601String().substring(0, 10),
            at.toIso8601String(),
          ),
        ),
      });
      await _storage.write(key: _cacheKey, value: jsonString);
    } catch (_) {
      // Cache is best-effort.
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _cacheKey);
      for (final key in _legacyKeys) {
        await _storage.delete(key: key);
      }
    } catch (_) {
      // Silently fail
    }
  }
}
