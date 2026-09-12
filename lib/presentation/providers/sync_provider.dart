import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/sync_exception.dart';
import '../../domain/entities/sync_status.dart';
import '../../domain/usecases/sync_data.dart';

/// Manages Google Drive sync state for the UI.
class SyncProvider extends ChangeNotifier {
  final SyncData _syncData;

  SyncStatus _status = SyncStatus.initial;

  /// SharedPreferences key for persisting last backup timestamp.
  static const _lastBackupKey = 'last_backup_timestamp';

  /// The current sync status.
  SyncStatus get status => _status;

  SyncProvider(this._syncData);

  // ── Computed Getters ────────────────────────────────────

  /// Human-readable relative time since last backup.
  ///
  /// Returns "Just now", "5m ago", "2h ago", "3d ago",
  /// or a formatted date for older backups.
  String get lastSyncedRelativeText {
    final lastBackup = _status.lastBackupAt;
    if (lastBackup == null) return 'Never synced';

    final diff = DateTime.now().difference(lastBackup);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('dd MMM').format(lastBackup);
  }

  // ── Initialisation ──────────────────────────────────────

  /// Checks whether the user is already signed in and loads
  /// the last backup timestamp. Call once on init.
  ///
  /// Loads the cached timestamp from SharedPreferences first
  /// (instant, no network), then refreshes from Drive in the background.
  Future<void> loadStatus() async {
    try {
      // 1. Load cached timestamp instantly (no network needed)
      final prefs = await SharedPreferences.getInstance();
      final cachedMs = prefs.getInt(_lastBackupKey);
      if (cachedMs != null) {
        _status = _status.copyWith(
          lastBackupAt: DateTime.fromMillisecondsSinceEpoch(cachedMs),
        );
        notifyListeners(); // Show cached time immediately
      }

      // 2. Check sign-in status and refresh from Drive
      final signedIn = await _syncData.isSignedIn();
      if (signedIn) {
        final email = await _syncData.getSignedInEmail();
        final displayName = await _syncData.getSignedInDisplayName();
        final lastBackup = await _syncData.getLastBackupTime();

        _status = _status.copyWith(
          isSignedIn: true,
          userEmail: email,
          userDisplayName: displayName,
          lastBackupAt: lastBackup,
          clearErrorMessage: true,
        );

        // Cache the refreshed time
        if (lastBackup != null) {
          prefs.setInt(_lastBackupKey, lastBackup.millisecondsSinceEpoch);
        }
      } else {
        // Keep any cached lastBackupAt for display, but mark as signed out
        _status = _status.copyWith(
          isSignedIn: false,
          clearUserEmail: true,
          clearUserDisplayName: true,
          clearErrorMessage: true,
        );
      }
    } on SyncException catch (e) {
      _status = _status.copyWith(errorMessage: e.message);
    } catch (e) {
      _status = _status.copyWith(errorMessage: e.toString());
    }
    notifyListeners();
  }

  // ── Sign In ─────────────────────────────────────────────

  /// Triggers Google Sign-In and updates status.
  Future<void> signIn() async {
    _status = _status.copyWith(isSyncing: true, clearErrorMessage: true);
    notifyListeners();

    try {
      final email = await _syncData.signIn();
      final displayName = await _syncData.getSignedInDisplayName();
      final lastBackup = await _syncData.getLastBackupTime();

      _status = _status.copyWith(
        isSignedIn: true,
        userEmail: email,
        userDisplayName: displayName,
        lastBackupAt: lastBackup,
        isSyncing: false,
      );

      // Cache the time
      if (lastBackup != null) {
        final prefs = await SharedPreferences.getInstance();
        prefs.setInt(_lastBackupKey, lastBackup.millisecondsSinceEpoch);
      }
    } on SyncException catch (e) {
      _status = _status.copyWith(
        isSyncing: false,
        errorMessage: e.message,
      );
    } catch (e) {
      _status = _status.copyWith(
        isSyncing: false,
        errorMessage: e.toString(),
      );
    }
    notifyListeners();
  }

  // ── Sign Out ────────────────────────────────────────────

  /// Signs out and resets status to initial.
  Future<void> signOut() async {
    try {
      await _syncData.signOut();
      _status = SyncStatus.initial;
    } catch (e) {
      _status = _status.copyWith(errorMessage: e.toString());
    }
    notifyListeners();
  }

  // ── Backup ──────────────────────────────────────────────

  /// Backs up all local data to Google Drive.
  Future<void> backup() async {
    _status = _status.copyWith(isSyncing: true, clearErrorMessage: true);
    notifyListeners();

    try {
      final timestamp = await _syncData.backup();
      _status = _status.copyWith(
        isSyncing: false,
        lastBackupAt: timestamp,
      );

      // Persist to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt(_lastBackupKey, timestamp.millisecondsSinceEpoch);
    } on SyncException catch (e) {
      if (e.type == SyncErrorType.tokenExpired) {
        // Token expired — attempt silent re-auth, then retry once
        _status = _status.copyWith(isSyncing: false);
        notifyListeners();
        await _handleTokenExpiry();
        return;
      }
      _status = _status.copyWith(
        isSyncing: false,
        errorMessage: e.message,
      );
    } catch (e) {
      _status = _status.copyWith(
        isSyncing: false,
        errorMessage: e.toString(),
      );
    }
    notifyListeners();
  }

  // ── Restore ─────────────────────────────────────────────

  /// Restores data from the latest Google Drive backup.
  ///
  /// After a successful restore, call [onRestoreComplete] to
  /// reload other providers (accounts, transactions, etc.).
  Future<void> restore() async {
    _status = _status.copyWith(isSyncing: true, clearErrorMessage: true);
    notifyListeners();

    try {
      await _syncData.restore();
      final lastBackup = await _syncData.getLastBackupTime();
      _status = _status.copyWith(
        isSyncing: false,
        lastBackupAt: lastBackup,
      );

      if (lastBackup != null) {
        final prefs = await SharedPreferences.getInstance();
        prefs.setInt(_lastBackupKey, lastBackup.millisecondsSinceEpoch);
      }
    } on SyncException catch (e) {
      if (e.type == SyncErrorType.tokenExpired) {
        _status = _status.copyWith(isSyncing: false);
        notifyListeners();
        await _handleTokenExpiry();
        return;
      }
      _status = _status.copyWith(
        isSyncing: false,
        errorMessage: e.message,
      );
    } catch (e) {
      _status = _status.copyWith(
        isSyncing: false,
        errorMessage: e.toString(),
      );
    }
    notifyListeners();
  }

  // ── Private Helpers ─────────────────────────────────────

  /// Handles token expiry by clearing signed-in state and
  /// prompting re-authentication.
  Future<void> _handleTokenExpiry() async {
    _status = _status.copyWith(
      isSignedIn: false,
      clearUserEmail: true,
      clearUserDisplayName: true,
      errorMessage: 'Session expired. Please sign in again.',
    );
    notifyListeners();
  }
}

