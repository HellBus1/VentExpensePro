import 'package:flutter/foundation.dart';

import '../../domain/entities/sync_status.dart';
import '../../domain/usecases/sync_data.dart';

/// Manages Google Drive sync state for the UI.
class SyncProvider extends ChangeNotifier {
  final SyncData _syncData;

  SyncStatus _status = SyncStatus.initial;

  /// The current sync status.
  SyncStatus get status => _status;

  SyncProvider(this._syncData);

  // ── Initialisation ──────────────────────────────────────

  /// Checks whether the user is already signed in and loads
  /// the last backup timestamp. Call once on init.
  Future<void> loadStatus() async {
    try {
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
      } else {
        _status = SyncStatus.initial;
      }
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
    } catch (e) {
      _status = _status.copyWith(
        isSyncing: false,
        errorMessage: e.toString(),
      );
    }
    notifyListeners();
  }
}
