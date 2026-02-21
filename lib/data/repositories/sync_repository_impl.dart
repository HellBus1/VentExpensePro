import '../../core/utils/database_export.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/google_drive_service.dart';

/// Implements [SyncRepository] by composing [GoogleDriveService]
/// (authentication + Drive file ops) with [DatabaseExport]
/// (local DB ↔ JSON serialization).
class SyncRepositoryImpl implements SyncRepository {
  final GoogleDriveService _driveService;

  SyncRepositoryImpl(this._driveService);

  // ── Authentication ──────────────────────────────────────

  @override
  Future<String> signIn() async {
    final account = await _driveService.signIn();
    return account.email;
  }

  @override
  Future<void> signOut() => _driveService.signOut();

  @override
  Future<bool> isSignedIn() => _driveService.isSignedIn();

  @override
  Future<String?> getSignedInEmail() async {
    var user = _driveService.currentUser;
    user ??= await _driveService.signInSilently();
    return user?.email;
  }

  @override
  Future<String?> getSignedInDisplayName() async {
    var user = _driveService.currentUser;
    user ??= await _driveService.signInSilently();
    return user?.displayName;
  }

  // ── Backup ──────────────────────────────────────────────

  @override
  Future<DateTime> backup() async {
    // 1. Export the entire local DB to a JSON string.
    final jsonString = await DatabaseExport.exportAsJson();

    // 2. Upload to Drive appDataFolder.
    final timestamp = await _driveService.uploadBackup(jsonString);

    return timestamp;
  }

  // ── Restore ─────────────────────────────────────────────

  @override
  Future<void> restore() async {
    // 1. Download the latest backup JSON.
    final jsonString = await _driveService.downloadLatestBackup();

    // 2. Replace local data atomically.
    await DatabaseExport.importFromJson(jsonString);
  }

  // ── Query ───────────────────────────────────────────────

  @override
  Future<DateTime?> getLastBackupTime() =>
      _driveService.getLatestBackupTime();
}
