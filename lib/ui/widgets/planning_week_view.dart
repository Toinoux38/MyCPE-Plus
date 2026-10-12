import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/utils/date_utils.dart' as date_utils;
import '../../data/models/planning_event.dart';
import '../../providers/planning_provider.dart';
import 'state_views.dart';

/// Week view showing Monday-Friday (plus weekend days with courses).
class PlanningWeekView extends StatefulWidget {
  final PlanningProvider planning;
  final AppStrings strings;
  final String locale;

  const PlanningWeekView({
    super.key,
    required this.planning,
    required this.strings,
    required this.locale,
  });

  @override
  State<PlanningWeekView> createState() => _PlanningWeekViewState();
}

class _PlanningWeekViewState extends State<PlanningWeekView> {
  double _dragDistance = 0;

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() > 500 || _dragDistance.abs() > 80) {
      if (_dragDistance > 0) {
        widget.planning.previousWeek();
      } else {
        widget.planning.nextWeek();
      }
    }
    _dragDistance = 0;
  }

  @override
  Widget build(BuildContext context) {
    final planning = widget.planning;
    final strings = widget.strings;
    final textPrimaryColor = context.textPrimaryColor;
    final textSecondaryColor = context.textSecondaryColor;

    final days = planning.weekDays;
    final anyLoaded = days.any(planning.isDayLoaded);

    final Widget content;
    if (!anyLoaded) {
      content = planning.isOffline
          ? ErrorView(
              message: planning.errorMessage ?? strings.noScheduleAvailable,
              onRetry: planning.refresh,
              retryLabel: strings.retry,
            )
          : LoadingIndicator(message: strings.loadingSchedule);
    } else if (!days.any(planning.dayHasCourses)) {
      content = RefreshIndicator(
        onRefresh: planning.refresh,
        color: AppColors.gradientStart,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: _EmptyWeek(strings: strings),
            ),
          ),
        ),
      );
    } else {
      content = RefreshIndicator(
        onRefresh: planning.refresh,
        color: AppColors.gradientStart,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            return _WeekDayRow(
              dayPlanning: planning.dayPlanning(day),
              isLoaded: planning.isDayLoaded(day),
              strings: strings,
              onDayTap: () => planning.openDay(day),
            );
          },
        ),
      );
    }

    return Column(
      children: [
        // Week navigation header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: planning.previousWeek,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Iconsax.arrow_left_2,
                    size: 20,
                    color: textSecondaryColor,
                  ),
                ),
              ),
              Text(
                date_utils.DateUtils.getWeekRangeString(
                  planning.currentMonday,
                  locale: widget.locale,
                ),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimaryColor,
                ),
              ),
              GestureDetector(
                onTap: planning.nextWeek,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Iconsax.arrow_right_3,
                    size: 20,
                    color: textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GestureDetector(
            onHorizontalDragStart: (_) => _dragDistance = 0,
            onHorizontalDragUpdate: (details) =>
                _dragDistance += details.delta.dx,
            onHorizontalDragEnd: _onDragEnd,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(planning.currentMonday),
                child: content,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyWeek extends StatelessWidget {
  final AppStrings strings;

  const _EmptyWeek({required this.strings});

  @override
  Widget build(BuildContext context) {
    final textSecondaryColor = context.textSecondaryColor;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.calendar_1,
            size: 64,
            color: textSecondaryColor.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            strings.noClassesScheduled,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekDayRow extends StatelessWidget {
  final DayPlanning dayPlanning;
  final bool isLoaded;
  final AppStrings strings;
  final VoidCallback onDayTap;

  const _WeekDayRow({
    required this.dayPlanning,
    required this.isLoaded,
    required this.strings,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimaryColor = context.textPrimaryColor;
    final textSecondaryColor = context.textSecondaryColor;
    final surfaceVariantColor = context.surfaceVariantColor;

    final isToday = date_utils.DateUtils.isSameDay(
      dayPlanning.date,
      DateTime.now(),
    );
    final dayLetter = _getDayLetter(dayPlanning.date.weekday);
    final dayNumber = dayPlanning.date.day.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onDayTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day label column
            SizedBox(
              width: 48,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  children: [
                    Text(
                      dayLetter,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isToday
                            ? AppColors.gradientStart
                            : textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: isToday
                          ? BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.gradientStart,
                                  AppColors.gradientEnd,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            )
                          : null,
                      alignment: Alignment.center,
                      child: Text(
                        dayNumber,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isToday ? Colors.white : textPrimaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Course chips
            Expanded(
              child: dayPlanning.hasCourses
                  ? Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surfaceVariantColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: dayPlanning.courses
                            .map(
                              (event) => _WeekCourseChip(
                                event: event,
                                isLast: event == dayPlanning.courses.last,
                              ),
                            )
                            .toList(),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        isLoaded ? strings.noClassesScheduled : '…',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondaryColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDayLetter(int weekday) {
    const letters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return letters[weekday - 1];
  }
}

class _WeekCourseChip extends StatelessWidget {
  final PlanningEvent event;
  final bool isLast;

  const _WeekCourseChip({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final textPrimaryColor = context.textPrimaryColor;
    final textSecondaryColor = context.textSecondaryColor;

    final isOngoing = event.isOngoing;
    final isPast = event.isPast;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        children: [
          // Time indicator bar
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              gradient: isOngoing
                  ? const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null,
              color: isOngoing
                  ? null
                  : isPast
                  ? textSecondaryColor.withValues(alpha: 0.2)
                  : AppColors.gradientStart.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          // Course info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.displayTitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isPast ? textSecondaryColor : textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  event.timeRange,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          // Room badge
          if (event.salle != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (context.surfaceColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                event.salle!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: textSecondaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
