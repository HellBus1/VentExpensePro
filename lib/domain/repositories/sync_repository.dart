/// Contract for Google Drive sync operations.
///
/// All operations use Google Drive's `appDataFolder` —
/// a hidden, app-private folder that the user cannot browse.
abstract class SyncRepository {
  /// Sign in with Google. Returns the signed-in email.
  ///
  /// Throws if the user cancels or an error occurs.
  Future<String> signIn();

  /// Sign out and clear cached credentials.
  Future<void> signOut();

  /// Whether a Google account is currently signed in.
  Future<bool> isSignedIn();

  /// Returns the signed-in user's email, or `null`.
  Future<String?> getSignedInEmail();

  /// Returns the signed-in user's display name, or `null`.
  Future<String?> getSignedInDisplayName();

  /// Export the entire local database as JSON and upload to Drive.
  ///
  /// Returns the backup timestamp. Throws on failure.
  Future<DateTime> backup();

  /// Download the latest backup from Drive and overwrite local data.
  ///
  /// Throws if no backup exists or on failure.
  Future<void> restore();

  /// Returns the timestamp of the most recent backup on Drive,
  /// or `null` if no backups exist.
  Future<DateTime?> getLastBackupTime();
}
