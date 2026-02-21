import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/entities/account.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/transaction.dart';
import '../models/category_model.dart';

class PdfReportService {
  static const PdfColor _paper = PdfColor.fromInt(0xFFFFF8F0);
  static const PdfColor _inkBlue = PdfColor.fromInt(0xFF1B3A5C);
  static const PdfColor _inkDark = PdfColor.fromInt(0xFF2C2C2C);
  static const PdfColor _inkLight = PdfColor.fromInt(0xFF7A7570);
  static const PdfColor _stampRed = PdfColor.fromInt(0xFFC0392B);
  static const PdfColor _inkGreen = PdfColor.fromInt(0xFF27774E);

  Future<String> generate({
    required List<Transaction> transactions,
    required List<Account> accounts,
    required List<Category> categories,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final pdf = pw.Document();

    // Load fonts
    final loraRegular = pw.Font.ttf(await rootBundle.load('assets/fonts/Lora-Regular.ttf'));
    final loraBold = pw.Font.ttf(await rootBundle.load('assets/fonts/Lora-Bold.ttf'));
    final monoRegular = pw.Font.ttf(await rootBundle.load('assets/fonts/JetBrainsMono-Regular.ttf'));

    final DateFormat formatter = DateFormat('dd MMM yyyy');
    final NumberFormat currencyFormatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: 0,
    );

    final accountName = accountId != null 
        ? accounts.firstWhere((a) => a.id == accountId).name 
        : 'All accounts';

    final dateRangeStr = (startDate != null && endDate != null)
        ? '${formatter.format(startDate)} - ${formatter.format(endDate)}'
        : 'All Time';

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Container(color: _paper),
          ),
        ),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'VENTEXPENSE PRO',
                  style: pw.TextStyle(
                    font: loraBold,
                    fontSize: 24,
                    color: _inkBlue,
                  ),
                ),
                pw.Text(
                  'LEDGER STATEMENT',
                  style: pw.TextStyle(
                    font: monoRegular,
                    fontSize: 10,
                    color: _inkLight,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: _inkBlue, thickness: 1),
            pw.SizedBox(height: 16),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _label('ACCOUNT', loraBold),
                      pw.Text(accountName, style: pw.TextStyle(font: loraRegular, fontSize: 14)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _label('PERIOD', loraBold),
                      pw.Text(dateRangeStr, style: pw.TextStyle(font: loraRegular, fontSize: 14)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _label('GENERATED AT', loraBold),
                      pw.Text(formatter.format(DateTime.now()), style: pw.TextStyle(font: loraRegular, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),
          ],
        ),
        build: (context) => [
          pw.Table(
            border: const pw.TableBorder(
              bottom: pw.BorderSide(color: _inkLight, width: 0.5),
              horizontalInside: pw.BorderSide(color: _inkLight, width: 0.2),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(2), // Date
              1: const pw.FlexColumnWidth(3), // Category
              2: const pw.FlexColumnWidth(4), // Note
              3: const pw.FlexColumnWidth(2.5), // Amount
            },
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _tableHeader('DATE', monoRegular),
                  _tableHeader('CATEGORY', monoRegular),
                  _tableHeader('NOTE', monoRegular),
                  _tableHeader('AMOUNT', monoRegular, align: pw.Alignment.centerRight),
                ],
              ),
              // Data
              ...transactions.map((t) {
                final category = categories.firstWhere(
                  (c) => c.id == t.categoryId,
                  orElse: () => const CategoryModel(id: '?', name: 'Unknown', icon: '?'),
                );
                final isPositive = t.type == TransactionType.income;
                final amountColor = isPositive ? _inkGreen : _stampRed;
                final amountPrefix = isPositive ? '+' : '-';

                return pw.TableRow(
                  children: [
                    _tableCell(DateFormat('dd/MM/yy').format(t.dateTime), loraRegular),
                    _tableCell(category.name, loraRegular),
                    _tableCell(t.note ?? '-', loraRegular),
                    _tableCell(
                      '$amountPrefix${currencyFormatter.format(t.amount)}',
                      monoRegular,
                      color: amountColor,
                      align: pw.Alignment.centerRight,
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(font: loraRegular, fontSize: 10, color: _inkLight),
          ),
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final fileName = 'vent_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  pw.Widget _label(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 8, color: _inkLight, letterSpacing: 1.2),
      ),
    );
  }

  pw.Widget _tableHeader(String text, pw.Font font, {pw.Alignment align = pw.Alignment.centerLeft}) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 9, fontWeight: pw.FontWeight.bold, color: _inkDark),
      ),
    );
  }

  pw.Widget _tableCell(String text, pw.Font font, {pw.Alignment align = pw.Alignment.centerLeft, PdfColor color = _inkDark}) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 10, color: color),
      ),
    );
  }
}
