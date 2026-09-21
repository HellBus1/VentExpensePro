import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vent_expense_pro/core/di/service_locator.dart';
import 'package:vent_expense_pro/data/datasources/local_database.dart';
import 'package:vent_expense_pro/domain/repositories/sync_repository.dart';
import 'package:vent_expense_pro/domain/usecases/sync_data.dart';

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

/// Initializes dependencies and resets the database for an integration test.
Future<void> setupIntegrationTestEnvironment() async {
  SharedPreferences.setMockInitialValues({});
  sl.allowReassignment = true;

  if (!sl.isRegistered<SyncRepository>()) {
    await initServiceLocator();
  }

  final fakeRepo = FakeIntegrationSyncRepository();
  sl.registerLazySingleton<SyncRepository>(() => fakeRepo);
  sl.registerFactory<SyncData>(() => SyncData(fakeRepo));

  await LocalDatabase.resetForTesting();
}
