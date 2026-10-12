import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/localization/app_locale.dart';
import '../core/localization/app_strings.dart';
import '../data/services/home_widget_service.dart';

/// Provider for application settings
class SettingsProvider extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  static const String _themeModeKey = 'theme_mode';
  
  final FlutterSecureStorage _storage;
  
  AppLocale _locale = AppLocale.french;
  AppStrings _strings = const FrenchStrings();
  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;
  
  SettingsProvider({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();
  
  AppLocale get locale => _locale;
  AppStrings get strings => _strings;
  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;
  
  /// Initialize settings from storage
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final storedLocale = await _storage.read(key: _localeKey);
      if (storedLocale != null) {
        _locale = AppLocale.fromCode(storedLocale);
        _strings = AppStrings.of(_locale);
      }
      
      final storedThemeMode = await _storage.read(key: _themeModeKey);
      if (storedThemeMode != null) {
        _themeMode = _themeModeFromString(storedThemeMode);
      }
    } catch (_) {
      // Use defaults on error
    }
    
    _isInitialized = true;
    notifyListeners();
    _pushWidgetLabels();
  }
  
  /// Change the application locale
  Future<void> setLocale(AppLocale newLocale) async {
    if (_locale == newLocale) return;
    
    _locale = newLocale;
    _strings = AppStrings.of(newLocale);
    _pushWidgetLabels();
    
    try {
      await _storage.write(key: _localeKey, value: newLocale.code);
    } catch (_) {
      // Continue even if storage fails
    }
    
    notifyListeners();
  }
  
  /// Change the theme mode
  Future<void> setThemeMode(ThemeMode newThemeMode) async {
    if (_themeMode == newThemeMode) return;
    
    _themeMode = newThemeMode;
    
    try {
      await _storage.write(key: _themeModeKey, value: _themeModeToString(newThemeMode));
    } catch (_) {
      // Continue even if storage fails
    }
    
    notifyListeners();
  }
  
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
  
  ThemeMode _themeModeFromString(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  void _pushWidgetLabels() {
    HomeWidgetService.pushLabels(_strings).catchError((_) {
      // Widget update is best-effort.
    });
  }
}
