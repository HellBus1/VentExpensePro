import 'package:flutter_test/flutter_test.dart';
import 'package:vent_expense_pro/domain/repositories/sync_repository.dart';
import 'package:vent_expense_pro/domain/usecases/sync_data.dart';

/// A simple fake of [SyncRepository] for testing.
class FakeSyncRepository implements SyncRepository {
  bool _signedIn = false;
  String? _email;
  DateTime? _lastBackup;

  @override
  Future<String> signIn() async {
    _signedIn = true;
    _email = 'test@example.com';
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
      _signedIn ? 'Test User' : null;

  @override
  Future<DateTime> backup() async {
    _lastBackup = DateTime.now();
    return _lastBackup!;
  }

  @override
  Future<void> restore() async {
    if (_lastBackup == null) throw Exception('No backup');
  }

  @override
  Future<DateTime?> getLastBackupTime() async => _lastBackup;
}

void main() {
  late FakeSyncRepository fakeRepo;
  late SyncData syncData;

  setUp(() {
    fakeRepo = FakeSyncRepository();
    syncData = SyncData(fakeRepo);
  });

  group('SyncData.signIn', () {
    test('should return email on successful sign in', () async {
      final email = await syncData.signIn();
      expect(email, 'test@example.com');
      expect(await syncData.isSignedIn(), true);
    });
  });

  group('SyncData.backup', () {
    test('should throw StateError when not signed in', () async {
      expect(
        () => syncData.backup(),
        throwsA(isA<StateError>()),
      );
    });

    test('should return timestamp on successful backup when signed in', () async {
      await syncData.signIn();
      final timestamp = await syncData.backup();
      expect(timestamp, isA<DateTime>());
      expect(await syncData.getLastBackupTime(), timestamp);
    });
  });

  group('SyncData.restore', () {
    test('should throw StateError when not signed in', () async {
      expect(
        () => syncData.restore(),
        throwsA(isA<StateError>()),
      );
    });

    test('should delegate to repository when signed in', () async {
      await syncData.signIn();
      await syncData.backup(); // Create a backup first in fake
      
      // Should not throw
      await syncData.restore();
    });
  });
}
