import '../entities/account.dart';
import '../entities/category.dart';
import '../entities/transaction.dart';

/// Contract for generating platform-specific report files.
abstract class ReportRepository {
  /// Generates a PDF statement. Returns the file path of the generated report.
  Future<String> generatePdf({
    required List<Transaction> transactions,
    required List<Account> accounts,
    required List<Category> categories,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  });

}
