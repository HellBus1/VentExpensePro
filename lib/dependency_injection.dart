import 'package:get_it/get_it.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vent_expense_pro/data/sqflite/sqflite_helper.dart';
import 'package:vent_expense_pro/repositories/impl/wallet_repository_impl.dart';
import 'package:vent_expense_pro/repositories/wallet_repository.dart';
import 'package:vent_expense_pro/screens/wallet/provider/wallet_provider.dart';
import 'package:vent_expense_pro/services/wallet_service.dart';

final GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
  // Register Database as an async singleton
  locator.registerSingletonAsync<Database>(() async => SQFLiteHelper.instance.database);

  // Register other dependencies after the async registration
  _registerRepositories();
  _registerServices();
  _registerProviders();

  // Wait until all async singletons are ready
  await locator.allReady();
}

void _registerRepositories() {
  locator.registerSingletonAsync<WalletRepository>(
    () async => WalletRepositoryImpl(await locator.getAsync<Database>()),
    dependsOn: [Database],
  );
}

void _registerServices() {
  locator.registerSingletonAsync<WalletService>(
    () async => WalletService(await locator.getAsync<WalletRepository>()),
    dependsOn: [WalletRepository],
  );
}

void _registerProviders() {
  locator.registerFactory<WalletProvider>(
    () => WalletProvider(locator<WalletService>()),
  );
}
