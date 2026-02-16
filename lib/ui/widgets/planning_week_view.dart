import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart' as date_utils;
import '../../data/models/planning_event.dart';
import '../../providers/planning_provider.dart';

/// Week view showing Monday-Friday with course cards for each day.
class PlanningWeekView extends StatefulWidget {
  final PlanningProvider planning;
  final dynamic strings;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  const PlanningWeekView({
    super.key,
    required this.planning,
    required this.strings,
    required this.onPreviousWeek,
    required this.onNextWeek,
  });

  @override
  State<PlanningWeekView> createState() => _PlanningWeekViewState();
}

class _PlanningWeekViewState extends State<PlanningWeekView> {
  double _dragDistance = 0;
  bool _isProcessingSwipe = false;

  @override
  Widget build(BuildContext context) {
    if (widget.planning.state == PlanningState.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textSecondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    final weekRange = widget.planning.weekRangeString;

    return Column(
      children: [
        // Week navigation header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: widget.onPreviousWeek,
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
                weekRange,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textPrimaryColor,
                ),
              ),
              GestureDetector(
                onTap: widget.onNextWeek,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Iconsax.arrow_right,
                    size: 20,
                    color: textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Week days list
        Expanded(
          child: widget.planning.weekPlanning.isEmpty
              ? _EmptyWeek(strings: widget.strings)
              : GestureDetector(
                  onHorizontalDragStart: (_) {
                    _dragDistance = 0;
                    _isProcessingSwipe = false;
                  },
                  onHorizontalDragUpdate: (details) {
                    if (_isProcessingSwipe) return;
                    _dragDistance += details.delta.dx;
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isProcessingSwipe) return;
                    final velocity = details.primaryVelocity ?? 0;
                    final hasSignificantVelocity = velocity.abs() > 500;
                    final hasSignificantDistance = _dragDistance.abs() > 80;

                    if (hasSignificantVelocity || hasSignificantDistance) {
                      _isProcessingSwipe = true;
                      if (_dragDistance > 0) {
                        widget.onPreviousWeek();
                      } else {
                        widget.onNextWeek();
                      }
                    }
                    _dragDistance = 0;
                  },
                  child: RefreshIndicator(
                    onRefresh: widget.planning.refresh,
                    color: AppColors.gradientStart,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: widget.planning.weekPlanning.length,
                      itemBuilder: (context, index) {
                        final dayPlanning = widget.planning.weekPlanning[index];
                        return _WeekDayRow(
                          dayPlanning: dayPlanning,
                          strings: widget.strings,
                          onDayTap: () => widget.planning
                              .selectDateFromCalendar(dayPlanning.date),
                        );
                      },
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

class _EmptyWeek extends StatelessWidget {
  final dynamic strings;

  const _EmptyWeek({required this.strings});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.calendar_1,
            size: 64,
            color: textSecondaryColor.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            strings.noClassesScheduled,
            style: GoogleFonts.poppins(
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
  final dynamic strings;
  final VoidCallback onDayTap;

  const _WeekDayRow({
    required this.dayPlanning,
    required this.strings,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textSecondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final surfaceVariantColor = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariant;

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
                      style: GoogleFonts.poppins(
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
                        style: GoogleFonts.poppins(
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
                        strings.noClassesScheduled,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: textSecondaryColor.withOpacity(0.6),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textSecondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

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
                  ? textSecondaryColor.withOpacity(0.2)
                  : AppColors.gradientStart.withOpacity(0.4),
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
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isPast ? textSecondaryColor : textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  event.timeRange,
                  style: GoogleFonts.poppins(
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
                color: (isDark ? AppColors.surfaceDark : AppColors.surface),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                event.salle!,
                style: GoogleFonts.poppins(
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
