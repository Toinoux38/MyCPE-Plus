import '../../core/constants/api_constants.dart';
import '../../core/utils/result.dart';
import '../models/course_grades.dart';
import 'api_client.dart';
import 'json_cache_service.dart';

/// Service for grades operations
class GradesService {
  static const String _cacheKey = 'grades_cache';

  final ApiClient _apiClient;
  final JsonCacheService _cache;
  // Bumped on clearCache() so a response arriving after logout isn't cached.
  int _generation = 0;

  GradesService({required ApiClient apiClient, JsonCacheService? cache})
    : _apiClient = apiClient,
      _cache = cache ?? JsonCacheService();

  static List<CourseGrades> _parse(dynamic json) {
    if (json is! List) return <CourseGrades>[];
    return json
        .map((e) => CourseGrades.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Last grades fetched, with their date (null if never fetched).
  Future<(List<CourseGrades>, DateTime)?> getCachedGrades() async {
    final cached = await _cache.read(_cacheKey);
    if (cached == null) return null;
    try {
      return (_parse(cached.json), cached.savedAt);
    } catch (_) {
      return null;
    }
  }

  /// Get all grades from the API (and cache them).
  Future<Result<List<CourseGrades>>> getGrades() async {
    final generation = _generation;
    dynamic raw;
    final result = await _apiClient.get<List<CourseGrades>>(
      ApiConstants.gradesEndpoint,
      fromJson: (json) => _parse(raw = json),
    );
    if (result is Success && generation == _generation) {
      await _cache.write(_cacheKey, raw);
    }
    return result;
  }

  Future<void> clearCache() {
    _generation++;
    return _cache.delete(_cacheKey);
  }
}
