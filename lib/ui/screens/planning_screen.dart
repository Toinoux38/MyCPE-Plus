import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart' as date_utils;
import '../../data/models/planning_event.dart';
import '../../providers/planning_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/planning_month_view.dart';
import '../widgets/planning_week_view.dart';
import '../widgets/state_views.dart';
import '../widgets/sync_status_footer.dart';

/// Planning screen: day, week and month views.
class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PlanningProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlanningProvider, SettingsProvider>(
      builder: (context, planning, settings, _) {
        final backgroundColor = context.backgroundColor;
        final locale = date_utils.DateUtils.localeTag(settings.locale.code);
        final isMonth = planning.viewMode == PlanningViewMode.month;
        final now = DateTime.now();
        final showsToday = isMonth
            ? planning.currentMonth.year == now.year &&
                  planning.currentMonth.month == now.month
            : planning.isToday;

        return Container(
          color: backgroundColor,
          child: SafeArea(
            child: Column(
              children: [
                _DateHeader(
                  selectedDate: planning.selectedDate,
                  isToday: showsToday,
                  onTodayTap: planning.goToToday,
                  strings: settings.strings,
                  viewMode: planning.viewMode,
                  currentMonth: planning.currentMonth,
                  locale: locale,
                ),
                _ViewModeToggle(
                  viewMode: planning.viewMode,
                  onChanged: planning.setViewMode,
                  strings: settings.strings,
                ),
                Expanded(
                  child: _MainCard(
                    planning: planning,
                    strings: settings.strings,
                    locale: locale,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// DATE HEADER
// =============================================================================

class _DateHeader extends StatelessWidget {
  final DateTime selectedDate;
  final bool isToday;
  final VoidCallback onTodayTap;
  final AppStrings strings;
  final PlanningViewMode viewMode;
  final DateTime currentMonth;
  final String locale;

  const _DateHeader({
    required this.selectedDate,
    required this.isToday,
    required this.onTodayTap,
    required this.strings,
    required this.viewMode,
    required this.currentMonth,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          if (viewMode == PlanningViewMode.month)
            _MonthHeaderDisplay(month: currentMonth, locale: locale)
          else
            _DateDisplay(selectedDate: selectedDate, locale: locale),
          const Spacer(),
          _TodayButton(
            label: strings.today,
            isToday: isToday,
            onTap: onTodayTap,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// VIEW MODE TOGGLE
// =============================================================================

class _ViewModeToggle extends StatelessWidget {
  final PlanningViewMode viewMode;
  final ValueChanged<PlanningViewMode> onChanged;
  final AppStrings strings;

  const _ViewModeToggle({
    required this.viewMode,
    required this.onChanged,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final backgroundColor = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.divider.withValues(alpha: 0.5);

    final modes = [
      (PlanningViewMode.day, strings.dayView),
      (PlanningViewMode.week, strings.weekView),
      (PlanningViewMode.month, strings.monthView),
    ];

    final selectedIndex = modes.indexWhere((e) => e.$1 == viewMode);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Container(
        height: 36,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / modes.length;

            return Stack(
              children: [
                // Animated sliding indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  left: selectedIndex * tabWidth,
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientEnd,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gradientStart.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tab labels
                Row(
                  children: modes.map((entry) {
                    final (mode, label) = entry;
                    final isSelected = viewMode == mode;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => onChanged(mode),
                        behavior: HitTestBehavior.opaque,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            // Replaces (not merges) the default text style.
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (context.textSecondaryColor),
                            ),
                            child: Text(label),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// =============================================================================
// MONTH HEADER DISPLAY
// =============================================================================

class _MonthHeaderDisplay extends StatelessWidget {
  final DateTime month;
  final String locale;

  const _MonthHeaderDisplay({required this.month, required this.locale});

  @override
  Widget build(BuildContext context) {
    final textPrimaryColor = context.textPrimaryColor;

    final monthName = date_utils.DateUtils.formatMonthYear(
      month,
      locale: locale,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          monthName,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: textPrimaryColor,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _DateDisplay extends StatelessWidget {
  final DateTime selectedDate;
  final String locale;

  const _DateDisplay({required this.selectedDate, required this.locale});

  @override
  Widget build(BuildContext context) {
    final textPrimaryColor = context.textPrimaryColor;
    final textSecondaryColor = context.textSecondaryColor;

    final dayNumber = selectedDate.day.toString();
    final dayName = date_utils.DateUtils.formatDayName(
      selectedDate,
      locale: locale,
    );
    final monthYear = date_utils.DateUtils.formatMonthYear(
      selectedDate,
      locale: locale,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dayNumber,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w600,
            color: textPrimaryColor,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              dayName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textSecondaryColor,
              ),
            ),
            Text(
              monthYear,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: textSecondaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TodayButton extends StatelessWidget {
  final String label;
  final bool isToday;
  final VoidCallback onTap;

  const _TodayButton({
    required this.label,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: isToday ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: isToday
                ? const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            borderRadius: BorderRadius.circular(20),
            border: isToday
                ? null
                : Border.all(color: AppColors.gradientStart, width: 1.5),
          ),
          child: ShaderMask(
            shaderCallback: isToday
                ? (bounds) => const LinearGradient(
                    colors: [Colors.white, Colors.white],
                  ).createShader(bounds)
                : (bounds) => const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// MAIN CARD
// =============================================================================

class _MainCard extends StatelessWidget {
  final PlanningProvider planning;
  final AppStrings strings;
  final String locale;

  const _MainCard({
    required this.planning,
    required this.strings,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = context.surfaceColor;
    final dividerColor = context.dividerColor;
    // Account for floating navigation bar
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final navBarSpace = 56 + (bottomPadding > 0 ? bottomPadding : 16);

    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, navBarSpace.toDouble()),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            if (planning.viewMode == PlanningViewMode.day) ...[
              _DaySelector(planning: planning),
              Divider(height: 1, color: dividerColor),
            ],
            Expanded(child: _buildContent()),
            SyncStatusFooter(
              isSyncing: planning.isSyncing,
              isOffline: planning.isOffline,
              lastSync: planning.lastSyncTime,
              strings: strings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (!planning.isReady) {
      return LoadingIndicator(message: strings.loadingSchedule);
    }
    switch (planning.viewMode) {
      case PlanningViewMode.month:
        return PlanningMonthView(
          planning: planning,
          strings: strings,
          locale: locale,
        );
      case PlanningViewMode.week:
        return PlanningWeekView(
          planning: planning,
          strings: strings,
          locale: locale,
        );
      case PlanningViewMode.day:
        return _DayPager(
          key: ValueKey(planning.currentMonday),
          planning: planning,
          strings: strings,
        );
    }
  }
}

// =============================================================================
// DAY SELECTOR
// =============================================================================

class _DaySelector extends StatefulWidget {
  final PlanningProvider planning;

  const _DaySelector({required this.planning});

  @override
  State<_DaySelector> createState() => _DaySelectorState();
}

class _DaySelectorState extends State<_DaySelector> {
  static const _letters = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  double _dragDistance = 0;

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final isSwipe =
        (velocity.abs() > 500 && _dragDistance.abs() > 100) ||
        _dragDistance.abs() > 150;
    if (isSwipe) {
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
    final monday = planning.currentMonday;
    final now = DateTime.now();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => _dragDistance = 0,
      onHorizontalDragUpdate: (details) => _dragDistance += details.delta.dx,
      onHorizontalDragEnd: _onDragEnd,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            final date = date_utils.DateUtils.addDays(monday, index);
            // Weekend days are selectable only when they have courses.
            final isEnabled = index < 5 || planning.dayHasCourses(date);

            return _DayItem(
              letter: _letters[index],
              number: date.day,
              isSelected: date_utils.DateUtils.isSameDay(
                date,
                planning.selectedDate,
              ),
              isToday: date_utils.DateUtils.isSameDay(date, now),
              isEnabled: isEnabled,
              onTap: isEnabled ? () => planning.selectDate(date) : null,
            );
          }),
        ),
      ),
    );
  }
}

class _DayItem extends StatelessWidget {
  final String letter;
  final int number;
  final bool isSelected;
  final bool isToday;
  final bool isEnabled;
  final VoidCallback? onTap;

  const _DayItem({
    required this.letter,
    required this.number,
    required this.isSelected,
    required this.isToday,
    required this.isEnabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimaryColor = context.textPrimaryColor;
    final textSecondaryColor = context.textSecondaryColor;

    final numberColor = isSelected
        ? Colors.white
        : isEnabled
        ? textPrimaryColor
        : textSecondaryColor.withValues(alpha: 0.4);

    final letterColor = isSelected
        ? Colors.white.withValues(alpha: 0.8)
        : textSecondaryColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          color: isSelected
              ? null
              : isToday
              ? AppColors.gradientStart.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              letter,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: letterColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              number.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: numberColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DAY PAGER
// =============================================================================

/// Swipeable days of one week. Rebuilt (via its key) when the week changes;
/// swiping past the first/last day moves to the previous/next week.
class _DayPager extends StatefulWidget {
  final PlanningProvider planning;
  final AppStrings strings;

  const _DayPager({
    super.key,
    required this.planning,
    required this.strings,
  });

  @override
  State<_DayPager> createState() => _DayPagerState();
}

class _DayPagerState extends State<_DayPager> {
  static const double _overscrollThreshold = 80.0;

  late final PageController _controller = PageController(
    initialPage: widget.planning.selectedDayIndex,
  );
  double _overscroll = 0;
  bool _weekChangeTriggered = false;
  // True while animating to a day picked elsewhere, so the pages crossed on
  // the way don't get selected.
  bool _animating = false;

  @override
  void didUpdateWidget(_DayPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Selection changed from outside (day selector tap): follow it.
    final target = widget.planning.selectedDayIndex;
    if (_controller.hasClients && _controller.page?.round() != target) {
      _animating = true;
      _controller
          .animateToPage(
            target,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          )
          .whenComplete(() => _animating = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.horizontal) return false;

    if (notification is ScrollStartNotification) {
      _overscroll = 0;
    } else if (notification is OverscrollNotification &&
        !_weekChangeTriggered) {
      _overscroll += notification.overscroll;
      if (_overscroll.abs() > _overscrollThreshold) {
        _weekChangeTriggered = true;
        if (_overscroll > 0) {
          widget.planning.nextWeek();
        } else {
          widget.planning.previousWeek();
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.planning.weekDays;

    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: PageView.builder(
        controller: _controller,
        physics: const ClampingScrollPhysics(),
        itemCount: days.length,
        onPageChanged: (index) {
          if (!_animating) widget.planning.selectDate(days[index]);
        },
        itemBuilder: (context, index) => _DayPage(
          planning: widget.planning,
          date: days[index],
          strings: widget.strings,
        ),
      ),
    );
  }
}

class _DayPage extends StatelessWidget {
  final PlanningProvider planning;
  final DateTime date;
  final AppStrings strings;

  const _DayPage({
    required this.planning,
    required this.date,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    if (!planning.isDayLoaded(date)) {
      // Never synced: don't pretend the day is empty.
      if (planning.isOffline) {
        return ErrorView(
          message: planning.errorMessage ?? strings.noScheduleAvailable,
          onRetry: planning.refresh,
          retryLabel: strings.retry,
        );
      }
      return LoadingIndicator(message: strings.loadingSchedule);
    }

    final courses = planning.coursesForDay(date);

    return RefreshIndicator(
      onRefresh: planning.refresh,
      color: AppColors.gradientStart,
      child: courses.isEmpty
          ? LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: _EmptyDay(
                    message: strings.noClassesScheduled,
                    isOffline: planning.isOffline,
                    strings: strings,
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 8, 16, 16),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final event = courses[index];
                return _CourseCard(
                  event: event,
                  strings: strings,
                  onTap: () => _showCourseDetails(context, event),
                );
              },
            ),
    );
  }

  void _showCourseDetails(BuildContext context, PlanningEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CourseDetailSheet(event: event, strings: strings),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  final String message;
  final bool isOffline;
  final AppStrings strings;

  const _EmptyDay({
    required this.message,
    required this.isOffline,
    required this.strings,
  });

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
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textSecondaryColor,
            ),
          ),
          if (isOffline) ...[
            const SizedBox(height: 8),
            Text(
              strings.mayNotBeUpToDate,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.warning,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// COURSE CARD
// =============================================================================

class _CourseCard extends StatelessWidget {
  final PlanningEvent event;
  final AppStrings strings;
  final VoidCallback onTap;

  const _CourseCard({
    required this.event,
    required this.strings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOngoing = event.isOngoing;
    final isPast = event.isPast;
    final textPrimaryColor = context.textPrimaryColor;
    final textSecondaryColor = context.textSecondaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 72,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8, top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.startTime,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isPast ? textSecondaryColor : textPrimaryColor,
                    ),
                  ),
                  Text(
                    event.endTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Card content
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: _CardContent(
                event: event,
                isOngoing: isOngoing,
                isPast: isPast,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  final PlanningEvent event;
  final bool isOngoing;
  final bool isPast;

  const _CardContent({
    required this.event,
    required this.isOngoing,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimaryColor = context.textPrimaryColor;
    final textSecondaryColor = context.textSecondaryColor;
    final surfaceVariantColor = context.surfaceVariantColor;

    final textColor = isOngoing ? Colors.white : textPrimaryColor;
    final secondaryColor = isOngoing
        ? Colors.white.withValues(alpha: 0.8)
        : textSecondaryColor;
    final iconColor = isOngoing
        ? Colors.white.withValues(alpha: 0.9)
        : textSecondaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
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
            ? surfaceVariantColor.withValues(alpha: 0.5)
            : surfaceVariantColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            event.displayTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Type
          if (event.typeActivite != null) ...[
            const SizedBox(height: 4),
            Text(
              event.typeActivite!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: secondaryColor,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Room
          if (event.salle != null) ...[
            Row(
              children: [
                Icon(Iconsax.location, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Text(
                  event.salle!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Instructor
          if (event.intervenants != null) ...[
            Row(
              children: [
                Icon(Iconsax.user, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.intervenants!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: secondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// COURSE DETAIL SHEET
// =============================================================================

class _CourseDetailSheet extends StatelessWidget {
  final PlanningEvent event;
  final AppStrings strings;

  const _CourseDetailSheet({required this.event, required this.strings});

  @override
  Widget build(BuildContext context) {
    final isOngoing = event.isOngoing;
    final surfaceColor = context.surfaceColor;
    final dividerColor = context.dividerColor;
    final textPrimaryColor = context.textPrimaryColor;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: isOngoing
                        ? null
                        : const LinearGradient(
                            colors: [
                              AppColors.gradientStart,
                              AppColors.gradientEnd,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                    color: isOngoing
                        ? AppColors.success.withValues(alpha: 0.1)
                        : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    event.timeRange,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isOngoing ? AppColors.success : Colors.white,
                    ),
                  ),
                ),
                if (isOngoing) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    strings.ongoing,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.success,
                    ),
                  ),
                ],
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Iconsax.close_circle),
                  color: context.textSecondaryColor,
                ),
              ],
            ),
          ),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    event.displayTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: textPrimaryColor,
                    ),
                  ),
                  if (event.typeActivite != null) ...[
                    const SizedBox(height: 4),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          AppColors.gradientStart,
                          AppColors.gradientEnd,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ).createShader(bounds),
                      child: Text(
                        event.typeActivite!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Info rows
                  if (event.salle != null)
                    _DetailRow(
                      icon: Iconsax.location,
                      label: strings.room,
                      value: event.salle!,
                    ),
                  if (event.duree != null)
                    _DetailRow(
                      icon: Iconsax.clock,
                      label: strings.duration,
                      value: event.duree!,
                    ),
                  if (event.intervenants != null)
                    _DetailRow(
                      icon: Iconsax.user,
                      label: strings.instructor,
                      value: event.intervenants!,
                    ),
                  if (event.statutIntervention != null)
                    _DetailRow(
                      icon: Iconsax.tick_circle,
                      label: strings.status,
                      value: event.statutIntervention!,
                      valueColor: event.statutIntervention == 'Confirmé'
                          ? AppColors.success
                          : null,
                    ),
                  // Description
                  if (event.description != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      strings.descriptionLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.surfaceVariantColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: textPrimaryColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimaryColor = context.textPrimaryColor;
    final textSecondaryColor = context.textSecondaryColor;
    final surfaceVariantColor = context.surfaceVariantColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: surfaceVariantColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: textSecondaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondaryColor,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
