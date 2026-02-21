import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../providers/sync_provider.dart';

/// A card widget providing Google Drive backup & restore controls.
///
/// Shows sign-in, backup, restore, and sign-out actions
/// styled in the Stationery aesthetic.
class SyncSettingsCard extends StatelessWidget {
  const SyncSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, provider, _) {
        final status = provider.status;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ────────────────────────────────
              Row(
                children: [
                  const Icon(
                    Icons.cloud_outlined,
                    color: AppColors.inkBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Backup & Sync',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.inkBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Your data stays private — stored in a hidden, app-only folder on your Google Drive.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.divider, height: 1),
              const SizedBox(height: 16),

              // ── Error banner ──────────────────────────
              if (status.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.stampRedLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.stampRed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          status.errorMessage!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.stampRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Syncing indicator ─────────────────────
              if (status.isSyncing) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.inkBlue,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text('Syncing…', style: AppTypography.bodyMedium),
                      ],
                    ),
                  ),
                ),
              ]

              // ── Signed OUT ────────────────────────────
              else if (!status.isSignedIn) ...[
                _buildSignInButton(context, provider),
              ]

              // ── Signed IN ─────────────────────────────
              else ...[
                _buildSignedInSection(context, provider),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Sign-In Button ──────────────────────────────────────

  Widget _buildSignInButton(BuildContext context, SyncProvider provider) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () => provider.signIn(),
        icon: const Icon(Icons.login, size: 20),
        label: const Text('Sign in with Google'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.inkBlue,
          side: const BorderSide(color: AppColors.inkBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── Signed-In Section ───────────────────────────────────

  Widget _buildSignedInSection(BuildContext context, SyncProvider provider) {
    final status = provider.status;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // User info
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.inkBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (status.userEmail ?? '?')[0].toUpperCase(),
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.inkBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (status.userDisplayName != null)
                    Text(
                      status.userDisplayName!,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    status.userEmail ?? '',
                    style: AppTypography.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Last backup info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.paperElevated,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: AppColors.inkLight),
              const SizedBox(width: 8),
              Text(
                status.lastBackupAt != null
                    ? 'Last backup: ${_formatTimestamp(status.lastBackupAt!)}'
                    : 'No backups yet',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            // Backup button
            Expanded(
              child: SizedBox(
                height: 44,
                child: FilledButton.icon(
                  onPressed: () => provider.backup(),
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: const Text('Backup Now'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.inkBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Restore button
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmRestore(context, provider),
                  icon: const Icon(Icons.cloud_download_outlined, size: 18),
                  label: const Text('Restore'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.stampRed,
                    side: const BorderSide(color: AppColors.stampRed),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Sign-out
        Center(
          child: TextButton(
            onPressed: () => provider.signOut(),
            child: Text(
              'Sign Out',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.inkLight,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Restore Confirmation Dialog ─────────────────────────

  void _confirmRestore(BuildContext context, SyncProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Restore from Backup?',
          style: AppTypography.titleMedium.copyWith(color: AppColors.inkBlue),
        ),
        content: const Text(
          'This will replace all current data with the latest backup from Google Drive. This action cannot be undone.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.inkLight,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.restore();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.stampRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return DateFormat('MMM d, yyyy – HH:mm').format(dt);
  }
}
