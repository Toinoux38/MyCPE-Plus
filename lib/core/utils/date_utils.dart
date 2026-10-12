import 'package:intl/intl.dart';

/// Date utility functions.
///
/// Day arithmetic always goes through [addDays] (calendar days), never
/// `Duration(days: n)`: adding 24h slots breaks across daylight-saving
/// changes (e.g. Monday 00:00 + 7 days = Sunday 23:00 in late October).
abstract final class DateUtils {
  /// Strip the time part.
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Add [days] calendar days (DST-safe), result at midnight.
  static DateTime addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  /// Get the Monday of the week containing [date].
  static DateTime getMondayOfWeek(DateTime date) =>
      DateTime(date.year, date.month, date.day - (date.weekday - 1));

  /// Get the Friday of the week containing [date].
  static DateTime getFridayOfWeek(DateTime date) =>
      addDays(getMondayOfWeek(date), 4);

  /// Every day from [start] to [end], both inclusive.
  static Iterable<DateTime> daysInRange(DateTime start, DateTime end) sync* {
    for (var d = dateOnly(start); !d.isAfter(end); d = addDays(d, 1)) {
      yield d;
    }
  }

  static bool isWeekend(DateTime date) =>
      date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

  /// Intl locale tag for an app language code ('fr' -> 'fr_FR').
  static String localeTag(String languageCode) =>
      languageCode == 'fr' ? 'fr_FR' : 'en_US';

  /// Format date for API requests (yyyy-MM-dd)
  static String formatForApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Format date for display (dd/MM/yyyy)
  static String formatForDisplay(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Format time for display (HH:mm)
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Format day name (Lundi, Monday, ...)
  static String formatDayName(DateTime date, {String locale = 'en_US'}) {
    return _capitalize(DateFormat('EEEE', locale).format(date));
  }

  /// Format month and day (e.g. "28 janv." / "Jan 28")
  static String formatMonthDay(DateTime date, {String locale = 'en_US'}) {
    final pattern = locale.startsWith('fr') ? 'd MMM' : 'MMM d';
    return DateFormat(pattern, locale).format(date);
  }

  /// Format month and year (e.g. "Janvier 2026")
  static String formatMonthYear(DateTime date, {String locale = 'en_US'}) {
    return _capitalize(DateFormat('MMMM yyyy', locale).format(date));
  }

  /// Parse API date format. Always returns local time.
  static DateTime? parseApiDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    return DateTime.tryParse(dateString)?.toLocal();
  }

  /// Check if two dates are the same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Get week range string (e.g. "27 janv. - 31 janv.")
  static String getWeekRangeString(DateTime monday, {String locale = 'en_US'}) {
    final friday = addDays(monday, 4);
    return '${formatMonthDay(monday, locale: locale)} - '
        '${formatMonthDay(friday, locale: locale)}';
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
