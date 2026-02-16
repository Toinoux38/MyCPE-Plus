import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart' as date_utils;
import '../../data/models/planning_event.dart';
import '../../providers/planning_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/planning_month_view.dart';
import '../widgets/planning_week_view.dart';
import '../widgets/state_views.dart';

/// Clean, simple planning screen with day-based view
class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  late PageController _pageController;
  bool _isChangingWeek = false;

  @override
  void initState() {
    super.initState();
    _initPageController();
    _loadInitialData();
  }

  void _initPageController() {
    final provider = context.read<PlanningProvider>();
    _pageController = PageController(
      initialPage: provider.selectedDayIndex,
      viewportFraction: 1.0,
    );
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PlanningProvider>();
      if (provider.state == PlanningState.initial) {
        // Use cache-first initialization
        provider.initializeWithCache();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_isChangingWeek) return;

    final provider = context.read<PlanningProvider>();

    if (index >= 0 && index <= 4) {
      provider.selectDay(index);
    }
  }

  Future<void> _goToNextWeek() async {
    if (_isChangingWeek) return;

    setState(() => _isChangingWeek = true);

    final provider = context.read<PlanningProvider>();
    await provider.nextWeek();

    // recreate page controller at monday without animation
    _pageController.dispose();
    _pageController = PageController(initialPage: 0);

    if (mounted) {
      setState(() => _isChangingWeek = false);
    }
  }

  Future<void> _goToPreviousWeek() async {
    if (_isChangingWeek) return;

    setState(() => _isChangingWeek = true);

    final provider = context.read<PlanningProvider>();
    await provider.previousWeek();

    // recreate page controller at friday without animation
    _pageController.dispose();
    _pageController = PageController(initialPage: 4);

    if (mounted) {
      setState(() => _isChangingWeek = false);
    }
  }

  void _onDayTapped(int dayIndex) {
    if (_isChangingWeek) return;
    if (dayIndex < 0 || dayIndex > 4) return;

    final provider = context.read<PlanningProvider>();
    provider.selectDay(dayIndex);

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        dayIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _goToToday() async {
    if (_isChangingWeek) return;

    setState(() => _isChangingWeek = true);

    final provider = context.read<PlanningProvider>();
    await provider.goToToday();

    // recreate page controller to today
    _pageController.dispose();
    _pageController = PageController(initialPage: provider.selectedDayIndex);

    if (mounted) {
      setState(() => _isChangingWeek = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlanningProvider, SettingsProvider>(
      builder: (context, planning, settings, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor = isDark
            ? AppColors.backgroundDark
            : AppColors.background;

        return Container(
          color: backgroundColor,
          child: SafeArea(
            child: Column(
              children: [
                _DateHeader(
                  selectedDate: planning.selectedDate,
                  isToday: planning.isToday,
                  onTodayTap: _goToToday,
                  strings: settings.strings,
                  viewMode: planning.viewMode,
                  currentMonth: planning.currentMonth,
                ),
                // View mode toggle
                _ViewModeToggle(
                  viewMode: planning.viewMode,
                  onChanged: planning.setViewMode,
                  strings: settings.strings,
                ),
                Expanded(
                  child: _MainCard(
                    planning: planning,
                    settings: settings,
                    pageController: _pageController,
                    onPageChanged: _onPageChanged,
                    onDayTapped: _onDayTapped,
                    onPreviousWeek: _goToPreviousWeek,
                    onNextWeek: _goToNextWeek,
                    isChangingWeek: _isChangingWeek,
                  ),
                ),
                // Sync status indicator below the card
                if (planning.syncStatus != PlanningSyncStatus.synced)
                  _SyncStatusIndicator(
                    syncStatus: planning.syncStatus,
                    strings: settings.strings,
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
  final dynamic strings;
  final PlanningViewMode viewMode;
  final DateTime currentMonth;

  const _DateHeader({
    required this.selectedDate,
    required this.isToday,
    required this.onTodayTap,
    required this.strings,
    required this.viewMode,
    required this.currentMonth,
  });

  @override
  Widget build(BuildContext context) {
    // In month view, show month/year as header; in week/day, show selected date
    final displayDate = viewMode == PlanningViewMode.month
        ? currentMonth
        : selectedDate;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          // Date display
          if (viewMode == PlanningViewMode.month)
            _MonthHeaderDisplay(month: currentMonth)
          else
            _DateDisplay(selectedDate: displayDate),
          const Spacer(),
          // Today button
          _TodayButton(
            label: strings.today,
            isToday: isToday && viewMode == PlanningViewMode.day,
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
  final dynamic strings;

  const _ViewModeToggle({
    required this.viewMode,
    required this.onChanged,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.divider.withOpacity(0.5);

    final modes = [
      (PlanningViewMode.day, strings.dayView as String),
      (PlanningViewMode.week, strings.weekView as String),
      (PlanningViewMode.month, strings.monthView as String),
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
                          color: AppColors.gradientStart.withOpacity(0.3),
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
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary),
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

  const _MonthHeaderDisplay({required this.month});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;

    final monthName = date_utils.DateUtils.formatMonthYear(month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          monthName,
          style: GoogleFonts.poppins(
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

class _SyncStatusIndicator extends StatelessWidget {
  final PlanningSyncStatus syncStatus;
  final dynamic strings;

  const _SyncStatusIndicator({required this.syncStatus, required this.strings});

  @override
  Widget build(BuildContext context) {
    String text;
    IconData icon;
    Color color;

    switch (syncStatus) {
      case PlanningSyncStatus.syncing:
        text = strings.syncing;
        icon = Iconsax.refresh;
        color = AppColors.gradientStart;
        break;
      case PlanningSyncStatus.cached:
        text = strings.syncing;
        icon = Iconsax.refresh;
        color = AppColors.gradientStart;
        break;
      case PlanningSyncStatus.offline:
        text = strings.offlineMode;
        icon = Iconsax.wifi_square;
        color = AppColors.warning;
        break;
      case PlanningSyncStatus.synced:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (syncStatus == PlanningSyncStatus.syncing ||
              syncStatus == PlanningSyncStatus.cached)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          else
            Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LastUpdatedFooter extends StatelessWidget {
  final DateTime lastSyncTime;
  final dynamic strings;

  const _LastUpdatedFooter({required this.lastSyncTime, required this.strings});

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}min ago';
    } else if (diff.inHours < 24 && now.day == time.day) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else {
      final day = time.day.toString().padLeft(2, '0');
      final month = time.month.toString().padLeft(2, '0');
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$day/$month $hour:$minute';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        '${strings.lastUpdated}: ${_formatTime(lastSyncTime)}',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: textSecondaryColor.withOpacity(0.5),
        ),
      ),
    );
  }
}

class _DateDisplay extends StatelessWidget {
  final DateTime selectedDate;

  const _DateDisplay({required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textSecondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    final dayNumber = selectedDate.day.toString();
    final dayName = date_utils.DateUtils.formatDayName(selectedDate);
    final monthYear = date_utils.DateUtils.formatMonthYear(selectedDate);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dayNumber,
          style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textSecondaryColor,
              ),
            ),
            Text(
              monthYear,
              style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
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
  final SettingsProvider settings;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onDayTapped;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final bool isChangingWeek;

  const _MainCard({
    required this.planning,
    required this.settings,
    required this.pageController,
    required this.onPageChanged,
    required this.onDayTapped,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.isChangingWeek,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final dividerColor = isDark ? AppColors.dividerDark : AppColors.divider;
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Day selector — only show in day view
            if (planning.viewMode == PlanningViewMode.day) ...[
              _DaySelector(
                currentMonday: planning.currentMonday,
                selectedDayIndex: planning.selectedDayIndex,
                onDayTapped: onDayTapped,
                onPreviousWeek: onPreviousWeek,
                onNextWeek: onNextWeek,
              ),
              Divider(height: 1, color: dividerColor),
            ],
            // Content
            Expanded(child: _buildContent()),
            // Last updated footer
            if (planning.lastSyncTime != null)
              _LastUpdatedFooter(
                lastSyncTime: planning.lastSyncTime!,
                strings: settings.strings,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final strings = settings.strings;

    // Month and week views handle their own loading/empty states
    if (planning.viewMode == PlanningViewMode.month) {
      return PlanningMonthView(planning: planning, strings: strings);
    }

    if (planning.viewMode == PlanningViewMode.week) {
      if (planning.state == PlanningState.initial ||
          planning.state == PlanningState.loading) {
        return LoadingIndicator(message: strings.loadingSchedule);
      }
      if (planning.state == PlanningState.error) {
        return ErrorView(
          message: planning.errorMessage ?? strings.noScheduleAvailable,
          onRetry: planning.refresh,
          retryLabel: strings.retry,
        );
      }
      return PlanningWeekView(
        planning: planning,
        strings: strings,
        onPreviousWeek: onPreviousWeek,
        onNextWeek: onNextWeek,
      );
    }

    // Day view (default)
    switch (planning.state) {
      case PlanningState.initial:
      case PlanningState.loading:
        return LoadingIndicator(message: strings.loadingSchedule);

      case PlanningState.error:
        return ErrorView(
          message: planning.errorMessage ?? strings.noScheduleAvailable,
          onRetry: planning.refresh,
          retryLabel: strings.retry,
        );

      case PlanningState.loaded:
        if (isChangingWeek) {
          return const Center(child: CircularProgressIndicator());
        }
        return _CoursesView(
          planning: planning,
          pageController: pageController,
          onPageChanged: onPageChanged,
          onNextWeek: onNextWeek,
          onPreviousWeek: onPreviousWeek,
          strings: settings.strings,
        );
    }
  }
}

// =============================================================================
// DAY SELECTOR
// =============================================================================

class _DaySelector extends StatefulWidget {
  final DateTime currentMonday;
  final int selectedDayIndex;
  final ValueChanged<int> onDayTapped;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  const _DaySelector({
    required this.currentMonday,
    required this.selectedDayIndex,
    required this.onDayTapped,
    required this.onPreviousWeek,
    required this.onNextWeek,
  });

  @override
  State<_DaySelector> createState() => _DaySelectorState();
}

class _DaySelectorState extends State<_DaySelector> {
  double _dragDistance = 0;
  bool _isProcessingSwipe = false;

  @override
  Widget build(BuildContext context) {
    final weekDays = ['D', 'L', 'M', 'M', 'J', 'V', 'S'];
    final sunday = widget.currentMonday.subtract(const Duration(days: 1));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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
        final hasSignificantDistance = _dragDistance.abs() > 100;

        if ((hasSignificantVelocity && hasSignificantDistance) ||
            _dragDistance.abs() > 150) {
          _isProcessingSwipe = true;
          if (_dragDistance > 0) {
            widget.onPreviousWeek();
          } else {
            widget.onNextWeek();
          }
        }
        _dragDistance = 0;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            final date = sunday.add(Duration(days: index));
            final isWeekday = index >= 1 && index <= 5;
            final dayIndex = index - 1;
            final isSelected = isWeekday && dayIndex == widget.selectedDayIndex;
            final isToday = date_utils.DateUtils.isSameDay(
              date,
              DateTime.now(),
            );

            return _DayItem(
              letter: weekDays[index],
              number: date.day,
              isSelected: isSelected,
              isToday: isToday,
              isEnabled: isWeekday,
              onTap: isWeekday ? () => widget.onDayTapped(dayIndex) : null,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textSecondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    final numberColor = isSelected
        ? Colors.white
        : isEnabled
        ? textPrimaryColor
        : textSecondaryColor.withOpacity(0.4);

    final letterColor = isSelected
        ? Colors.white.withOpacity(0.8)
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
              ? AppColors.gradientStart.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              letter,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: letterColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              number.toString(),
              style: GoogleFonts.poppins(
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
// COURSES VIEW
// =============================================================================

class _CoursesView extends StatefulWidget {
  final PlanningProvider planning;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onNextWeek;
  final VoidCallback onPreviousWeek;
  final dynamic strings;

  const _CoursesView({
    required this.planning,
    required this.pageController,
    required this.onPageChanged,
    required this.onNextWeek,
    required this.onPreviousWeek,
    required this.strings,
  });

  @override
  State<_CoursesView> createState() => _CoursesViewState();
}

class _CoursesViewState extends State<_CoursesView> {
  double _overscrollAccumulator = 0;
  bool _isHandlingOverscroll = false;
  static const double _overscrollThreshold = 80.0;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // Handle overscroll at page boundaries for week transitions
        if (notification is OverscrollNotification) {
          // Only handle horizontal overscrolls (from PageView), not vertical (from ListView/RefreshIndicator)
          if (notification.metrics.axis != Axis.horizontal) return false;

          if (_isHandlingOverscroll) return true;

          final currentPage = widget.pageController.page?.round() ?? 0;

          if (currentPage == 4 && notification.overscroll > 0) {
            // Friday, swiping right
            _overscrollAccumulator += notification.overscroll;
            if (_overscrollAccumulator > _overscrollThreshold) {
              _isHandlingOverscroll = true;
              _overscrollAccumulator = 0;
              widget.onNextWeek();
              // Reset after a delay to prevent double triggers
              Future.delayed(const Duration(milliseconds: 500), () {
                _isHandlingOverscroll = false;
              });
            }
            return true;
          } else if (currentPage == 0 && notification.overscroll < 0) {
            // Monday, swiping left
            _overscrollAccumulator += notification.overscroll.abs();
            if (_overscrollAccumulator > _overscrollThreshold) {
              _isHandlingOverscroll = true;
              _overscrollAccumulator = 0;
              widget.onPreviousWeek();
              Future.delayed(const Duration(milliseconds: 500), () {
                _isHandlingOverscroll = false;
              });
            }
            return true;
          }
        }

        if (notification is ScrollStartNotification ||
            notification is ScrollEndNotification) {
          _overscrollAccumulator = 0;
        }

        return false;
      },
      child: PageView.builder(
        controller: widget.pageController,
        onPageChanged: widget.onPageChanged,
        physics: const ClampingScrollPhysics(),
        itemCount: 5, // Monday to Friday
        itemBuilder: (context, index) {
          return _DayPage(
            planning: widget.planning,
            dayIndex: index,
            strings: widget.strings,
            isOffline: widget.planning.isOffline,
          );
        },
      ),
    );
  }
}

class _DayPage extends StatelessWidget {
  final PlanningProvider planning;
  final int dayIndex;
  final dynamic strings;
  final bool isOffline;

  const _DayPage({
    required this.planning,
    required this.dayIndex,
    required this.strings,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    if (dayIndex >= planning.weekPlanning.length) {
      return _EmptyDay(
        message: strings.noClassesScheduled,
        isOffline: isOffline,
        strings: strings,
      );
    }

    final dayPlanning = planning.weekPlanning[dayIndex];

    if (!dayPlanning.hasCourses) {
      return _EmptyDay(
        message: strings.noClassesScheduled,
        isOffline: isOffline,
        strings: strings,
      );
    }

    return RefreshIndicator(
      onRefresh: planning.refresh,
      color: AppColors.gradientStart,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(0, 8, 16, 16),
        itemCount: dayPlanning.courses.length,
        itemBuilder: (context, index) {
          final event = dayPlanning.courses[index];
          return _CourseCard(
            event: event,
            strings: strings,
            onTap: () => _showCourseDetails(context, event, strings),
          );
        },
      ),
    );
  }

  void _showCourseDetails(
    BuildContext context,
    PlanningEvent event,
    dynamic strings,
  ) {
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
  final dynamic strings;

  const _EmptyDay({
    required this.message,
    required this.isOffline,
    required this.strings,
  });

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
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textSecondaryColor,
            ),
          ),
          if (isOffline) ...[
            const SizedBox(height: 8),
            Text(
              strings.mayNotBeUpToDate,
              style: GoogleFonts.poppins(
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
  final dynamic strings;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textSecondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 56,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.startTime,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isPast ? textSecondaryColor : textPrimaryColor,
                    ),
                  ),
                  Text(
                    event.endTime,
                    style: GoogleFonts.poppins(
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

    final textColor = isOngoing ? Colors.white : textPrimaryColor;
    final secondaryColor = isOngoing
        ? Colors.white.withOpacity(0.8)
        : textSecondaryColor;
    final iconColor = isOngoing
        ? Colors.white.withOpacity(0.9)
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
            ? surfaceVariantColor.withOpacity(0.5)
            : surfaceVariantColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            event.displayTitle,
            style: GoogleFonts.poppins(
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
              style: GoogleFonts.poppins(
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
                  style: GoogleFonts.poppins(
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
                    style: GoogleFonts.poppins(
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
  final dynamic strings;

  const _CourseDetailSheet({required this.event, required this.strings});

  @override
  Widget build(BuildContext context) {
    final isOngoing = event.isOngoing;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final dividerColor = isDark ? AppColors.dividerDark : AppColors.divider;
    final textPrimaryColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;

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
                        ? AppColors.success.withOpacity(0.1)
                        : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    event.timeRange,
                    style: GoogleFonts.poppins(
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
                    'En cours',
                    style: GoogleFonts.poppins(
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
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
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
                    style: GoogleFonts.poppins(
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
                        style: GoogleFonts.poppins(
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
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceVariantDark
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event.description!,
                        style: GoogleFonts.poppins(
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
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: textSecondaryColor,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
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
