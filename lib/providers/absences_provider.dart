import 'package:flutter/foundation.dart';
import '../core/utils/result.dart';
import '../data/models/absences_response.dart';
import '../data/services/absences_service.dart';

/// Loading state for absences data
enum AbsencesState {
  initial,
  loading,
  loaded,
  error,
}

/// Provider for absences state management
class AbsencesProvider extends ChangeNotifier {
  final AbsencesService _absencesService;

  AbsencesState _state = AbsencesState.initial;
  String? _errorMessage;
  AbsencesResponse? _absencesData;
  bool _isSyncing = false;
  DateTime? _lastUpdated;
  // Bumped on reset() so a response arriving after logout is dropped.
  int _generation = 0;

  AbsencesProvider({required AbsencesService absencesService})
      : _absencesService = absencesService;

  AbsencesState get state => _state;
  String? get errorMessage => _errorMessage;
  AbsencesResponse? get absencesData => _absencesData;
  bool get isLoading => _state == AbsencesState.loading;
  bool get isSyncing => _isSyncing;
  DateTime? get lastUpdated => _lastUpdated;

  /// Showing cached absences because the last refresh failed.
  bool get isOffline => _state == AbsencesState.loaded && _errorMessage != null;

  /// Get total absences count
  int get totalAbsences =>
      (_absencesData?.nbrTotalAbsenceExcuser ?? 0) +
      (_absencesData?.nbrTotalAbsenceNonExcuser ?? 0);

  /// Get excused absences count
  int get excusedAbsencesCount => _absencesData?.nbrTotalAbsenceExcuser ?? 0;

  /// Get unexcused absences count
  int get unexcusedAbsencesCount =>
      _absencesData?.nbrTotalAbsenceNonExcuser ?? 0;

  /// Get list of absences
  List<Absence> get absences => _absencesData?.absences ?? [];

  /// First load: cached absences right away, then a refresh from the API.
  Future<void> loadAbsences() async {
    if (_state == AbsencesState.initial) {
      final generation = _generation;
      _state = AbsencesState.loading;
      notifyListeners();
      final cached = await _absencesService.getCachedAbsences();
      if (generation != _generation) return;
      if (cached != null) {
        _absencesData = cached.$1;
        _lastUpdated = cached.$2;
        _state = AbsencesState.loaded;
        notifyListeners();
      }
    }
    await refresh();
  }

  /// Fetch from the API, keeping the current absences on screen meanwhile.
  Future<void> refresh() async {
    if (_isSyncing) return;
    final generation = _generation;
    _isSyncing = true;
    notifyListeners();

    final result = await _absencesService.fetchAbsences();
    if (generation != _generation) return;
    _isSyncing = false;

    switch (result) {
      case Success(:final data):
        _absencesData = data;
        _lastUpdated = DateTime.now();
        _errorMessage = null;
        _state = AbsencesState.loaded;
      case Failure(:final message):
        _errorMessage = message;
        if (_state != AbsencesState.loaded) _state = AbsencesState.error;
    }
    notifyListeners();
  }

  /// Reset to initial state and forget the cached absences (logout).
  void reset() {
    _generation++;
    _state = AbsencesState.initial;
    _absencesData = null;
    _errorMessage = null;
    _isSyncing = false;
    _lastUpdated = null;
    _absencesService.clearCache();
    notifyListeners();
  }
}
