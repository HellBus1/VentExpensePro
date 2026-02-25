import '../datasources/pdf_report_service.dart';
import '../../domain/entities/account.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  final PdfReportService pdfService;

  ReportRepositoryImpl({
    required this.pdfService,
  });

  @override
  Future<String> generatePdf({
    required List<Transaction> transactions,
    required List<Account> accounts,
    required List<Category> categories,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return pdfService.generate(
      transactions: transactions,
      accounts: accounts,
      categories: categories,
      accountId: accountId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
