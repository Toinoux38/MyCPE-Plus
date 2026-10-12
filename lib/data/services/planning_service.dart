import 'dart:async';

import '../../core/constants/api_constants.dart';
import '../../core/utils/date_utils.dart' as date_utils;
import '../../core/utils/result.dart';
import '../models/planning_event.dart';
import 'api_client.dart';
import 'planning_cache_service.dart';

typedef _Du = date_utils.DateUtils;

/// Single source of truth for planning data.
///
/// Events are stored per day, together with the time each day was last
/// fetched. Network responses are applied to the days they cover, so a
/// response can never land on the wrong week, whatever the user is viewing.
class PlanningService {
  /// Days older than this are dropped from the cache.
  static const int _keepPastDays = 120;
  static const Duration _saveDelay = Duration(milliseconds: 500);

  final ApiClient _apiClient;
  final PlanningCacheService _cacheService;

  final Map<DateTime, List<PlanningEvent>> _eventsByDay = {};
  final Map<DateTime, DateTime> _fetchedAt = {};
  final Map<String, Future<Result<bool>>> _inFlight = {};
  Future<void>? _loading;
  Timer? _saveTimer;
  // Bumped on clearCache() so responses of requests sent before a logout
  // are dropped instead of repopulating the cache.
  int _generation = 0;

  PlanningService({
    required ApiClient apiClient,
    PlanningCacheService? cacheService,
  }) : _apiClient = apiClient,
       _cacheService = cacheService ?? PlanningCacheService();

  /// Load the persisted cache into memory (once).
  Future<void> loadCache() => _loading ??= _loadCache();

  Future<void> _loadCache() async {
    final snapshot = await _cacheService.load();
    for (final event in snapshot.events) {
      final start = event.dateDebut;
      if (start == null) continue;
      _eventsByDay.putIfAbsent(_Du.dateOnly(start), () => []).add(event);
    }
    _eventsByDay.updateAll((_, events) => events..sort(_byStart));
    _fetchedAt.addAll(snapshot.fetchedAt);
  }

  /// Whether [day] has been synced at least once.
  bool isDayLoaded(DateTime day) => _fetchedAt.containsKey(_Du.dateOnly(day));

  /// All events (courses, breaks...) of [day], sorted by start time.
  List<PlanningEvent> eventsForDay(DateTime day) =>
      _eventsByDay[_Du.dateOnly(day)] ?? const [];

  /// Every cached event (used by the home screen widget).
  List<PlanningEvent> get allEvents =>
      _eventsByDay.values.expand((e) => e).toList();

  /// Oldest sync time among the days of the range, null if one is missing.
  DateTime? rangeFetchedAt(DateTime start, DateTime end) {
    DateTime? oldest;
    for (final day in _Du.daysInRange(start, end)) {
      final at = _fetchedAt[day];
      if (at == null) return null;
      if (oldest == null || at.isBefore(oldest)) oldest = at;
    }
    return oldest;
  }

  /// Most recent sync time of any day.
  DateTime? get lastSyncTime => _fetchedAt.values.fold<DateTime?>(
    null,
    (latest, at) => latest == null || at.isAfter(latest) ? at : latest,
  );

  /// Fetch [start]..[end] (inclusive days) and store the result.
  ///
  /// Succeeds with `true` when the stored data changed. Concurrent calls for
  /// the same range share a single request.
  Future<Result<bool>> fetchRange(DateTime start, DateTime end) {
    final from = _Du.dateOnly(start);
    final to = _Du.dateOnly(end);
    final key = '${from.toIso8601String()}|${to.toIso8601String()}';
    // Block body on purpose: returning the removed future from whenComplete
    // would make the request wait on itself.
    return _inFlight[key] ??= _fetchRange(from, to).whenComplete(() {
      _inFlight.remove(key);
    });
  }

  bool get hasRequestInFlight => _inFlight.isNotEmpty;

  Future<Result<bool>> _fetchRange(DateTime from, DateTime to) async {
    await loadCache();
    final generation = _generation;
    // Ask one extra day so the range is complete whether the API treats
    // date_fin as inclusive or exclusive; events past [to] are ignored.
    final result = await _apiClient.get<List<PlanningEvent>>(
      ApiConstants.planningEndpoint,
      queryParams: {
        'date_debut': _Du.formatForApi(from),
        'date_fin': _Du.formatForApi(_Du.addDays(to, 1)),
      },
      fromJson: (json) {
        if (json is! List) return <PlanningEvent>[];
        return json
            .map((e) => PlanningEvent.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );

    if (generation != _generation) return Result.success(false);
    switch (result) {
      case Success(data: final events):
        return Result.success(_applyRange(from, to, events));
      case Failure(:final message, :final statusCode):
        return Result.failure(message, statusCode: statusCode);
    }
  }

  /// Replace the content of every day in [from]..[to] with [events].
  /// Returns whether any day's content changed.
  bool _applyRange(DateTime from, DateTime to, List<PlanningEvent> events) {
    final byDay = <DateTime, List<PlanningEvent>>{};
    for (final event in events) {
      final start = event.dateDebut;
      if (start == null) continue;
      byDay.putIfAbsent(_Du.dateOnly(start), () => []).add(event);
    }

    final now = DateTime.now();
    var changed = false;
    for (final day in _Du.daysInRange(from, to)) {
      final fresh = (byDay[day] ?? <PlanningEvent>[])..sort(_byStart);
      if (!_sameContent(_eventsByDay[day], fresh) ||
          !_fetchedAt.containsKey(day)) {
        changed = true;
      }
      if (fresh.isEmpty) {
        _eventsByDay.remove(day);
      } else {
        _eventsByDay[day] = fresh;
      }
      _fetchedAt[day] = now;
    }

    _prune();
    _scheduleSave();
    return changed;
  }

  void _prune() {
    final limit = _Du.addDays(DateTime.now(), -_keepPastDays);
    _eventsByDay.removeWhere((day, _) => day.isBefore(limit));
    _fetchedAt.removeWhere((day, _) => day.isBefore(limit));
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDelay, () {
      _cacheService.save(
        PlanningSnapshot(events: allEvents, fetchedAt: Map.of(_fetchedAt)),
      );
    });
  }

  /// Forget everything (logout).
  Future<void> clearCache() async {
    _generation++;
    _saveTimer?.cancel();
    _inFlight.clear();
    _eventsByDay.clear();
    _fetchedAt.clear();
    _loading = null;
    await _cacheService.clear();
  }

  static int _byStart(PlanningEvent a, PlanningEvent b) {
    if (a.dateDebut == null) return 1;
    if (b.dateDebut == null) return -1;
    return a.dateDebut!.compareTo(b.dateDebut!);
  }

  static bool _sameContent(List<PlanningEvent>? a, List<PlanningEvent> b) {
    final old = a ?? const <PlanningEvent>[];
    if (old.length != b.length) return false;
    for (var i = 0; i < old.length; i++) {
      if (old[i].contentKey != b[i].contentKey) return false;
    }
    return true;
  }
}
