import 'package:flutter/foundation.dart';
import '../core/utils/result.dart';
import '../data/models/course_grades.dart';
import '../data/services/grades_service.dart';

/// Loading state for grades data
enum GradesState {
  initial,
  loading,
  loaded,
  error,
}

/// Provider for grades state management
class GradesProvider extends ChangeNotifier {
  final GradesService _gradesService;
  
  GradesState _state = GradesState.initial;
  String? _errorMessage;
  List<CourseGrades> _courses = [];
  String? _expandedCourseId;
  bool _isSyncing = false;
  DateTime? _lastUpdated;
  // Bumped on reset() so a response arriving after logout is dropped.
  int _generation = 0;

  GradesProvider({required GradesService gradesService})
    : _gradesService = gradesService;

  GradesState get state => _state;
  String? get errorMessage => _errorMessage;
  List<CourseGrades> get courses => _courses;
  String? get expandedCourseId => _expandedCourseId;
  bool get isLoading => _state == GradesState.loading;
  bool get isSyncing => _isSyncing;
  DateTime? get lastUpdated => _lastUpdated;

  /// Showing cached grades because the last refresh failed.
  bool get isOffline => _state == GradesState.loaded && _errorMessage != null;

  /// Get overall average across all courses
  double? get overallAverage {
    final coursesWithGrades = _courses.where((c) => c.averageGrade != null).toList();
    if (coursesWithGrades.isEmpty) return null;
    
    final sum = coursesWithGrades.fold<double>(0, (prev, c) => prev + c.averageGrade!);
    return sum / coursesWithGrades.length;
  }
  
  /// Get total graded exams count
  int get totalGradedExams => 
      _courses.fold<int>(0, (prev, c) => prev + c.gradedExamsCount);
  
  /// Get total courses count
  int get totalCourses => _courses.length;
  
  /// First load: cached grades right away, then a refresh from the API.
  Future<void> loadGrades() async {
    if (_state == GradesState.initial) {
      final generation = _generation;
      _state = GradesState.loading;
      notifyListeners();
      final cached = await _gradesService.getCachedGrades();
      if (generation != _generation) return;
      if (cached != null) {
        _courses = cached.$1;
        _lastUpdated = cached.$2;
        _state = GradesState.loaded;
        notifyListeners();
      }
    }
    await refresh();
  }

  /// Toggle course expansion
  void toggleCourseExpansion(String courseId) {
    if (_expandedCourseId == courseId) {
      _expandedCourseId = null;
    } else {
      _expandedCourseId = courseId;
    }
    notifyListeners();
  }
  
  /// Fetch from the API, keeping the current grades on screen meanwhile.
  Future<void> refresh() async {
    if (_isSyncing) return;
    final generation = _generation;
    _isSyncing = true;
    notifyListeners();

    final result = await _gradesService.getGrades();
    if (generation != _generation) return;
    _isSyncing = false;

    switch (result) {
      case Success(data: final courses):
        _courses = courses;
        _lastUpdated = DateTime.now();
        _errorMessage = null;
        _state = GradesState.loaded;
      case Failure(:final message):
        _errorMessage = message;
        if (_state != GradesState.loaded) _state = GradesState.error;
    }
    notifyListeners();
  }

  /// Reset to initial state and forget the cached grades (logout).
  void reset() {
    _generation++;
    _state = GradesState.initial;
    _courses = [];
    _expandedCourseId = null;
    _errorMessage = null;
    _isSyncing = false;
    _lastUpdated = null;
    _gradesService.clearCache();
    notifyListeners();
  }
}
