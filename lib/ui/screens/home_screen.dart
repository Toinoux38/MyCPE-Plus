import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_extensions.dart';
import '../../providers/settings_provider.dart';
import 'planning_screen.dart';
import 'grades_screen.dart';
import 'absences_screen.dart';
import 'settings_screen.dart';

/// Main home screen with bottom navigation
class HomeScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const HomeScreen({super.key, required this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  List<_NavItem> _getNavItems(SettingsProvider settings) {
    return [
      _NavItem(
        icon: Iconsax.calendar_copy,
        activeIcon: Iconsax.calendar_1,
        label: settings.strings.planning,
      ),
      _NavItem(
        icon: Iconsax.medal_copy,
        activeIcon: Iconsax.medal,
        label: settings.strings.grades,
      ),
      _NavItem(
        icon: Iconsax.calendar_remove_copy,
        activeIcon: Iconsax.calendar_remove,
        label: settings.strings.absences,
      ),
      _NavItem(
        icon: Iconsax.setting_2_copy,
        activeIcon: Iconsax.setting_2,
        label: settings.strings.settings,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final navItems = _getNavItems(settings);

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: const [
              PlanningScreen(),
              GradesScreen(),
              AbsencesScreen(),
              SettingsScreen(),
            ],
          ),
          extendBody: true,
          bottomNavigationBar: _buildBottomNavigationBar(navItems),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar(List<_NavItem> navItems) {
    final surfaceColor = context.surfaceColor;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bottomMargin = bottomPadding > 0 ? bottomPadding + 8 : 24.0;

    return Container(
      margin: EdgeInsets.fromLTRB(24, 0, 24, bottomMargin),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          navItems.length,
          (index) => _buildNavItem(index, navItems[index]),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, _NavItem item) {
    final isSelected = _currentIndex == index;
    final textSecondaryColor = context.textSecondaryColor;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                )
              : null,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              color: isSelected ? Colors.white : textSecondaryColor,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Navigation item data class
class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
