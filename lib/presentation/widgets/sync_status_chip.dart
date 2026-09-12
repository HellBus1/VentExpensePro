import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../providers/sync_provider.dart';

/// A compact, interactive chip that displays the current Google Drive sync status.
///
/// Tapping the chip:
/// - Triggers interactive sign-in if the user is signed out.
/// - Triggers an immediate backup if the user is already signed in.
class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, _) {
        final status = syncProvider.status;

        IconData icon;
        Color chipColor;
        Color iconColor;

        if (status.isSyncing) {
          icon = Icons.cloud_sync_outlined;
          chipColor = AppColors.inkBlue.withValues(alpha: 0.08);
          iconColor = AppColors.inkBlue;
        } else if (status.errorMessage != null) {
          icon = Icons.cloud_off_outlined;
          chipColor = AppColors.stampRedLight;
          iconColor = AppColors.stampRed;
        } else if (status.isSignedIn && status.lastBackupAt != null) {
          icon = Icons.cloud_done_outlined;
          chipColor = AppColors.inkGreenLight;
          iconColor = AppColors.inkGreen;
        } else {
          icon = Icons.cloud_outlined;
          chipColor = AppColors.paperElevated;
          iconColor = AppColors.disabled;
        }

        final label = status.isSyncing
            ? 'Syncing…'
            : syncProvider.lastSyncedRelativeText;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              key: const ValueKey('sync_chip'),
              onTap: () {
                if (status.isSyncing) return;
                if (status.isSignedIn) {
                  syncProvider.backup().then((_) {
                    if (context.mounted &&
                        syncProvider.status.errorMessage == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Backup complete'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else if (context.mounted &&
                        syncProvider.status.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(syncProvider.status.errorMessage!),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  });
                } else {
                  syncProvider.signIn();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.divider.withValues(alpha: 0.6),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: iconColor),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: AppTypography.label.copyWith(
                        color: iconColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
