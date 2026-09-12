/// Typed errors for Google Drive sync operations.
///
/// Used to distinguish recoverable conditions (expired token, no network)
/// from hard failures, so the UI can respond appropriately.
enum SyncErrorType {
  /// No Google account is signed in.
  notSignedIn,

  /// The OAuth token has expired or been revoked.
  tokenExpired,

  /// The device has no internet connectivity.
  noNetwork,

  /// No backup file was found on Google Drive.
  noBackupFound,

  /// The restore operation failed (corrupt data, schema mismatch, etc.).
  restoreFailed,

  /// The backup upload failed.
  backupFailed,

  /// An unclassified error.
  unknown,
}

/// Exception thrown by sync-related services and repositories.
class SyncException implements Exception {
  /// The error category — drives UI behavior (retry, re-sign-in, etc.).
  final SyncErrorType type;

  /// Human-readable error message shown to the user.
  final String message;

  const SyncException(this.type, this.message);

  @override
  String toString() => message;
}
