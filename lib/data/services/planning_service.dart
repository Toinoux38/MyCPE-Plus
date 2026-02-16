import '../../core/constants/api_constants.dart';
import '../../core/utils/date_utils.dart' as date_utils;
import '../../core/utils/result.dart';
import '../models/planning_event.dart';
import 'api_client.dart';
import 'planning_cache_service.dart';

/// Service for planning/schedule operations
class PlanningService {
  final ApiClient _apiClient;
  final PlanningCacheService _cacheService;

  PlanningService({
    required ApiClient apiClient,
    PlanningCacheService? cacheService,
  }) : _apiClient = apiClient,
       _cacheService = cacheService ?? PlanningCacheService();

  /// Get planning for a specific date range (from network)
  Future<Result<List<PlanningEvent>>> getPlanning({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _apiClient.get<List<PlanningEvent>>(
      ApiConstants.planningEndpoint,
      queryParams: {
        'date_debut': date_utils.DateUtils.formatForApi(startDate),
        'date_fin': date_utils.DateUtils.formatForApi(endDate),
      },
      fromJson: (json) {
        if (json is! List) return <PlanningEvent>[];
        return json
            .map((e) => PlanningEvent.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  /// Get planning for current week (Monday to Friday)
  Future<Result<List<PlanningEvent>>> getCurrentWeekPlanning() async {
    final now = DateTime.now();
    final monday = date_utils.DateUtils.getMondayOfWeek(now);
    final friday = date_utils.DateUtils.getFridayOfWeek(now);

    return getPlanning(startDate: monday, endDate: friday);
  }

  /// Get planning for a specific week
  Future<Result<List<PlanningEvent>>> getWeekPlanning(
    DateTime referenceDate,
  ) async {
    final monday = date_utils.DateUtils.getMondayOfWeek(referenceDate);
    final friday = date_utils.DateUtils.getFridayOfWeek(referenceDate);

    return getPlanning(startDate: monday, endDate: friday);
  }

  /// Get cached planning for a specific week (returns null if not in cache)
  Future<List<PlanningEvent>?> getCachedWeekPlanning(
    DateTime referenceDate,
  ) async {
    final monday = date_utils.DateUtils.getMondayOfWeek(referenceDate);
    final friday = date_utils.DateUtils.getFridayOfWeek(referenceDate);

    return _cacheService.getCachedEventsForRange(monday, friday);
  }

  /// Check if we have cached data for a week
  Future<bool> hasCacheForWeek(DateTime referenceDate) async {
    final monday = date_utils.DateUtils.getMondayOfWeek(referenceDate);
    final friday = date_utils.DateUtils.getFridayOfWeek(referenceDate);

    return _cacheService.hasCacheForRange(monday, friday);
  }

  /// Get cached events for an arbitrary date range
  Future<List<PlanningEvent>?> getCachedEventsForRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return _cacheService.getCachedEventsForRange(startDate, endDate);
  }

  /// Fetch and cache a full month of planning data
  Future<Result<List<PlanningEvent>>> fetchAndCacheMonthPlanning(
    DateTime month,
  ) async {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);

    final result = await getPlanning(startDate: firstDay, endDate: lastDay);

    switch (result) {
      case Success(data: final events):
        await _cacheService.mergeEvents(events);
      case Failure():
        break;
    }

    return result;
  }

  /// Fetch and cache 2 months of planning data (for background prefetch)
  Future<Result<List<PlanningEvent>>> fetchAndCacheExtendedPlanning() async {
    final now = DateTime.now();
    final monday = date_utils.DateUtils.getMondayOfWeek(now);
    // Fetch from 1 week before to 2 months ahead
    final startDate = monday.subtract(const Duration(days: 7));
    final endDate = monday.add(const Duration(days: 60));

    final result = await getPlanning(startDate: startDate, endDate: endDate);

    // Properly await cache operations using switch instead of when
    switch (result) {
      case Success(data: final events):
        await _cacheService.cacheEvents(events);
        await _cacheService.saveCacheRange(startDate, endDate);
      case Failure():
        // Don't update cache on failure
        break;
    }

    return result;
  }

  /// Fetch week planning and update cache
  Future<Result<List<PlanningEvent>>> fetchAndCacheWeekPlanning(
    DateTime referenceDate,
  ) async {
    final result = await getWeekPlanning(referenceDate);

    // Properly await cache operations using switch instead of when
    switch (result) {
      case Success(data: final events):
        // Merge with existing cache instead of replacing
        await _cacheService.mergeEvents(events);
      case Failure():
        // Don't update cache on failure
        break;
    }

    return result;
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() => _cacheService.getLastSyncTime();

  /// Check if cache is stale
  Future<bool> isCacheStale() => _cacheService.isCacheStale();

  /// Clear cache
  Future<void> clearCache() => _cacheService.clearCache();

  /// Group events by day
  List<DayPlanning> groupEventsByDay(
    List<PlanningEvent> events,
    DateTime mondayOfWeek,
  ) {
    final List<DayPlanning> result = [];

    // Create entries for Monday to Friday
    for (int i = 0; i < 5; i++) {
      final day = mondayOfWeek.add(Duration(days: i));
      final dayEvents = events.where((event) {
        if (event.dateDebut == null) return false;
        return date_utils.DateUtils.isSameDay(event.dateDebut!, day);
      }).toList();

      // Sort events by start time
      dayEvents.sort((a, b) {
        if (a.dateDebut == null) return 1;
        if (b.dateDebut == null) return -1;
        return a.dateDebut!.compareTo(b.dateDebut!);
      });

      result.add(DayPlanning(date: day, events: dayEvents));
    }

    return result;
  }
}
