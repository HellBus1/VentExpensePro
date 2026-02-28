import 'dart:convert';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Low-level service wrapping Google Sign-In + Google Drive API (v3).
///
/// All file operations target the `appDataFolder` — a hidden,
/// app-private folder that the user cannot browse in their Drive.
class GoogleDriveService {
  static const _backupPrefix = 'vent_expense_backup_';
  static const _mimeType = 'application/json';

  /// Number of old backups to keep after a new one is uploaded.
  static const _keepBackupCount = 5;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
  );

  // ── Authentication ──────────────────────────────────────

  /// Trigger interactive Google Sign-In.
  ///
  /// Returns the signed-in [GoogleSignInAccount].
  /// Throws if the user cancels or an error occurs.
  Future<GoogleSignInAccount> signIn() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google Sign-In was cancelled.');
    }
    return account;
  }

  /// Sign out and disconnect.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Whether a Google account is currently signed in.
  Future<bool> isSignedIn() => _googleSignIn.isSignedIn();

  /// Returns the currently signed-in account, or `null`.
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Attempts to restore a previous sign-in silently (no UI).
  Future<GoogleSignInAccount?> signInSilently() =>
      _googleSignIn.signInSilently();

  // ── Drive File Operations ───────────────────────────────

  /// Uploads [jsonString] as a backup file to `appDataFolder`.
  ///
  /// The file is named `vent_expense_backup_<ISO8601>.json`.
  /// After upload, old backups beyond [_keepBackupCount] are cleaned up.
  Future<DateTime> uploadBackup(String jsonString) async {
    final driveApi = await _getDriveApi();
    final now = DateTime.now();
    final filename = '$_backupPrefix${now.toIso8601String()}.json';

    final media = drive.Media(
      Stream.value(utf8.encode(jsonString)),
      utf8.encode(jsonString).length,
    );

    final driveFile = drive.File()
      ..name = filename
      ..parents = ['appDataFolder']
      ..mimeType = _mimeType;

    await driveApi.files.create(driveFile, uploadMedia: media);

    // Clean up old backups, keep only the latest N.
    await _cleanupOldBackups(driveApi);

    return now;
  }

  /// Downloads the content of the most recent backup file.
  ///
  /// Returns the JSON string. Throws if no backup exists.
  Future<String> downloadLatestBackup() async {
    final driveApi = await _getDriveApi();
    final latest = await _getLatestBackupFile(driveApi);

    if (latest == null || latest.id == null) {
      throw Exception('No backup found on Google Drive.');
    }

    final media = await driveApi.files.get(
      latest.id!,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }

    return utf8.decode(bytes);
  }

  /// Returns the `modifiedTime` of the most recent backup,
  /// or `null` if no backups exist.
  Future<DateTime?> getLatestBackupTime() async {
    final driveApi = await _getDriveApi();
    final latest = await _getLatestBackupFile(driveApi);
    return latest?.modifiedTime;
  }

  // ── Helpers ─────────────────────────────────────────────

  /// Builds an authenticated [drive.DriveApi] client.
  Future<drive.DriveApi> _getDriveApi() async {
    var account = _googleSignIn.currentUser;
    account ??= await _googleSignIn.signInSilently();

    if (account == null) {
      throw Exception('Not signed in to Google.');
    }

    final authHeaders = await account.authHeaders;
    final client = _GoogleAuthClient(authHeaders);
    return drive.DriveApi(client);
  }

  /// Returns the most recent backup file metadata, or `null`.
  Future<drive.File?> _getLatestBackupFile(drive.DriveApi api) async {
    final fileList = await api.files.list(
      spaces: 'appDataFolder',
      q: "name contains '$_backupPrefix'",
      orderBy: 'modifiedTime desc',
      pageSize: 1,
      $fields: 'files(id, name, modifiedTime)',
    );

    final files = fileList.files;
    if (files == null || files.isEmpty) return null;
    return files.first;
  }

  /// Deletes old backups beyond [_keepBackupCount].
  Future<void> _cleanupOldBackups(drive.DriveApi api) async {
    final fileList = await api.files.list(
      spaces: 'appDataFolder',
      q: "name contains '$_backupPrefix'",
      orderBy: 'modifiedTime desc',
      $fields: 'files(id, name)',
    );

    final files = fileList.files;
    if (files == null || files.length <= _keepBackupCount) return;

    // Delete everything after the first N.
    for (var i = _keepBackupCount; i < files.length; i++) {
      final id = files[i].id;
      if (id != null) {
        await api.files.delete(id);
      }
    }
  }
}

/// A simple [http.BaseClient] that injects Google auth headers.
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}
