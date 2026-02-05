import 'package:flutter/foundation.dart';
import '../core/utils/date_utils.dart' as date_utils;
import '../data/models/planning_event.dart';
import '../data/services/planning_service.dart';

/// Loading state for planning data
enum PlanningState { initial, loading, loaded, error }

/// Provider for planning/schedule state management
class PlanningProvider extends ChangeNotifier {
  final PlanningService _planningService;

  PlanningState _state = PlanningState.initial;
  String? _errorMessage;
  List<DayPlanning> _weekPlanning = [];
  DateTime _currentMonday = date_utils.DateUtils.getMondayOfWeek(
    DateTime.now(),
  );
  int _selectedDayIndex = 0; // 0 = Monday, 4 = Friday

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
  String? get errorMessage => _errorMessage;
  List<DayPlanning> get weekPlanning => _weekPlanning;
  DateTime get currentMonday => _currentMonday;
  bool get isLoading => _state == PlanningState.loading;
  int get selectedDayIndex => _selectedDayIndex;

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

  /// Load planning for current week view
  Future<void> loadWeekPlanning() async {
    _state = PlanningState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _planningService.getWeekPlanning(_currentMonday);

    result.when(
      success: (events) {
        _weekPlanning = _planningService.groupEventsByDay(
          events,
          _currentMonday,
        );
        _state = PlanningState.loaded;
        notifyListeners();
      },
      failure: (message, statusCode) {
        _errorMessage = message;
        _state = PlanningState.error;
        notifyListeners();
      },
    );
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

  /// Refresh current week data
  Future<void> refresh() async {
    await loadWeekPlanning();
  }

  /// Reset to initial state
  void reset() {
    _state = PlanningState.initial;
    _weekPlanning = [];
    _currentMonday = date_utils.DateUtils.getMondayOfWeek(DateTime.now());
    _selectedDayIndex = 0;
    _errorMessage = null;
    notifyListeners();
  }
}
