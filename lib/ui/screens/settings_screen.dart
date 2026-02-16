import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_locale.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';

/// Modern settings screen with same style as planning
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final strings = settings.strings;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor = isDark
            ? AppColors.backgroundDark
            : AppColors.background;

        return Container(
          color: backgroundColor,
          child: SafeArea(
            child: Column(
              children: [
                _SettingsHeader(strings: strings),
                Expanded(child: _MainCard(settings: settings)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// SETTINGS HEADER
// =============================================================================

class _SettingsHeader extends StatelessWidget {
  final dynamic strings;

  const _SettingsHeader({required this.strings});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textSecondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

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
            child: const Icon(Iconsax.setting_2, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.settings,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: textPrimaryColor,
                ),
              ),
              Text(
                strings.appName,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: textSecondaryColor,
                ),
              ),
            ],
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
  final SettingsProvider settings;

  const _MainCard({required this.settings});

  @override
  Widget build(BuildContext context) {
    final strings = settings.strings;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
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
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Language section
            _SectionHeader(
              title: strings.language,
              icon: Iconsax.language_circle,
            ),
            const SizedBox(height: 12),
            _LanguageSelector(settings: settings),
            const SizedBox(height: 24),
            // Theme section
            _SectionHeader(title: strings.theme, icon: Iconsax.moon),
            const SizedBox(height: 12),
            _ThemeSelector(settings: settings),
            const SizedBox(height: 24),
            // About section
            _SectionHeader(title: strings.about, icon: Iconsax.info_circle),
            const SizedBox(height: 12),
            _AboutCard(settings: settings),
            const SizedBox(height: 24),
            // Logout button
            _LogoutButton(settings: settings),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// SECTION HEADER
// =============================================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 8),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [AppColors.gradientStart, AppColors.gradientEnd],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// LANGUAGE SELECTOR
// =============================================================================

class _LanguageSelector extends StatelessWidget {
  final SettingsProvider settings;

  const _LanguageSelector({required this.settings});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceVariantColor = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariant;
    final textPrimaryColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textSecondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.dividerDark : AppColors.divider;

    return Container(
      decoration: BoxDecoration(
        color: surfaceVariantColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: AppLocale.values.asMap().entries.map((entry) {
          final index = entry.key;
          final locale = entry.value;
          final isSelected = settings.locale == locale;
          final isLast = index == AppLocale.values.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: () => settings.setLocale(locale),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Text(
                        _getLanguageFlag(locale),
                        style: const TextStyle(fontSize: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              locale.displayName,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: textPrimaryColor,
                              ),
                            ),
                            Text(
                              _getLanguageNativeName(locale),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [
                                    AppColors.gradientStart,
                                    AppColors.gradientEnd,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                )
                              : null,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: textSecondaryColor.withOpacity(0.3),
                                  width: 2,
                                ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: dividerColor,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _getLanguageFlag(AppLocale locale) {
    switch (locale) {
      case AppLocale.english:
        return '🇬🇧';
      case AppLocale.french:
        return '🇫🇷';
    }
  }

  String _getLanguageNativeName(AppLocale locale) {
    switch (locale) {
      case AppLocale.english:
        return 'English';
      case AppLocale.french:
        return 'Français';
    }
  }
}

// =============================================================================
// THEME SELECTOR
// =============================================================================

class _ThemeSelector extends StatelessWidget {
  final SettingsProvider settings;

  const _ThemeSelector({required this.settings});

  @override
  Widget build(BuildContext context) {
    final strings = settings.strings;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceVariantColor = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariant;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final textPrimaryColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textSecondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final dividerColor = isDark ? AppColors.dividerDark : AppColors.divider;

    final themes = [
      _ThemeOption(ThemeMode.system, strings.themeSystem, Iconsax.mobile),
      _ThemeOption(ThemeMode.light, strings.themeLight, Iconsax.sun_1),
      _ThemeOption(ThemeMode.dark, strings.themeDark, Iconsax.moon),
    ];

    return Container(
      decoration: BoxDecoration(
        color: surfaceVariantColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: themes.asMap().entries.map((entry) {
          final index = entry.key;
          final themeOption = entry.value;
          final isSelected = settings.themeMode == themeOption.mode;
          final isLast = index == themes.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: () => settings.setThemeMode(themeOption.mode),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.gradientStart.withOpacity(0.1)
                              : surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          themeOption.icon,
                          size: 20,
                          color: isSelected
                              ? AppColors.gradientStart
                              : textSecondaryColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          themeOption.label,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: textPrimaryColor,
                          ),
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [
                                    AppColors.gradientStart,
                                    AppColors.gradientEnd,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                )
                              : null,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: textSecondaryColor.withOpacity(0.3),
                                  width: 2,
                                ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: dividerColor,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ThemeOption {
  final ThemeMode mode;
  final String label;
  final IconData icon;

  const _ThemeOption(this.mode, this.label, this.icon);
}

// =============================================================================
// ABOUT CARD
// =============================================================================

class _AboutCard extends StatefulWidget {
  final SettingsProvider settings;

  const _AboutCard({required this.settings});

  @override
  State<_AboutCard> createState() => _AboutCardState();
}

class _AboutCardState extends State<_AboutCard> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
        _buildNumber = info.buildNumber;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceVariantColor = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariant;
    final textPrimaryColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final dividerColor = isDark ? AppColors.dividerDark : AppColors.divider;

    final versionText = _version.isNotEmpty
        ? '${settings.strings.version} $_version+$_buildNumber'
        : '${settings.strings.version} ...';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceVariantColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // App info row
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SvgPicture.asset(
                    'assets/images/app_logo.svg',
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.strings.appName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.gradientStart,
                            AppColors.gradientEnd,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        versionText,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: dividerColor),
          const SizedBox(height: 20),
          // Info rows
          _InfoRow(icon: Iconsax.building, label: 'School', value: 'CPE Lyon'),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Iconsax.code,
            label: 'Developers',
            value: 'Toitoine & Max',
          ),
          const SizedBox(height: 12),
          _InfoRow(icon: Iconsax.calendar, label: 'Year', value: '2026'),
          const SizedBox(height: 12),
          _StudioRow(),
        ],
      ),
    );
  }
}

class _StudioRow extends StatelessWidget {
  const _StudioRow();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final textPrimaryColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textSecondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Row(
      children: [
        Text(
          'Studio',
          style: GoogleFonts.poppins(fontSize: 14, color: textSecondaryColor),
        ),
        const Spacer(),
        SvgPicture.asset(
          'assets/images/fluffin_studio_logo.svg',
          height: 22,
          colorFilter: ColorFilter.mode(textSecondaryColor, BlendMode.srcIn),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final textPrimaryColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textSecondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: textSecondaryColor),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, color: textSecondaryColor),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textPrimaryColor,
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// LOGOUT BUTTON
// =============================================================================

class _LogoutButton extends StatelessWidget {
  final SettingsProvider settings;

  const _LogoutButton({required this.settings});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showLogoutDialog(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Iconsax.logout,
                color: AppColors.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    settings.strings.signOut,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    settings.strings.signOutConfirmMessage,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, color: AppColors.error, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final strings = settings.strings;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimaryColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final textSecondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          strings.signOutConfirmTitle,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimaryColor,
          ),
        ),
        content: Text(
          strings.signOutConfirmMessage,
          style: GoogleFonts.poppins(fontSize: 14, color: textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              strings.cancel,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textSecondaryColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              strings.signOut,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }
}
