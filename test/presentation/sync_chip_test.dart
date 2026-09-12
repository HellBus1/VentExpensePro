import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vent_expense_pro/domain/repositories/sync_repository.dart';
import 'package:vent_expense_pro/domain/usecases/sync_data.dart';
import 'package:vent_expense_pro/presentation/providers/sync_provider.dart';
import 'package:vent_expense_pro/presentation/widgets/sync_status_chip.dart';

class FakeSyncRepository implements SyncRepository {
  bool _signedIn = false;
  String? _email;
  DateTime? _lastBackup;
  bool shouldThrowOnBackup = false;

  void setSignedIn({DateTime? lastBackup}) {
    _signedIn = true;
    _email = 'user@example.com';
    _lastBackup = lastBackup;
  }

  @override
  Future<String> signIn() async {
    _signedIn = true;
    _email = 'user@example.com';
    return _email!;
  }

  @override
  Future<void> signOut() async {
    _signedIn = false;
    _email = null;
  }

  @override
  Future<bool> isSignedIn() async => _signedIn;

  @override
  Future<String?> getSignedInEmail() async => _email;

  @override
  Future<String?> getSignedInDisplayName() async =>
      _signedIn ? 'User' : null;

  @override
  Future<DateTime> backup() async {
    if (shouldThrowOnBackup) {
      throw Exception('Backup failed');
    }
    _lastBackup = DateTime.now();
    return _lastBackup!;
  }

  @override
  Future<void> restore() async {}

  @override
  Future<DateTime?> getLastBackupTime() async => _lastBackup;
}

Widget createTestWidget(SyncProvider provider) {
  return MaterialApp(
    home: Scaffold(
      body: ChangeNotifierProvider<SyncProvider>.value(
        value: provider,
        child: const SyncStatusChip(),
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

  group('SyncStatusChip Widget Tests', () {
    testWidgets('shows Never synced when user has not backed up', (tester) async {
      await tester.pumpWidget(createTestWidget(syncProvider));

      expect(find.byKey(const ValueKey('sync_chip')), findsOneWidget);
      expect(find.text('Never synced'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
    });

    testWidgets('tapping chip when signed out triggers sign in', (tester) async {
      await tester.pumpWidget(createTestWidget(syncProvider));

      await tester.tap(find.byKey(const ValueKey('sync_chip')));
      await tester.pumpAndSettle();

      expect(syncProvider.status.isSignedIn, isTrue);
    });

    testWidgets('shows relative time when signed in with prior backup',
        (tester) async {
      fakeRepo.setSignedIn(lastBackup: DateTime.now().subtract(const Duration(minutes: 5)));
      await syncProvider.loadStatus();

      await tester.pumpWidget(createTestWidget(syncProvider));

      expect(find.text('5m ago'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
    });

    testWidgets('tapping chip when signed in triggers backup and shows snackbar',
        (tester) async {
      fakeRepo.setSignedIn(lastBackup: DateTime.now().subtract(const Duration(hours: 1)));
      await syncProvider.loadStatus();

      await tester.pumpWidget(createTestWidget(syncProvider));

      await tester.tap(find.byKey(const ValueKey('sync_chip')));
      await tester.pumpAndSettle();

      expect(find.text('Backup complete'), findsOneWidget);
      expect(find.text('Just now'), findsOneWidget);
    });

    testWidgets('shows error icon when sync error occurs', (tester) async {
      fakeRepo.setSignedIn();
      fakeRepo.shouldThrowOnBackup = true;
      await syncProvider.loadStatus();

      await tester.pumpWidget(createTestWidget(syncProvider));

      await tester.tap(find.byKey(const ValueKey('sync_chip')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
      expect(find.textContaining('Backup failed'), findsOneWidget);
    });
  });
}
