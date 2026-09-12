import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vent_expense_pro/core/di/service_locator.dart';
import 'package:vent_expense_pro/domain/repositories/sync_repository.dart';
import 'package:vent_expense_pro/domain/usecases/sync_data.dart';
import 'package:vent_expense_pro/main.dart';

/// Fake repository used for hermetic end-to-end UI integration tests.
class FakeIntegrationSyncRepository implements SyncRepository {
  bool _signedIn = false;
  String? _email;
  String? _displayName;
  DateTime? _lastBackup;

  @override
  Future<String> signIn() async {
    _signedIn = true;
    _email = 'test.user@gmail.com';
    _displayName = 'Test User';
    return _email!;
  }

  @override
  Future<void> signOut() async {
    _signedIn = false;
    _email = null;
    _displayName = null;
  }

  @override
  Future<bool> isSignedIn() async => _signedIn;

  @override
  Future<String?> getSignedInEmail() async => _email;

  @override
  Future<String?> getSignedInDisplayName() async => _displayName;

  @override
  Future<DateTime> backup() async {
    _lastBackup = DateTime.now();
    return _lastBackup!;
  }

  @override
  Future<void> restore() async {}

  @override
  Future<DateTime?> getLastBackupTime() async => _lastBackup;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await initServiceLocator();

    // Override SyncRepository and SyncData with our fake for automated UI testing
    sl.allowReassignment = true;
    final fakeRepo = FakeIntegrationSyncRepository();
    sl.registerLazySingleton<SyncRepository>(() => fakeRepo);
    sl.registerFactory<SyncData>(() => SyncData(fakeRepo));
  });

  group('Google Drive Backup & Sync Integration Tests', () {
    testWidgets(
      'Full End-to-End flow: Ledger sync chip -> Open Backup & Sync modal -> Sign In -> Backup -> Restore dialog -> Sign Out',
      (tester) async {
        // 1. Launch the application
        await tester.pumpWidget(const VentExpenseApp());
        await tester.pumpAndSettle();

        // 2. Verify LedgerScreen is active and the SyncStatusChip is visible
        final syncChipFinder = find.byKey(const ValueKey('sync_chip'));
        expect(syncChipFinder, findsOneWidget);
        expect(find.text('Never synced'), findsOneWidget);

        // 3. Open the top-right app bar overflow menu
        final menuButtonFinder = find.byKey(const ValueKey('app_bar_overflow_menu'));
        expect(menuButtonFinder, findsOneWidget);
        await tester.tap(menuButtonFinder);
        await tester.pumpAndSettle();

        // 4. Select 'Backup & Sync' from the menu
        final syncMenuItemFinder = find.text('Backup & Sync');
        expect(syncMenuItemFinder, findsOneWidget);
        await tester.tap(syncMenuItemFinder);
        await tester.pumpAndSettle();

        // 5. Verify the SyncSettingsCard bottom sheet opens in signed-out state
        expect(find.text('Sign in with Google'), findsOneWidget);
        final signInBtn = find.byKey(const ValueKey('sync_signin_button'));
        expect(signInBtn, findsOneWidget);

        // 6. Tap 'Sign in with Google'
        await tester.tap(signInBtn);
        await tester.pumpAndSettle();

        // 7. Verify transitions to signed-in state
        expect(find.text('test.user@gmail.com'), findsOneWidget);
        expect(find.text('Test User'), findsOneWidget);
        expect(find.text('No backups yet'), findsOneWidget);
        final backupBtn = find.byKey(const ValueKey('sync_backup_button'));
        final restoreBtn = find.byKey(const ValueKey('sync_restore_button'));
        final signOutBtn = find.byKey(const ValueKey('sync_signout_button'));
        expect(backupBtn, findsOneWidget);
        expect(restoreBtn, findsOneWidget);
        expect(signOutBtn, findsOneWidget);

        // 8. Tap 'Backup Now'
        await tester.tap(backupBtn);
        await tester.pumpAndSettle();

        // 9. Verify last backup status updates
        expect(find.textContaining('Last backup: Just now'), findsOneWidget);

        // 10. Tap 'Restore' to open confirmation dialog
        await tester.tap(restoreBtn);
        await tester.pumpAndSettle();

        expect(find.text('Restore from Backup?'), findsOneWidget);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Restore from Backup?'), findsNothing);

        // 11. Tap 'Sign Out'
        await tester.tap(signOutBtn);
        await tester.pumpAndSettle();

        // 12. Verify return to signed-out state
        expect(find.text('Sign in with Google'), findsOneWidget);

        // 13. Close modal sheet
        await tester.tapAt(const Offset(20, 50));
        await tester.pumpAndSettle();

        // 14. Verify back on Ledger screen
        expect(find.byKey(const ValueKey('sync_chip')), findsOneWidget);
      },
    );
  });
}
