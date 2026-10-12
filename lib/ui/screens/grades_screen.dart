import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/utils/grade_utils.dart';
import '../../data/models/course_grades.dart';
import '../../providers/grades_provider.dart';
import '../../providers/settings_provider.dart';
import '../widgets/state_views.dart';
import '../widgets/sync_status_footer.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GradesProvider>();
      if (provider.state == GradesState.initial) {
        provider.loadGrades();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GradesProvider, SettingsProvider>(
      builder: (context, grades, settings, _) {
        final backgroundColor = context.backgroundColor;

        return Container(
          color: backgroundColor,
          child: SafeArea(
            child: Column(
              children: [
                _GradesHeader(strings: settings.strings),
                Expanded(
                  child: _MainCard(grades: grades, settings: settings),
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
// GRADES HEADER
// =============================================================================

class _GradesHeader extends StatelessWidget {
  final AppStrings strings;

  const _GradesHeader({required this.strings});

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
            child: const Icon(Iconsax.medal, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Text(
            strings.grades,
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
  final GradesProvider grades;
  final SettingsProvider settings;

  const _MainCard({required this.grades, required this.settings});

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
            // Stats bar
            _StatsBar(grades: grades, strings: settings.strings),
            Divider(height: 1, color: dividerColor),
            // Content
            Expanded(child: _buildContent()),
            SyncStatusFooter(
              isSyncing: grades.isSyncing,
              isOffline: grades.isOffline,
              lastSync: grades.lastUpdated,
              strings: settings.strings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final strings = settings.strings;

    switch (grades.state) {
      case GradesState.initial:
      case GradesState.loading:
        return LoadingIndicator(message: strings.loadingGrades);

      case GradesState.error:
        return ErrorView(
          message: grades.errorMessage ?? strings.noGradesAvailable,
          onRetry: grades.refresh,
          retryLabel: strings.retry,
        );

      case GradesState.loaded:
        if (grades.courses.isEmpty) {
          return _EmptyGrades(message: strings.noGradesAvailable);
        }
        return _CoursesList(grades: grades, strings: settings.strings);
    }
  }
}

// =============================================================================
// STATS BAR
// =============================================================================

class _StatsBar extends StatelessWidget {
  final GradesProvider grades;
  final AppStrings strings;

  const _StatsBar({required this.grades, required this.strings});

  @override
  Widget build(BuildContext context) {
    final dividerColor = context.dividerColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Iconsax.book,
            value: grades.totalCourses.toString(),
            label: strings.courses,
          ),
          Container(width: 1, height: 32, color: dividerColor),
          _StatItem(
            icon: Iconsax.document_text,
            value: grades.totalGradedExams.toString(),
            label: strings.graded,
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

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimaryColor = context.textPrimaryColor;
    final textSecondaryColor = context.textSecondaryColor;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimaryColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: textSecondaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// COURSES LIST
// =============================================================================

class _CoursesList extends StatelessWidget {
  final GradesProvider grades;
  final AppStrings strings;

  const _CoursesList({required this.grades, required this.strings});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: grades.refresh,
      color: AppColors.gradientStart,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: grades.courses.length,
        itemBuilder: (context, index) {
          final course = grades.courses[index];
          final courseId = course.id?.toString() ?? index.toString();

          return _CourseCard(
            course: course,
            isExpanded: grades.expandedCourseId == courseId,
            onTap: () => grades.toggleCourseExpansion(courseId),
            strings: strings,
          );
        },
      ),
    );
  }
}

class _EmptyGrades extends StatelessWidget {
  final String message;

  const _EmptyGrades({required this.message});

  @override
  Widget build(BuildContext context) {
    final textSecondaryColor = context.textSecondaryColor;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.medal,
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
        ],
      ),
    );
  }
}

// =============================================================================
// COURSE CARD
// =============================================================================

class _CourseCard extends StatelessWidget {
  final CourseGrades course;
  final bool isExpanded;
  final VoidCallback onTap;
  final AppStrings strings;

  const _CourseCard({
    required this.course,
    required this.isExpanded,
    required this.onTap,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceVariantColor = context.surfaceVariantColor;
    final textPrimaryColor = context.textPrimaryColor;
    final dividerColor = context.dividerColor;

    final average = course.averageGrade;
    final gradeColor = GradeUtils.getGradeColor(average);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceVariantColor,
        borderRadius: BorderRadius.circular(16),
        border: isExpanded
            ? Border.all(
                color: AppColors.gradientStart.withValues(alpha: 0.3),
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Grade badge
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: gradeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          GradeUtils.formatGrade(average),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: gradeColor,
                          ),
                        ),
                        Text(
                          strings.avg,
                          style: TextStyle(
                            fontSize: 10,
                            color: gradeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Course info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.displayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textPrimaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildChip(
                              Iconsax.document,
                              '${course.gradedExamsCount}/${course.totalExamsCount}',
                            ),
                            if (course
                                    .inscriptionCours
                                    ?.nombreCreditsPotentiels !=
                                null) ...[
                              const SizedBox(width: 8),
                              _buildChip(
                                Iconsax.star,
                                '${course.inscriptionCours!.nombreCreditsPotentiels} ${strings.credits}',
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildValidationIcon(course),
                ],
              ),
            ),
          ),
          // Expanded exams
          if (isExpanded && course.epreuves.isNotEmpty) ...[
            Divider(height: 1, color: dividerColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: course.epreuves.map((exam) {
                  return _ExamRow(exam: exam, strings: strings);
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Builder(
      builder: (context) {
        final surfaceColor = context.surfaceColor;
        final textSecondaryColor = context.textSecondaryColor;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: textSecondaryColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondaryColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildValidationIcon(CourseGrades course) {
    final estValidee = course.inscriptionCours?.estValidee;

    if (estValidee == null) {
      // Validation is ongoing - show wait icon
      return Icon(Iconsax.clock, color: AppColors.disabled, size: 20);
    } else if (estValidee) {
      // Validated - show green check
      return Icon(Iconsax.tick_circle, color: AppColors.success, size: 20);
    } else {
      // Not validated - show red cross
      return Icon(Iconsax.close_circle, color: AppColors.error, size: 20);
    }
  }
}

// =============================================================================
// EXAM ROW
// =============================================================================

class _ExamRow extends StatelessWidget {
  final Epreuve exam;
  final AppStrings strings;

  const _ExamRow({required this.exam, required this.strings});

  @override
  Widget build(BuildContext context) {
    final surfaceColor = context.surfaceColor;
    final textPrimaryColor = context.textPrimaryColor;
    final textSecondaryColor = context.textSecondaryColor;

    final grade = exam.grade;
    final gradeColor = exam.estAbsent
        ? AppColors.error
        : GradeUtils.getGradeColor(grade);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exam.libelle ?? strings.unnamedExam,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textPrimaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (exam.intervenants != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    exam.intervenants!,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: gradeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              exam.displayGrade,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: gradeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
