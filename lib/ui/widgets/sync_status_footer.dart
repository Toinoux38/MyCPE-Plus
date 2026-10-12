import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/localization/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/utils/date_utils.dart' as date_utils;

/// Sync status line at the bottom of a card ("Updated: 5 min ago",
/// "Updating...", "Offline"). Always takes the same height, so syncing never
/// shifts the layout.
class SyncStatusFooter extends StatelessWidget {
  final bool isSyncing;
  final bool isOffline;
  final DateTime? lastSync;
  final AppStrings strings;

  const SyncStatusFooter({
    super.key,
    required this.isSyncing,
    required this.isOffline,
    required this.lastSync,
    required this.strings,
  });

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    String two(int n) => n.toString().padLeft(2, '0');

    if (diff.inMinutes < 1) return strings.justNow;
    if (diff.inMinutes < 60) return strings.minutesAgo(diff.inMinutes);
    final hourMinute = '${two(time.hour)}:${two(time.minute)}';
    if (date_utils.DateUtils.isSameDay(now, time)) return hourMinute;
    return '${two(time.day)}/${two(time.month)} $hourMinute';
  }

  @override
  Widget build(BuildContext context) {
    final lastSync = this.lastSync;

    final Widget content;
    if (isSyncing) {
      content = Row(
        key: const ValueKey('syncing'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation(AppColors.gradientStart),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            strings.syncing,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.gradientStart,
            ),
          ),
        ],
      );
    } else if (isOffline) {
      content = Row(
        key: const ValueKey('offline'),
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Iconsax.wifi_square, size: 12, color: AppColors.warning),
          const SizedBox(width: 6),
          Text(
            lastSync == null
                ? strings.offlineMode
                : '${strings.offlineMode} · ${strings.lastUpdated}: '
                      '${_formatTime(lastSync)}',
            style: const TextStyle(fontSize: 11, color: AppColors.warning),
          ),
        ],
      );
    } else {
      content = Text(
        key: const ValueKey('synced'),
        lastSync == null
            ? ''
            : '${strings.lastUpdated}: ${_formatTime(lastSync)}',
        style: TextStyle(
          fontSize: 11,
          color: context.textSecondaryColor.withValues(alpha: 0.5),
        ),
      );
    }

    return SizedBox(
      height: 28,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: content,
        ),
      ),
    );
  }
}
