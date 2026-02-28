import 'package:flutter/material.dart';
import '../../domain/usecases/generate_report.dart';

enum ReportStatus { idle, loading, success, error }

class ReportsProvider extends ChangeNotifier {
  final GenerateReport generateReportUseCase;

  ReportsProvider(this.generateReportUseCase);

  ReportStatus _status = ReportStatus.idle;
  ReportStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _generatedFilePath;
  String? get generatedFilePath => _generatedFilePath;

  DateTime? _startDate;
  DateTime? get startDate => _startDate;

  DateTime? _endDate;
  DateTime? get endDate => _endDate;

  String? _selectedAccountId;
  String? get selectedAccountId => _selectedAccountId;

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  void setSelectedAccount(String? accountId) {
    _selectedAccountId = accountId;
    notifyListeners();
  }

  Future<void> generate(String type) async {
    _status = ReportStatus.loading;
    _errorMessage = null;
    _generatedFilePath = null;
    notifyListeners();

    try {
      final path = await generateReportUseCase(
        type: type,
        accountId: _selectedAccountId,
        startDate: _startDate,
        endDate: _endDate,
      );
      _generatedFilePath = path;
      _status = ReportStatus.success;
    } catch (e) {
      _errorMessage = e.toString();
      _status = ReportStatus.error;
    } finally {
      notifyListeners();
    }
  }

  void reset() {
    _status = ReportStatus.idle;
    _errorMessage = null;
    _generatedFilePath = null;
    notifyListeners();
  }
}
