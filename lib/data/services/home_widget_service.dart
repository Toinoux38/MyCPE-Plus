import 'dart:convert';
import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../../core/localization/app_strings.dart';
import '../../core/utils/date_utils.dart' as date_utils;
import '../models/planning_event.dart';

/// Pushes the upcoming courses to the native home screen widget.
///
/// The widget picks the day to show and the next course itself, from the
/// current time, so it stays correct for days without the app being opened.
class HomeWidgetService {
  static const String _androidWidgetName = 'WeekPlanningWidgetReceiver';
  static const String _iOSWidgetName = 'WeekPlanningWidget';
  static const String _qualifiedAndroidName =
      'com.fluffin.mycpe_plus.glance.WeekPlanningWidgetReceiver';
  static const String _appGroupId = 'group.com.fluffin.mycpeplus';

  /// How many days ahead the widget can show without the app being opened.
  static const int _daysAhead = 21;

  /// Initialize home widget (call once at app start).
  static Future<void> initialize() async {
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId(_appGroupId);
    }
  }

  /// Push the courses from today to [_daysAhead] days ahead.
  static Future<void> pushSchedule(List<PlanningEvent> allEvents) async {
    final today = date_utils.DateUtils.dateOnly(DateTime.now());
    final limit = date_utils.DateUtils.addDays(today, _daysAhead);

    final courses =
        allEvents
            .where(
              (e) =>
                  e.isValidCourse &&
                  e.dateDebut != null &&
                  e.dateFin != null &&
                  !e.dateFin!.isBefore(today) &&
                  e.dateDebut!.isBefore(limit),
            )
            .toList()
          ..sort((a, b) => a.dateDebut!.compareTo(b.dateDebut!));

    final schedule = courses
        .map(
          (e) => {
            'title': e.displayTitle,
            'time': e.timeRange,
            'room': e.salle ?? '',
            'start': e.dateDebut!.millisecondsSinceEpoch,
            'end': e.dateFin!.millisecondsSinceEpoch,
          },
        )
        .toList();

    await HomeWidget.saveWidgetData<String>('schedule', jsonEncode(schedule));
    await HomeWidget.saveWidgetData<String>(
      'last_updated',
      DateTime.now().toIso8601String(),
    );
    await _update();
  }

  /// Push the widget's texts in the app language.
  static Future<void> pushLabels(AppStrings strings) async {
    await HomeWidget.saveWidgetData<String>('label_today', strings.today);
    await HomeWidget.saveWidgetData<String>(
      'label_no_course',
      strings.noClassesScheduled,
    );
    await _update();
  }

  static Future<bool?> _update() => HomeWidget.updateWidget(
    name: _androidWidgetName,
    iOSName: _iOSWidgetName,
    qualifiedAndroidName: _qualifiedAndroidName,
  );
}
