import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vent_expense_pro/domain/repositories/sync_repository.dart';
import 'package:vent_expense_pro/domain/usecases/sync_data.dart';
import 'package:vent_expense_pro/presentation/providers/sync_provider.dart';
import 'package:vent_expense_pro/presentation/widgets/sync_settings_card.dart';

/// Fake repository to simulate all Google Drive sync scenarios in tests.
class FakeSyncRepository implements SyncRepository {
  bool _signedIn = false;
  String? _email;
  String? _displayName;
  DateTime? _lastBackup;
  bool shouldThrowOnSignIn = false;
  bool shouldThrowOnBackup = false;

  void setSignedIn({
    String email = 'user@example.com',
    String displayName = 'Test User',
    DateTime? lastBackup,
  }) {
    _signedIn = true;
    _email = email;
    _displayName = displayName;
    _lastBackup = lastBackup;
  }

  @override
  Future<String> signIn() async {
    if (shouldThrowOnSignIn) {
      throw Exception('Simulated sign in failure');
    }
    _signedIn = true;
    _email = 'user@example.com';
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
    if (shouldThrowOnBackup) {
      throw Exception('Simulated backup error');
    }
    _lastBackup = DateTime.now();
    return _lastBackup!;
  }

  @override
  Future<void> restore() async {
    if (_lastBackup == null) throw Exception('No backup available');
  }

  @override
  Future<DateTime?> getLastBackupTime() async => _lastBackup;
}

Widget createTestWidget(SyncProvider provider) {
  return MaterialApp(
    home: Scaffold(
      body: ChangeNotifierProvider<SyncProvider>.value(
        value: provider,
        child: const SingleChildScrollView(
          child: SyncSettingsCard(),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSyncRepository fakeRepo;
  late SyncData syncData;
  late SyncProvider syncProvider;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeRepo = FakeSyncRepository();
    syncData = SyncData(fakeRepo);
    syncProvider = SyncProvider(syncData);
  });

  group('SyncSettingsCard Widget Tests', () {
    testWidgets('renders signed-out state with Sign in button', (tester) async {
      await tester.pumpWidget(createTestWidget(syncProvider));

      expect(find.text('Backup & Sync'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.byKey(const ValueKey('sync_signin_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('sync_backup_button')), findsNothing);
    });

    testWidgets('tapping Sign In authenticates and transitions to signed-in state',
        (tester) async {
      await tester.pumpWidget(createTestWidget(syncProvider));

      await tester.tap(find.byKey(const ValueKey('sync_signin_button')));
      await tester.pumpAndSettle();

      expect(find.text('user@example.com'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.byKey(const ValueKey('sync_backup_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('sync_restore_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('sync_signout_button')), findsOneWidget);
    });

    testWidgets('tapping Backup Now runs backup and updates last backup label',
        (tester) async {
      fakeRepo.setSignedIn();
      await syncProvider.loadStatus();

      await tester.pumpWidget(createTestWidget(syncProvider));
      expect(find.text('No backups yet'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('sync_backup_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Last backup: Just now'), findsOneWidget);
    });

    testWidgets('tapping Restore opens confirmation dialog with cancel and restore actions',
        (tester) async {
      fakeRepo.setSignedIn(lastBackup: DateTime.now());
      await syncProvider.loadStatus();

      await tester.pumpWidget(createTestWidget(syncProvider));

      await tester.tap(find.byKey(const ValueKey('sync_restore_button')));
      await tester.pumpAndSettle();

      expect(find.text('Restore from Backup?'), findsOneWidget);
      expect(
        find.textContaining('This will replace all current data with the latest backup'),
        findsOneWidget,
      );

      // Tap Cancel closes dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Restore from Backup?'), findsNothing);
    });

    testWidgets('tapping Sign Out resets UI to signed-out state', (tester) async {
      fakeRepo.setSignedIn();
      await syncProvider.loadStatus();

      await tester.pumpWidget(createTestWidget(syncProvider));
      expect(find.text('user@example.com'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('sync_signout_button')));
      await tester.pumpAndSettle();

      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.byKey(const ValueKey('sync_signin_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('sync_backup_button')), findsNothing);
    });

    testWidgets('displays error banner when operation fails', (tester) async {
      fakeRepo.shouldThrowOnSignIn = true;

      await tester.pumpWidget(createTestWidget(syncProvider));
      await tester.tap(find.byKey(const ValueKey('sync_signin_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Simulated sign in failure'), findsOneWidget);
    });
  });
}
