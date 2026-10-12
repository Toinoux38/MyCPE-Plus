import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/utils/date_utils.dart' as date_utils;
import '../../data/models/absences_response.dart';
import '../../providers/absences_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/state_views.dart';
import '../widgets/sync_status_footer.dart';

class AbsencesScreen extends StatefulWidget {
  const AbsencesScreen({super.key});

  @override
  State<AbsencesScreen> createState() => _AbsencesScreenState();
}

class _AbsencesScreenState extends State<AbsencesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AbsencesProvider>();
      if (provider.state == AbsencesState.initial) {
        provider.loadAbsences();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AbsencesProvider, SettingsProvider>(
      builder: (context, absences, settings, _) {
        final backgroundColor = context.backgroundColor;

        return Container(
          color: backgroundColor,
          child: SafeArea(
            child: Column(
              children: [
                _AbsencesHeader(strings: settings.strings),
                Expanded(
                  child: _MainCard(absences: absences, settings: settings),
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
// ABSENCES HEADER
// =============================================================================

class _AbsencesHeader extends StatelessWidget {
  final AppStrings strings;

  const _AbsencesHeader({required this.strings});

  @override
  Widget build(BuildContext context) {
    final textPrimaryColor = context.textPrimaryColor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gradientStart, AppColors.gradientEnd],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Iconsax.calendar_remove,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            strings.absences,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// MAIN CARD
// =============================================================================

class _MainCard extends StatelessWidget {
  final AbsencesProvider absences;
  final SettingsProvider settings;

  const _MainCard({required this.absences, required this.settings});

  @override
  Widget build(BuildContext context) {
    final surfaceColor = context.surfaceColor;
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
            // Stats bar
            _StatsBar(absences: absences, strings: settings.strings),
            const Divider(height: 1, color: AppColors.divider),
            // Content
            Expanded(child: _buildContent()),
            SyncStatusFooter(
              isSyncing: absences.isSyncing,
              isOffline: absences.isOffline,
              lastSync: absences.lastUpdated,
              strings: settings.strings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final strings = settings.strings;

    switch (absences.state) {
      case AbsencesState.initial:
      case AbsencesState.loading:
        return LoadingIndicator(message: strings.loadingAbsences);

      case AbsencesState.error:
        return ErrorView(
          message: absences.errorMessage ?? strings.noAbsencesAvailable,
          onRetry: absences.refresh,
          retryLabel: strings.retry,
        );

      case AbsencesState.loaded:
        if (absences.absences.isEmpty) {
          return _EmptyAbsences(message: strings.noAbsencesAvailable);
        }
        return _AbsencesList(absences: absences, strings: settings.strings);
    }
  }
}

// =============================================================================
// STATS BAR
// =============================================================================

class _StatsBar extends StatelessWidget {
  final AbsencesProvider absences;
  final AppStrings strings;

  const _StatsBar({required this.absences, required this.strings});

  @override
  Widget build(BuildContext context) {
    final data = absences.absencesData;
    if (data == null) {
      return const SizedBox.shrink();
    }

    final dividerColor = context.dividerColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Iconsax.info_circle,
                value: absences.totalAbsences.toString(),
                label: strings.totalAbsences,
                color: AppColors.gradientStart,
              ),
              Container(width: 1, height: 32, color: dividerColor),
              _StatItem(
                icon: Iconsax.tick_circle,
                value: absences.excusedAbsencesCount.toString(),
                label: strings.excusedAbsences,
                color: Colors.green,
              ),
              Container(width: 1, height: 32, color: dividerColor),
              _StatItem(
                icon: Iconsax.close_circle,
                value: absences.unexcusedAbsencesCount.toString(),
                label: strings.unexcusedAbsences,
                color: AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: dividerColor),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _DurationItem(
                label: strings.excusedAbsences,
                duration: data.dureeTotaleAbsenceExcuser,
                color: Colors.green,
              ),
              Container(width: 1, height: 32, color: dividerColor),
              _DurationItem(
                label: strings.unexcusedAbsences,
                duration: data.dureeTotaleAbsenceNonExcuser,
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimaryColor = context.textPrimaryColor;
    final textSecondaryColor = context.textSecondaryColor;

    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: textPrimaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: textSecondaryColor),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _DurationItem extends StatelessWidget {
  final String label;
  final String duration;
  final Color color;

  const _DurationItem({
    required this.label,
    required this.duration,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondaryColor = context.textSecondaryColor;

    return Expanded(
      child: Column(
        children: [
          Text(
            duration,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: textSecondaryColor),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// EMPTY STATE
// =============================================================================

class _EmptyAbsences extends StatelessWidget {
  final String message;

  const _EmptyAbsences({required this.message});

  @override
  Widget build(BuildContext context) {
    final surfaceVariantColor = context.surfaceVariantColor;
    final textSecondaryColor = context.textSecondaryColor;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: surfaceVariantColor,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Iconsax.tick_circle,
              size: 50,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// ABSENCES LIST
// =============================================================================

class _AbsencesList extends StatelessWidget {
  final AbsencesProvider absences;
  final AppStrings strings;

  const _AbsencesList({required this.absences, required this.strings});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: absences.refresh,
      color: AppColors.gradientStart,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: absences.absences.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final absence = absences.absences[index];
          return _AbsenceCard(absence: absence, strings: strings);
        },
      ),
    );
  }
}

// =============================================================================
// ABSENCE CARD
// =============================================================================

class _AbsenceCard extends StatelessWidget {
  final Absence absence;
  final AppStrings strings;

  const _AbsenceCard({required this.absence, required this.strings});

  @override
  Widget build(BuildContext context) {
    final surfaceColor = context.surfaceColor;
    final surfaceVariantColor = context.surfaceVariantColor;
    final textPrimaryColor = context.textPrimaryColor;
    final textSecondaryColor = context.textSecondaryColor;
    final dividerColor = context.dividerColor;

    final isExcused = absence.motifAbsence.estExcuser;
    final borderColor = isExcused
        ? Colors.green.withValues(alpha: 0.3)
        : AppColors.error.withValues(alpha: 0.3);
    final iconColor = isExcused ? Colors.green : AppColors.error;
    final locale = date_utils.DateUtils.localeTag(
      context.watch<SettingsProvider>().locale.code,
    );

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date and status
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Iconsax.calendar_1,
                        size: 16,
                        color: textSecondaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(absence.evenement.dateDebut, locale),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isExcused ? Iconsax.tick_circle : Iconsax.close_circle,
                        size: 14,
                        color: iconColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isExcused ? strings.excused : strings.notExcused,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Course title
            Text(
              absence.evenement.libelleConstruit,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            // Instructor
            if (absence.evenement.intervenants.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Iconsax.user, size: 14, color: textSecondaryColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      absence.evenement.intervenants,
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            // Time range
            Row(
              children: [
                Icon(Iconsax.clock, size: 14, color: textSecondaryColor),
                const SizedBox(width: 6),
                Text(
                  _formatTimeRange(
                    absence.evenement.dateDebut,
                    absence.evenement.dateFin,
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: surfaceVariantColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    absence.duree,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: dividerColor),
            const SizedBox(height: 10),
            // Reason
            Row(
              children: [
                Icon(Iconsax.info_circle, size: 14, color: textSecondaryColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    absence.motifAbsence.libelle,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondaryColor,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr, String locale) {
    final date = date_utils.DateUtils.parseApiDate(dateStr);
    if (date == null) return dateStr;
    return DateFormat('EEE d MMM y', locale).format(date);
  }

  String _formatTimeRange(String startStr, String endStr) {
    final start = date_utils.DateUtils.parseApiDate(startStr);
    final end = date_utils.DateUtils.parseApiDate(endStr);
    if (start == null || end == null) return '';
    return '${date_utils.DateUtils.formatTime(start)} - '
        '${date_utils.DateUtils.formatTime(end)}';
  }
}
