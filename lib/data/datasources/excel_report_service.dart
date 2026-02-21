import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/account.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/transaction.dart';
import '../models/category_model.dart';

class ExcelReportService {
  Future<String> generate({
    required List<Transaction> transactions,
    required List<Account> accounts,
    required List<Category> categories,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['Ledger Report'];

    final accountName = accountId != null 
        ? accounts.firstWhere((a) => a.id == accountId).name 
        : 'All accounts';

    // Summary Header
    sheet.appendRow([TextCellValue('VentExpense Pro Ledger Statement')]);
    sheet.appendRow([TextCellValue('Account: $accountName')]);
    sheet.appendRow([
      TextCellValue('Period: ${startDate != null ? DateFormat('dd/MM/yyyy').format(startDate) : 'Start'} - ${endDate != null ? DateFormat('dd/MM/yyyy').format(endDate) : 'Present'}')
    ]);
    sheet.appendRow([]); // Empty spacer

    // Table Header
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Type'),
      TextCellValue('Category'),
      TextCellValue('Account'),
      TextCellValue('To Account'),
      TextCellValue('Note'),
      TextCellValue('Amount'),
      TextCellValue('Is Settlement'),
    ]);

    // Data Rows
    for (final t in transactions) {
      final category = categories.firstWhere(
        (c) => c.id == t.categoryId,
        orElse: () => const CategoryModel(id: '?', name: 'Unknown', icon: '?'),
      );
      final account = accounts.firstWhere((a) => a.id == t.accountId);
      final toAccount = t.toAccountId != null 
          ? accounts.firstWhere((a) => a.id == t.toAccountId).name 
          : '-';

      sheet.appendRow([
        TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(t.dateTime)),
        TextCellValue(t.type.toString().split('.').last.toUpperCase()),
        TextCellValue(category.name),
        TextCellValue(account.name),
        TextCellValue(toAccount),
        TextCellValue(t.note ?? ''),
        IntCellValue(t.type == TransactionType.expense ? -t.amount : t.amount),
        TextCellValue(t.isSettlement ? 'Yes' : 'No'),
      ]);
    }

    final output = await getTemporaryDirectory();
    final fileName = 'vent_report_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final path = '${output.path}/$fileName';
    
    final fileBytes = excel.save();
    if (fileBytes != null) {
      await File(path).writeAsBytes(fileBytes);
    }

    return path;
  }
}
