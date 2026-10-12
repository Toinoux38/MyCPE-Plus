import '../../core/constants/api_constants.dart';
import '../../core/utils/result.dart';
import '../models/absences_response.dart';
import 'api_client.dart';
import 'json_cache_service.dart';

/// Service for absences operations
class AbsencesService {
  static const String _cacheKey = 'absences_cache';

  final ApiClient _apiClient;
  final JsonCacheService _cache;
  // Bumped on clearCache() so a response arriving after logout isn't cached.
  int _generation = 0;

  AbsencesService({required ApiClient apiClient, JsonCacheService? cache})
    : _apiClient = apiClient,
      _cache = cache ?? JsonCacheService();

  /// Last absences fetched, with their date (null if never fetched).
  Future<(AbsencesResponse, DateTime)?> getCachedAbsences() async {
    final cached = await _cache.read(_cacheKey);
    if (cached == null) return null;
    try {
      return (
        AbsencesResponse.fromJson(cached.json as Map<String, dynamic>),
        cached.savedAt,
      );
    } catch (_) {
      return null;
    }
  }

  /// Fetch absences from the server (and cache them).
  Future<Result<AbsencesResponse>> fetchAbsences() async {
    final generation = _generation;
    dynamic raw;
    final result = await _apiClient.get<AbsencesResponse>(
      ApiConstants.absencesEndpoint,
      fromJson: (json) =>
          AbsencesResponse.fromJson((raw = json) as Map<String, dynamic>),
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
