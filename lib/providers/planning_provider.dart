import 'package:flutter/widgets.dart';
import '../core/utils/date_utils.dart' as date_utils;
import '../core/utils/result.dart';
import '../data/models/planning_event.dart';
import '../data/services/home_widget_service.dart';
import '../data/services/planning_service.dart';

typedef _Du = date_utils.DateUtils;

/// View mode for the planning screen
enum PlanningViewMode { day, week, month }

/// Provider for planning/schedule state management.
///
/// All views read the same per-day data from [PlanningService]: navigation is
/// instant and synchronous, cached days are shown right away, and network
/// refreshes happen in the background and only notify when something changed.
class PlanningProvider extends ChangeNotifier with WidgetsBindingObserver {
  /// Visible data older than this is silently refreshed.
  static const Duration _staleAfter = Duration(minutes: 15);

  final PlanningService _planningService;

  bool _initialized = false;
  bool _cacheLoaded = false;
  PlanningViewMode _viewMode = PlanningViewMode.day;
  late DateTime _selectedDate;
  late DateTime _focusedMonth;
  final List<(DateTime, DateTime)> _pendingRanges = [];
  String? _errorMessage;

  PlanningProvider({required PlanningService planningService})
    : _planningService = planningService {
    _resetSelection();
  }

  void _resetSelection() {
    final today = _Du.dateOnly(DateTime.now());
    // On weekends, start on the upcoming Monday.
    _selectedDate = _Du.isWeekend(today)
        ? _Du.addDays(_Du.getMondayOfWeek(today), 7)
        : today;
    _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  // ===========================================================================
  // STATE
  // ===========================================================================

  /// False until the local cache has been read.
  bool get isReady => _cacheLoaded;
  PlanningViewMode get viewMode => _viewMode;
  DateTime get selectedDate => _selectedDate;
  DateTime get currentMonday => _Du.getMondayOfWeek(_selectedDate);
  DateTime get currentMonth => _focusedMonth;
  bool get isToday => _Du.isSameDay(_selectedDate, DateTime.now());

  /// A request for the visible range is running.
  bool get isSyncing => _pendingRanges.any((r) => _overlapsVisible(r));

  /// Last network error, cleared on the next successful sync.
  String? get errorMessage => _errorMessage;
  bool get isOffline => _errorMessage != null;
  DateTime? get lastSyncTime => _planningService.lastSyncTime;

  /// Days shown for the current week: Monday to Friday, plus Saturday and
  /// Sunday when they have courses.
  List<DateTime> get weekDays => daysOfWeek(currentMonday);

  List<DateTime> daysOfWeek(DateTime monday) => [
    for (var i = 0; i < 7; i++)
      if (i < 5 || dayHasCourses(_Du.addDays(monday, i)))
        _Du.addDays(monday, i),
  ];

  /// Index of [selectedDate] in [weekDays].
  int get selectedDayIndex {
    final index = weekDays.indexWhere((d) => _Du.isSameDay(d, _selectedDate));
    return index < 0 ? 0 : index;
  }

  bool isDayLoaded(DateTime day) => _planningService.isDayLoaded(day);

  /// Valid courses (no breaks / empty slots) of [day], sorted.
  List<PlanningEvent> coursesForDay(DateTime day) => _planningService
      .eventsForDay(day)
      .where((e) => e.isValidCourse)
      .toList();

  bool dayHasCourses(DateTime day) =>
      _planningService.eventsForDay(day).any((e) => e.isValidCourse);

  DayPlanning dayPlanning(DateTime day) => DayPlanning(
    date: _Du.dateOnly(day),
    events: _planningService.eventsForDay(day),
  );

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  /// Load the cache, then sync in the background. Safe to call repeatedly.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);

    await _planningService.loadCache();
    _cacheLoaded = true;
    notifyListeners();
    _pushToHomeWidget();

    // One request for the coming weeks, then whatever is visible if needed.
    final monday = _Du.getMondayOfWeek(DateTime.now());
    _syncRange(_Du.addDays(monday, -7), _Du.addDays(monday, 62));
    _syncVisible();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _cacheLoaded) {
      _syncVisible();
    }
  }

  /// Forget the user's data (logout).
  Future<void> reset() async {
    if (_initialized) WidgetsBinding.instance.removeObserver(this);
    _initialized = false;
    _cacheLoaded = false;
    _viewMode = PlanningViewMode.day;
    _pendingRanges.clear();
    _errorMessage = null;
    _resetSelection();
    await _planningService.clearCache();
    HomeWidgetService.pushSchedule(const []).catchError((_) {});
    notifyListeners();
  }

  @override
  void dispose() {
    if (_initialized) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ===========================================================================
  // NAVIGATION
  // ===========================================================================

  void selectDate(DateTime date) {
    final day = _Du.dateOnly(date);
    if (_Du.isSameDay(day, _selectedDate)) return;
    final weekChanged = !_Du.isSameDay(
      _Du.getMondayOfWeek(day),
      currentMonday,
    );
    _selectedDate = day;
    notifyListeners();
    if (weekChanged) _syncVisible();
  }

  /// Go to the next week, on Monday.
  void nextWeek() => selectDate(_Du.addDays(currentMonday, 7));

  /// Go to the previous week, on Friday.
  void previousWeek() => selectDate(_Du.addDays(currentMonday, -3));

  /// Show today (or the upcoming Monday on weekends) in the current view.
  void goToToday() {
    _resetSelection();
    notifyListeners();
    _syncVisible();
  }

  void setViewMode(PlanningViewMode mode) {
    if (_viewMode == mode) return;
    _viewMode = mode;
    if (mode == PlanningViewMode.month) {
      _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);
    }
    notifyListeners();
    _syncVisible();
  }

  void previousMonth() => _setMonth(-1);
  void nextMonth() => _setMonth(1);

  void goToCurrentMonth() {
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month);
    notifyListeners();
    _syncVisible();
  }

  void _setMonth(int delta) {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
    notifyListeners();
    _syncVisible();
  }

  /// Open [date] in the day view (from the week or month view).
  void openDay(DateTime date) {
    _selectedDate = _Du.dateOnly(date);
    _viewMode = PlanningViewMode.day;
    notifyListeners();
    _syncVisible();
  }

  // ===========================================================================
  // SYNC
  // ===========================================================================

  /// Pull-to-refresh: refetch the visible range, completes when done.
  Future<void> refresh() {
    final (start, end) = _visibleRange;
    return _syncRange(start, end);
  }

  (DateTime, DateTime) get _visibleRange {
    if (_viewMode == PlanningViewMode.month) {
      return (
        _focusedMonth,
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0),
      );
    }
    return (currentMonday, _Du.addDays(currentMonday, 6));
  }

  bool _overlapsVisible((DateTime, DateTime) range) {
    final (start, end) = _visibleRange;
    return !range.$1.isAfter(end) && !range.$2.isBefore(start);
  }

  /// Fetch the visible range if it is missing or stale.
  void _syncVisible() {
    final (start, end) = _visibleRange;
    final alreadyPending = _pendingRanges.any(
      (r) => !r.$1.isAfter(start) && !r.$2.isBefore(end),
    );
    if (alreadyPending) return;

    final fetchedAt = _planningService.rangeFetchedAt(start, end);
    if (fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < _staleAfter) {
      return;
    }
    _syncRange(start, end);
  }

  Future<void> _syncRange(DateTime start, DateTime end) async {
    final range = (start, end);
    _pendingRanges.add(range);
    if (_overlapsVisible(range)) notifyListeners();

    final result = await _planningService.fetchRange(start, end);
    if (!_pendingRanges.remove(range)) return; // reset() happened meanwhile

    switch (result) {
      case Success(data: final changed):
        final hadError = _errorMessage != null;
        _errorMessage = null;
        if (changed) _pushToHomeWidget();
        if (changed || hadError || _overlapsVisible(range)) notifyListeners();
      case Failure(:final message):
        _errorMessage = message;
        notifyListeners();
    }
  }

  void _pushToHomeWidget() {
    final events = _planningService.allEvents;
    if (events.isEmpty) return;
    HomeWidgetService.pushSchedule(events).catchError((_) {
      // Widget update is best-effort.
    });
  }
}
