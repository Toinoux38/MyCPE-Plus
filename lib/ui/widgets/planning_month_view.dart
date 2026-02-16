import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart' as date_utils;
import '../../providers/planning_provider.dart';

/// Month calendar view showing a gradient dot for days with courses.
class PlanningMonthView extends StatefulWidget {
  final PlanningProvider planning;
  final dynamic strings;

  const PlanningMonthView({
    super.key,
    required this.planning,
    required this.strings,
  });

  @override
  State<PlanningMonthView> createState() => _PlanningMonthViewState();
}

class _PlanningMonthViewState extends State<PlanningMonthView> {
  double _dragDistance = 0;
  bool _isProcessingSwipe = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textSecondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    final month = widget.planning.currentMonth;
    final monthLabel = date_utils.DateUtils.formatMonthYear(month);

    return GestureDetector(
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
            widget.planning.previousMonth();
          } else {
            widget.planning.nextMonth();
          }
        }
        _dragDistance = 0;
      },
      child: Column(
        children: [
          // Month navigation header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: widget.planning.previousMonth,
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
                  monthLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimaryColor,
                  ),
                ),
                GestureDetector(
                  onTap: widget.planning.nextMonth,
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
          // Weekday headers
          _WeekdayHeaders(strings: widget.strings),
          const SizedBox(height: 4),
          // Calendar grid with pull-to-refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: widget.planning.refreshMonthEvents,
              color: AppColors.gradientStart,
              child: _MonthGrid(month: month, planning: widget.planning),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeaders extends StatelessWidget {
  final dynamic strings;

  const _WeekdayHeaders({required this.strings});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    // Mon-Sun single letters matching existing day selector style
    final dayLetters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: dayLetters.map((letter) {
          return SizedBox(
            width: 40,
            child: Center(
              child: Text(
                letter,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textSecondaryColor,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final PlanningProvider planning;

  const _MonthGrid({required this.month, required this.planning});

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    // Monday = 1, so offset is (weekday - 1) to align Monday as first column
    final startOffset = (firstDayOfMonth.weekday - 1) % 7;

    final totalDays = lastDayOfMonth.day;
    final totalCells = startOffset + totalDays;
    final rows = (totalCells / 7).ceil();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: rows,
      itemBuilder: (context, rowIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (colIndex) {
              final cellIndex = rowIndex * 7 + colIndex;
              final dayNumber = cellIndex - startOffset + 1;

              if (dayNumber < 1 || dayNumber > totalDays) {
                return const SizedBox(width: 40, height: 48);
              }

              final date = DateTime(month.year, month.month, dayNumber);
              final hasCourses = planning.dayHasCourses(date);
              final isToday = date_utils.DateUtils.isSameDay(
                date,
                DateTime.now(),
              );
              final isWeekend = date.weekday == 6 || date.weekday == 7;

              return _MonthDayCell(
                dayNumber: dayNumber,
                hasCourses: hasCourses,
                isToday: isToday,
                isWeekend: isWeekend,
                onTap: isWeekend
                    ? null
                    : () => planning.selectDateFromCalendar(date),
              );
            }),
          ),
        );
      },
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  final int dayNumber;
  final bool hasCourses;
  final bool isToday;
  final bool isWeekend;
  final VoidCallback? onTap;

  const _MonthDayCell({
    required this.dayNumber,
    required this.hasCourses,
    required this.isToday,
    required this.isWeekend,
    this.onTap,
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

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Day number
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
                dayNumber.toString(),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                  color: isToday
                      ? Colors.white
                      : isWeekend
                      ? textSecondaryColor.withOpacity(0.4)
                      : textPrimaryColor,
                ),
              ),
            ),
            const SizedBox(height: 2),
            // Course indicator dot
            if (hasCourses)
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
