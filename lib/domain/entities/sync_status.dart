import 'package:equatable/equatable.dart';

/// Represents the current state of Google Drive sync.
class SyncStatus extends Equatable {
  /// Whether a Google account is currently signed in.
  final bool isSignedIn;

  /// The signed-in user's email address.
  final String? userEmail;

  /// The signed-in user's display name.
  final String? userDisplayName;

  /// Timestamp of the most recent successful backup.
  final DateTime? lastBackupAt;

  /// Whether a sync operation (backup / restore) is in progress.
  final bool isSyncing;

  /// Human-readable error message from the last failed operation.
  final String? errorMessage;

  const SyncStatus({
    this.isSignedIn = false,
    this.userEmail,
    this.userDisplayName,
    this.lastBackupAt,
    this.isSyncing = false,
    this.errorMessage,
  });

  /// Initial / default status — signed out, idle.
  static const initial = SyncStatus();

  /// Returns a copy with the given fields replaced.
  SyncStatus copyWith({
    bool? isSignedIn,
    String? userEmail,
    String? userDisplayName,
    DateTime? lastBackupAt,
    bool? isSyncing,
    String? errorMessage,
    // Allow explicitly clearing nullable fields.
    bool clearUserEmail = false,
    bool clearUserDisplayName = false,
    bool clearLastBackupAt = false,
    bool clearErrorMessage = false,
  }) {
    return SyncStatus(
      isSignedIn: isSignedIn ?? this.isSignedIn,
      userEmail: clearUserEmail ? null : (userEmail ?? this.userEmail),
      userDisplayName: clearUserDisplayName
          ? null
          : (userDisplayName ?? this.userDisplayName),
      lastBackupAt:
          clearLastBackupAt ? null : (lastBackupAt ?? this.lastBackupAt),
      isSyncing: isSyncing ?? this.isSyncing,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        isSignedIn,
        userEmail,
        userDisplayName,
        lastBackupAt,
        isSyncing,
        errorMessage,
      ];
}
