import '../repositories/sync_repository.dart';

/// Orchestrates Google Drive backup & restore operations.
///
/// Validates preconditions (e.g. must be signed in) before
/// delegating to [SyncRepository].
class SyncData {
  final SyncRepository _syncRepository;

  SyncData(this._syncRepository);

  // ── Authentication ──────────────────────────────────────

  /// Sign in with Google. Returns the signed-in email.
  Future<String> signIn() => _syncRepository.signIn();

  /// Sign out and clear cached credentials.
  Future<void> signOut() => _syncRepository.signOut();

  /// Whether a Google account is currently signed in.
  Future<bool> isSignedIn() => _syncRepository.isSignedIn();

  /// Returns the signed-in user's email, or `null`.
  Future<String?> getSignedInEmail() => _syncRepository.getSignedInEmail();

  /// Returns the signed-in user's display name, or `null`.
  Future<String?> getSignedInDisplayName() =>
      _syncRepository.getSignedInDisplayName();

  // ── Backup ──────────────────────────────────────────────

  /// Back up all local data to Google Drive.
  ///
  /// Returns the backup timestamp.
  /// Throws [StateError] if the user is not signed in.
  Future<DateTime> backup() async {
    final signedIn = await _syncRepository.isSignedIn();
    if (!signedIn) {
      throw StateError('Must be signed in before backing up.');
    }
    return _syncRepository.backup();
  }

  // ── Restore ─────────────────────────────────────────────

  /// Restore data from the latest Google Drive backup.
  ///
  /// Throws [StateError] if the user is not signed in.
  Future<void> restore() async {
    final signedIn = await _syncRepository.isSignedIn();
    if (!signedIn) {
      throw StateError('Must be signed in before restoring.');
    }
    return _syncRepository.restore();
  }

  // ── Query ───────────────────────────────────────────────

  /// Returns the timestamp of the most recent backup on Drive,
  /// or `null` if no backups exist.
  Future<DateTime?> getLastBackupTime() =>
      _syncRepository.getLastBackupTime();
}
