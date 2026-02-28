import 'package:get_it/get_it.dart';

import '../../data/datasources/google_drive_service.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/sync_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/calculate_net_position.dart';
import '../../domain/usecases/log_transaction.dart';
import '../../domain/usecases/manage_account.dart';
import '../../domain/usecases/manage_transaction.dart';
import '../../domain/usecases/settle_credit_bill.dart';
import '../../domain/usecases/sync_data.dart';
import '../../domain/usecases/generate_report.dart';
import '../../domain/repositories/report_repository.dart';
import '../../data/repositories/report_repository_impl.dart';
import '../../data/datasources/pdf_report_service.dart';

/// Global service locator instance.
final sl = GetIt.instance;

/// Registers all dependencies. Call once at app startup.
Future<void> initServiceLocator() async {
  // — Repositories —
  sl.registerLazySingleton<AccountRepository>(() => AccountRepositoryImpl());
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepositoryImpl(),
  );
  sl.registerLazySingleton<CategoryRepository>(() => CategoryRepositoryImpl());

  // — Google Drive Sync —
  sl.registerLazySingleton(() => GoogleDriveService());
  sl.registerLazySingleton<SyncRepository>(
    () => SyncRepositoryImpl(sl<GoogleDriveService>()),
  );

  // — Reports —
  sl.registerLazySingleton(() => PdfReportService());
  sl.registerLazySingleton<ReportRepository>(
    () => ReportRepositoryImpl(
      pdfService: sl<PdfReportService>(),
    ),
  );

  // — Use Cases —
  sl.registerFactory(() => CalculateNetPosition(sl<AccountRepository>()));
  sl.registerFactory(
    () => LogTransaction(sl<TransactionRepository>(), sl<AccountRepository>()),
  );
  sl.registerFactory(
    () =>
        SettleCreditBill(sl<TransactionRepository>(), sl<AccountRepository>()),
  );
  sl.registerFactory(() => ManageAccount(sl<AccountRepository>()));
  sl.registerFactory(
    () => ManageTransaction(
      sl<TransactionRepository>(),
      sl<AccountRepository>(),
      sl<LogTransaction>(),
    ),
  );
  sl.registerFactory(() => SyncData(sl<SyncRepository>()));
  sl.registerFactory(
    () => GenerateReport(
      reportRepository: sl<ReportRepository>(),
      transactionRepository: sl<TransactionRepository>(),
      accountRepository: sl<AccountRepository>(),
      categoryRepository: sl<CategoryRepository>(),
    ),
  );
}
