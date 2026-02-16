import 'package:flutter/foundation.dart';
import '../core/utils/date_utils.dart' as date_utils;
import '../data/models/planning_event.dart';
import '../data/services/planning_service.dart';

/// Loading state for planning data
enum PlanningState { initial, loading, loaded, error }

/// Sync status for planning data
enum PlanningSyncStatus {
  /// Data is from cache, not yet synced
  cached,

  /// Currently fetching fresh data from server
  syncing,

  /// Data is fresh from server
  synced,

  /// Offline mode, showing cached data
  offline,
}

/// View mode for the planning screen
enum PlanningViewMode { day, week, month }

/// Provider for planning/schedule state management
class PlanningProvider extends ChangeNotifier {
  final PlanningService _planningService;

  PlanningState _state = PlanningState.initial;
  PlanningSyncStatus _syncStatus = PlanningSyncStatus.synced;
  String? _errorMessage;
  List<DayPlanning> _weekPlanning = [];
  DateTime _currentMonday = date_utils.DateUtils.getMondayOfWeek(
    DateTime.now(),
  );
  int _selectedDayIndex = 0; // 0 = Monday, 4 = Friday
  DateTime? _lastSyncTime;
  bool _isOffline = false;
  bool _hasInitializedCache = false;

  /// Current view mode (day, week, month)
  PlanningViewMode _viewMode = PlanningViewMode.day;

  /// Current month being viewed in month mode
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  /// Cached events for the current month (keyed by day)
  Map<DateTime, List<PlanningEvent>> _monthEvents = {};

  PlanningProvider({required PlanningService planningService})
    : _planningService = planningService {
    // Set initial selected day to today if it's a weekday
    final today = DateTime.now();
    final monday = date_utils.DateUtils.getMondayOfWeek(today);
    final dayDiff = today.difference(monday).inDays;
    if (dayDiff >= 0 && dayDiff <= 4) {
      _selectedDayIndex = dayDiff;
    }
  }

  PlanningState get state => _state;
  PlanningSyncStatus get syncStatus => _syncStatus;
  String? get errorMessage => _errorMessage;
  List<DayPlanning> get weekPlanning => _weekPlanning;
  DateTime get currentMonday => _currentMonday;
  bool get isLoading => _state == PlanningState.loading;
  int get selectedDayIndex => _selectedDayIndex;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isOffline => _isOffline;
  bool get isSyncing => _syncStatus == PlanningSyncStatus.syncing;
  PlanningViewMode get viewMode => _viewMode;
  DateTime get currentMonth => _currentMonth;
  Map<DateTime, List<PlanningEvent>> get monthEvents => _monthEvents;

  /// Get selected date
  DateTime get selectedDate =>
      _currentMonday.add(Duration(days: _selectedDayIndex));

  /// Get selected day planning
  DayPlanning? get selectedDayPlanning {
    if (_weekPlanning.isEmpty) return null;
    if (_selectedDayIndex >= _weekPlanning.length) return null;
    return _weekPlanning[_selectedDayIndex];
  }

  /// Check if selected date is today
  bool get isToday =>
      date_utils.DateUtils.isSameDay(selectedDate, DateTime.now());

  /// Get week range string for current view
  String get weekRangeString =>
      date_utils.DateUtils.getWeekRangeString(_currentMonday);

  /// Select a day by index (0-4 for Mon-Fri)
  void selectDay(int index) {
    if (index >= 0 && index <= 4 && index != _selectedDayIndex) {
      _selectedDayIndex = index;
      notifyListeners();
    }
  }

  /// Load planning with cache-first strategy
  /// Shows cached data immediately, then fetches fresh data in background
  Future<void> loadWeekPlanning() async {
    _errorMessage = null;

    // Try to load from cache first
    final cachedEvents = await _planningService.getCachedWeekPlanning(
      _currentMonday,
    );

    if (cachedEvents != null && cachedEvents.isNotEmpty) {
      // Show cached data immediately
      _weekPlanning = _planningService.groupEventsByDay(
        cachedEvents,
        _currentMonday,
      );
      _state = PlanningState.loaded;
      _syncStatus = PlanningSyncStatus.cached;
      notifyListeners();

      // Fetch fresh data in background
      _fetchFreshDataInBackground();
    } else {
      // No cache, show loading and fetch from network
      _state = PlanningState.loading;
      _syncStatus = PlanningSyncStatus.syncing;
      notifyListeners();

      await _fetchFromNetwork();
    }
  }

  /// Fetch fresh data in background without blocking UI
  Future<void> _fetchFreshDataInBackground() async {
    _syncStatus = PlanningSyncStatus.syncing;
    notifyListeners();

    final result = await _planningService.fetchAndCacheWeekPlanning(
      _currentMonday,
    );

    result.when(
      success: (events) {
        _weekPlanning = _planningService.groupEventsByDay(
          events,
          _currentMonday,
        );
        _state = PlanningState.loaded;
        _syncStatus = PlanningSyncStatus.synced;
        _isOffline = false;
        _lastSyncTime = DateTime.now();
        notifyListeners();
      },
      failure: (message, statusCode) {
        // Keep showing cached data, just update sync status
        _syncStatus = PlanningSyncStatus.offline;
        _isOffline = true;
        // Don't set error state since we have cached data
        notifyListeners();
      },
    );
  }

  /// Fetch data from network (used when no cache available)
  Future<void> _fetchFromNetwork() async {
    final result = await _planningService.fetchAndCacheWeekPlanning(
      _currentMonday,
    );

    result.when(
      success: (events) {
        _weekPlanning = _planningService.groupEventsByDay(
          events,
          _currentMonday,
        );
        _state = PlanningState.loaded;
        _syncStatus = PlanningSyncStatus.synced;
        _isOffline = false;
        _lastSyncTime = DateTime.now();
        notifyListeners();
      },
      failure: (message, statusCode) {
        _errorMessage = message;
        _state = PlanningState.error;
        _syncStatus = PlanningSyncStatus.offline;
        _isOffline = true;
        notifyListeners();
      },
    );
  }

  /// Initialize and prefetch extended planning (call on app start)
  Future<void> initializeWithCache() async {
    if (_hasInitializedCache) return;
    _hasInitializedCache = true;

    // Load last sync time immediately for display
    _lastSyncTime = await _planningService.getLastSyncTime();

    // Load current week first
    await loadWeekPlanning();

    // Prefetch 2 months of data in background
    _prefetchExtendedPlanning();
  }

  /// Prefetch extended planning data in background
  Future<void> _prefetchExtendedPlanning() async {
    // Don't block or show any UI for this
    await _planningService.fetchAndCacheExtendedPlanning();
    _lastSyncTime = await _planningService.getLastSyncTime();
  }

  /// Navigate to previous week
  Future<void> previousWeek() async {
    _currentMonday = _currentMonday.subtract(const Duration(days: 7));
    _selectedDayIndex = 4; // Set to Friday immediately before loading
    await loadWeekPlanning();
  }

  /// Navigate to next week
  Future<void> nextWeek() async {
    _currentMonday = _currentMonday.add(const Duration(days: 7));
    _selectedDayIndex = 0; // Set to Monday immediately before loading
    await loadWeekPlanning();
  }

  /// Navigate to current week and select today
  Future<void> goToToday() async {
    final today = DateTime.now();
    _currentMonday = date_utils.DateUtils.getMondayOfWeek(today);
    final dayDiff = today.difference(_currentMonday).inDays;
    _selectedDayIndex = (dayDiff >= 0 && dayDiff <= 4) ? dayDiff : 0;
    await loadWeekPlanning();
  }

  /// Navigate to current week
  Future<void> goToCurrentWeek() async {
    _currentMonday = date_utils.DateUtils.getMondayOfWeek(DateTime.now());
    await loadWeekPlanning();
  }

  /// Force refresh from network (ignores cache)
  Future<void> forceRefresh() async {
    _state = PlanningState.loading;
    _syncStatus = PlanningSyncStatus.syncing;
    notifyListeners();

    await _fetchFromNetwork();
  }

  /// Refresh current week data
  Future<void> refresh() async {
    await loadWeekPlanning();
  }

  /// Clear cache and reset
  Future<void> clearCache() async {
    await _planningService.clearCache();
    _hasInitializedCache = false;
  }

  /// Reset to initial state
  void reset() {
    _state = PlanningState.initial;
    _syncStatus = PlanningSyncStatus.synced;
    _weekPlanning = [];
    _currentMonday = date_utils.DateUtils.getMondayOfWeek(DateTime.now());
    _selectedDayIndex = 0;
    _errorMessage = null;
    _isOffline = false;
    _hasInitializedCache = false;
    _viewMode = PlanningViewMode.day;
    _monthEvents = {};
    notifyListeners();
  }

  // ===========================================================================
  // VIEW MODE
  // ===========================================================================

  /// Switch between day, week, and month view
  void setViewMode(PlanningViewMode mode) {
    if (_viewMode == mode) return;
    _viewMode = mode;

    if (mode == PlanningViewMode.month) {
      // Sync month to whatever week we're viewing
      _currentMonth = DateTime(_currentMonday.year, _currentMonday.month);
      loadMonthEvents();
    } else if (mode == PlanningViewMode.week || mode == PlanningViewMode.day) {
      // If coming from month view, ensure week data is in sync
      if (_state == PlanningState.loaded) {
        notifyListeners();
      }
    } else {
      notifyListeners();
    }
  }

  // ===========================================================================
  // MONTH VIEW
  // ===========================================================================

  /// Navigate to previous month
  void previousMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    loadMonthEvents();
  }

  /// Navigate to next month
  void nextMonth() {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    loadMonthEvents();
  }

  /// Go to current month
  void goToCurrentMonth() {
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    loadMonthEvents();
  }

  /// Load events for the current month — cache-first, then fetch from API
  Future<void> loadMonthEvents() async {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

    // Show cached data immediately
    final cachedEvents = await _planningService.getCachedEventsForRange(
      firstDay,
      lastDay,
    );

    _monthEvents = {};
    if (cachedEvents != null) {
      _populateMonthEvents(cachedEvents);
    }
    notifyListeners();

    // Then fetch full month from API in background to fill gaps
    _fetchMonthInBackground();
  }

  /// Fetch the full month from the API and update month events
  Future<void> _fetchMonthInBackground() async {
    final result = await _planningService.fetchAndCacheMonthPlanning(
      _currentMonth,
    );

    result.when(
      success: (events) {
        _monthEvents = {};
        _populateMonthEvents(events);
        _lastSyncTime = DateTime.now();
        notifyListeners();
      },
      failure: (message, statusCode) {
        // Keep showing cached data
      },
    );
  }

  /// Force refresh month data from API
  Future<void> refreshMonthEvents() async {
    final result = await _planningService.fetchAndCacheMonthPlanning(
      _currentMonth,
    );

    result.when(
      success: (events) {
        _monthEvents = {};
        _populateMonthEvents(events);
        _lastSyncTime = DateTime.now();
        notifyListeners();
      },
      failure: (message, statusCode) {
        // Keep existing data
      },
    );
  }

  /// Populate _monthEvents map from a list of events
  void _populateMonthEvents(List<PlanningEvent> events) {
    for (final event in events) {
      if (event.dateDebut != null && event.isValidCourse) {
        final dayKey = DateTime(
          event.dateDebut!.year,
          event.dateDebut!.month,
          event.dateDebut!.day,
        );
        _monthEvents.putIfAbsent(dayKey, () => []).add(event);
      }
    }
  }

  /// Check if a day has courses in the month view
  bool dayHasCourses(DateTime date) {
    final dayKey = DateTime(date.year, date.month, date.day);
    return _monthEvents.containsKey(dayKey) && _monthEvents[dayKey]!.isNotEmpty;
  }

  /// Get events for a specific day in the month view
  List<PlanningEvent> getEventsForDay(DateTime date) {
    final dayKey = DateTime(date.year, date.month, date.day);
    return _monthEvents[dayKey] ?? [];
  }

  /// Select a day from month/week view and switch to day view
  Future<void> selectDateFromCalendar(DateTime date) async {
    final monday = date_utils.DateUtils.getMondayOfWeek(date);
    final dayDiff = date.difference(monday).inDays;

    // Only allow weekdays
    if (dayDiff < 0 || dayDiff > 4) return;

    _currentMonday = monday;
    _selectedDayIndex = dayDiff;
    _viewMode = PlanningViewMode.day;

    await loadWeekPlanning();
  }
}
