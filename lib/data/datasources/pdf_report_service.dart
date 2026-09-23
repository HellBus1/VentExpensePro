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
import '../../domain/value_objects/billing_breakdown.dart';
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
    List<Account>? debtAccounts,
    List<Account>? creditCards,
    Map<String, BillingBreakdown>? billingBreakdowns,
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

    // Calculate Statistics
    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, double> expenseByCategory = {};

    for (final t in transactions) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
      } else if (t.type == TransactionType.expense) {
        totalExpense += t.amount;
        expenseByCategory[t.categoryId] = (expenseByCategory[t.categoryId] ?? 0) + t.amount;
      }
    }
    final netBalance = totalIncome - totalExpense;

    // Prepare Chart Data
    final List<pw.Dataset> chartDatasets = [];
    final List<PdfColor> chartColors = [
      _inkBlue, _inkGreen, _stampRed, PdfColors.amber700, PdfColors.teal, PdfColors.purple,
    ];
    int colorIndex = 0;

    final List<pw.Widget> legendWidgets = [];

    expenseByCategory.forEach((categoryId, amount) {
      final category = categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => const CategoryModel(id: '?', name: 'Unknown', icon: '?'),
      );
      final color = chartColors[colorIndex % chartColors.length];
      chartDatasets.add(
        pw.PieDataSet(
          value: amount,
          color: color,
          legend: null, // Disable built-in legend to avoid squishing
        ),
      );
      legendWidgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Container(width: 8, height: 8, decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle)),
              pw.SizedBox(width: 8),
              pw.Text(
                '${category.name} (${currencyFormatter.format(amount)})',
                style: pw.TextStyle(font: loraRegular, fontSize: 9, color: _inkDark),
              ),
            ],
          ),
        ),
      );
      colorIndex++;
    });

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
            pw.SizedBox(height: 16),

            // Statistics & Chart Section
            if (transactions.isNotEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  border: pw.Border.all(color: _inkLight, width: 0.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Summary Numbers
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _label('TOTAL INCOME', loraBold),
                          pw.Text('+${currencyFormatter.format(totalIncome)}', style: pw.TextStyle(font: monoRegular, fontSize: 14, color: _inkGreen)),
                          pw.SizedBox(height: 12),
                          _label('TOTAL EXPENSE', loraBold),
                          pw.Text('-${currencyFormatter.format(totalExpense)}', style: pw.TextStyle(font: monoRegular, fontSize: 14, color: _stampRed)),
                          pw.SizedBox(height: 12),
                          pw.Divider(color: _inkLight, thickness: 0.5),
                          pw.SizedBox(height: 8),
                          _label('NET BALANCE', loraBold),
                          pw.Text(
                            '${netBalance >= 0 ? '+' : ''}${currencyFormatter.format(netBalance)}',
                            style: pw.TextStyle(
                              font: monoRegular,
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: netBalance >= 0 ? _inkGreen : _stampRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 24),
                    // Pie Chart (Expense Breakdown)
                    if (expenseByCategory.isNotEmpty) ...[
                      pw.Expanded(
                        flex: 1,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            _label('BREAKDOWN', loraBold),
                            pw.SizedBox(height: 8),
                            pw.SizedBox(
                              height: 80,
                              width: 80,
                              child: pw.Chart(
                                grid: pw.PieGrid(),
                                datasets: chartDatasets,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 16),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: legendWidgets,
                        ),
                      ),
                    ],
                  ],
                ),
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
              }),
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

    // Add Debt Summary Page if debt accounts exist
    if (debtAccounts != null && debtAccounts.isNotEmpty) {
      _addDebtSummaryPage(
        pdf: pdf,
        debtAccounts: debtAccounts,
        allTransactions: transactions,
        loraRegular: loraRegular,
        loraBold: loraBold,
        monoRegular: monoRegular,
        currencyFormatter: currencyFormatter,
        formatter: formatter,
      );
    }

    // Add Credit Card Billing Page if credit cards exist
    if (creditCards != null && creditCards.isNotEmpty && billingBreakdowns != null && billingBreakdowns.isNotEmpty) {
      _addCreditCardBillingPage(
        pdf: pdf,
        creditCards: creditCards,
        billingBreakdowns: billingBreakdowns,
        loraRegular: loraRegular,
        loraBold: loraBold,
        monoRegular: monoRegular,
        currencyFormatter: currencyFormatter,
        formatter: formatter,
      );
    }

    final output = await getTemporaryDirectory();
    final fileName = 'vent_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  void _addDebtSummaryPage({
    required pw.Document pdf,
    required List<Account> debtAccounts,
    required List<Transaction> allTransactions,
    required pw.Font loraRegular,
    required pw.Font loraBold,
    required pw.Font monoRegular,
    required NumberFormat currencyFormatter,
    required DateFormat formatter,
  }) {
    final receivables = debtAccounts.where((a) => a.balance > 0).toList()
      ..sort((a, b) => b.balance.compareTo(a.balance));
    final payables = debtAccounts.where((a) => a.balance < 0).toList()
      ..sort((a, b) => a.balance.compareTo(b.balance));

    final totalReceivable = receivables.fold<int>(0, (sum, a) => sum + a.balance);
    final totalPayable = payables.fold<int>(0, (sum, a) => sum + a.balance.abs());
    final netDebtPosition = totalReceivable - totalPayable;

    final debtIds = debtAccounts.map((a) => a.id).toSet();
    final settlements = allTransactions
        .where((t) => t.isSettlement && (debtIds.contains(t.accountId) || debtIds.contains(t.toAccountId)))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

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
                pw.Text('VENTEXPENSE PRO', style: pw.TextStyle(font: loraBold, fontSize: 24, color: _inkBlue)),
                pw.Text('DEBT & LENDING SUMMARY', style: pw.TextStyle(font: monoRegular, fontSize: 10, color: _inkLight)),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: _inkBlue, thickness: 1),
            pw.SizedBox(height: 16),
          ],
        ),
        build: (context) => [
          // Net Position Overview Card
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: _inkLight, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _label('RECEIVABLE (THEY OWE YOU)', loraBold),
                    pw.Text('+${currencyFormatter.format(totalReceivable)}', style: pw.TextStyle(font: monoRegular, fontSize: 14, color: _inkGreen)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _label('PAYABLE (YOU OWE)', loraBold),
                    pw.Text('-${currencyFormatter.format(totalPayable)}', style: pw.TextStyle(font: monoRegular, fontSize: 14, color: _stampRed)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _label('NET DEBT POSITION', loraBold),
                    pw.Text(
                      '${netDebtPosition >= 0 ? '+' : ''}${currencyFormatter.format(netDebtPosition)}',
                      style: pw.TextStyle(
                        font: monoRegular,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: netDebtPosition >= 0 ? _inkGreen : _stampRed,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Receivables Table
          _sectionTitle('RECEIVABLE (PIUTANG)', loraBold),
          pw.SizedBox(height: 8),
          if (receivables.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Text('No outstanding receivables.', style: pw.TextStyle(font: loraRegular, fontSize: 10, color: _inkLight)),
            )
          else
            pw.Table(
              border: const pw.TableBorder(
                bottom: pw.BorderSide(color: _inkLight, width: 0.5),
                horizontalInside: pw.BorderSide(color: _inkLight, width: 0.2),
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(6),
                1: const pw.FlexColumnWidth(4),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _tableHeader('PERSON / ACCOUNT', monoRegular),
                    _tableHeader('AMOUNT', monoRegular, align: pw.Alignment.centerRight),
                  ],
                ),
                ...receivables.map((acc) => pw.TableRow(
                  children: [
                    _tableCell(acc.name, loraRegular),
                    _tableCell('+${currencyFormatter.format(acc.balance)}', monoRegular, color: _inkGreen, align: pw.Alignment.centerRight),
                  ],
                )),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _tableCell('Total Receivable', loraBold),
                    _tableCell('+${currencyFormatter.format(totalReceivable)}', monoRegular, color: _inkGreen, align: pw.Alignment.centerRight),
                  ],
                ),
              ],
            ),
          pw.SizedBox(height: 20),

          // Payables Table
          _sectionTitle('PAYABLE (HUTANG)', loraBold),
          pw.SizedBox(height: 8),
          if (payables.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 6),
              child: pw.Text('No outstanding payables.', style: pw.TextStyle(font: loraRegular, fontSize: 10, color: _inkLight)),
            )
          else
            pw.Table(
              border: const pw.TableBorder(
                bottom: pw.BorderSide(color: _inkLight, width: 0.5),
                horizontalInside: pw.BorderSide(color: _inkLight, width: 0.2),
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(6),
                1: const pw.FlexColumnWidth(4),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _tableHeader('PERSON / ACCOUNT', monoRegular),
                    _tableHeader('AMOUNT', monoRegular, align: pw.Alignment.centerRight),
                  ],
                ),
                ...payables.map((acc) => pw.TableRow(
                  children: [
                    _tableCell(acc.name, loraRegular),
                    _tableCell('-${currencyFormatter.format(acc.balance.abs())}', monoRegular, color: _stampRed, align: pw.Alignment.centerRight),
                  ],
                )),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    _tableCell('Total Payable', loraBold),
                    _tableCell('-${currencyFormatter.format(totalPayable)}', monoRegular, color: _stampRed, align: pw.Alignment.centerRight),
                  ],
                ),
              ],
            ),
          pw.SizedBox(height: 20),

          // Settlement History
          if (settlements.isNotEmpty) ...[
            _sectionTitle('RECENT SETTLEMENTS', loraBold),
            pw.SizedBox(height: 8),
            pw.Table(
              border: const pw.TableBorder(
                bottom: pw.BorderSide(color: _inkLight, width: 0.5),
                horizontalInside: pw.BorderSide(color: _inkLight, width: 0.2),
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(5),
                2: const pw.FlexColumnWidth(3),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _tableHeader('DATE', monoRegular),
                    _tableHeader('DESCRIPTION', monoRegular),
                    _tableHeader('AMOUNT', monoRegular, align: pw.Alignment.centerRight),
                  ],
                ),
                ...settlements.take(15).map((s) => pw.TableRow(
                  children: [
                    _tableCell(formatter.format(s.dateTime), loraRegular),
                    _tableCell(s.note ?? 'Debt Settlement', loraRegular),
                    _tableCell(currencyFormatter.format(s.amount), monoRegular, align: pw.Alignment.centerRight),
                  ],
                )),
              ],
            ),
          ],
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
  }

  void _addCreditCardBillingPage({
    required pw.Document pdf,
    required List<Account> creditCards,
    required Map<String, BillingBreakdown> billingBreakdowns,
    required pw.Font loraRegular,
    required pw.Font loraBold,
    required pw.Font monoRegular,
    required NumberFormat currencyFormatter,
    required DateFormat formatter,
  }) {
    int totalAllCards = 0;
    for (final card in creditCards) {
      final breakdown = billingBreakdowns[card.id];
      if (breakdown != null) {
        totalAllCards += breakdown.totalOutstanding;
      }
    }

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
                pw.Text('VENTEXPENSE PRO', style: pw.TextStyle(font: loraBold, fontSize: 24, color: _inkBlue)),
                pw.Text('CREDIT CARD BILLING SUMMARY', style: pw.TextStyle(font: monoRegular, fontSize: 10, color: _inkLight)),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: _inkBlue, thickness: 1),
            pw.SizedBox(height: 16),
          ],
        ),
        build: (context) => [
          // Total All Cards Card
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              border: pw.Border.all(color: _inkLight, width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _label('TOTAL CREDIT OUTSTANDING', loraBold),
                    pw.Text('Across ${creditCards.length} configured card${creditCards.length > 1 ? 's' : ''}', style: pw.TextStyle(font: loraRegular, fontSize: 10, color: _inkLight)),
                  ],
                ),
                pw.Text(
                  currencyFormatter.format(totalAllCards),
                  style: pw.TextStyle(
                    font: monoRegular,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: _stampRed,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Cards List
          ...creditCards.map((card) {
            final breakdown = billingBreakdowns[card.id];
            if (breakdown == null) return pw.SizedBox.shrink();

            final billedRange = breakdown.billedPeriod != null
                ? '${formatter.format(breakdown.billedPeriod!.start)} - ${formatter.format(breakdown.billedPeriod!.end)}'
                : 'Previous Cycle';
            final unbilledRange = breakdown.unbilledPeriod != null
                ? '${formatter.format(breakdown.unbilledPeriod!.start)} - ${formatter.format(breakdown.unbilledPeriod!.end)}'
                : 'Current Cycle';

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 16),
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                border: pw.Border.all(color: _inkLight, width: 0.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(card.name, style: pw.TextStyle(font: loraBold, fontSize: 13, color: _inkBlue)),
                      pw.Text('Statement Closes: ${card.statementCloseDay ?? '-'}th', style: pw.TextStyle(font: monoRegular, fontSize: 9, color: _inkLight)),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(color: _inkLight, thickness: 0.3),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _label('BILLED STATEMENT ($billedRange)', loraBold),
                          pw.Text(currencyFormatter.format(breakdown.billedAmount), style: pw.TextStyle(font: monoRegular, fontSize: 12, color: _stampRed)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          _label('UNBILLED CYCLE ($unbilledRange)', loraBold),
                          pw.Text(currencyFormatter.format(breakdown.unbilledAmount), style: pw.TextStyle(font: monoRegular, fontSize: 12, color: _inkDark)),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _label('TOTAL OUTSTANDING', loraBold),
                      pw.Text(
                        currencyFormatter.format(breakdown.totalOutstanding),
                        style: pw.TextStyle(font: monoRegular, fontSize: 13, fontWeight: pw.FontWeight.bold, color: _stampRed),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
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
  }

  pw.Widget _sectionTitle(String text, pw.Font font) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        font: font,
        fontSize: 11,
        color: _inkBlue,
        letterSpacing: 1.1,
      ),
    );
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
