import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../painters/paper_background.dart';
import '../providers/account_provider.dart';
import '../providers/reports_provider.dart';

/// The reports screen — PDF / Excel generation and viewing.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PaperBackground(
      child: Consumer2<ReportsProvider, AccountProvider>(
        builder: (context, reportsProvider, accountProvider, child) {
          final DateFormat formatter = DateFormat('dd MMM yyyy');
          final String dateRangeLabel = reportsProvider.startDate != null &&
                  reportsProvider.endDate != null
              ? '${formatter.format(reportsProvider.startDate!)} - ${formatter.format(reportsProvider.endDate!)}'
              : 'All Time';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Professional Reports',
                  style: AppTypography.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Generate bank-ready statements and spreadsheets for your records.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.inkLight),
                ),
                const SizedBox(height: 32),

                // — Filter Section —
                _buildSectionTitle('REPORT FILTERS'),
                const SizedBox(height: 12),
                
                // Date Range Selector
                _buildFilterTile(
                  context,
                  label: 'PERIOD',
                  value: dateRangeLabel,
                  onTap: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      initialDateRange: reportsProvider.startDate != null &&
                              reportsProvider.endDate != null
                          ? DateTimeRange(
                              start: reportsProvider.startDate!,
                              end: reportsProvider.endDate!,
                            )
                          : null,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.inkBlue,
                              onPrimary: AppColors.paper,
                              onSurface: AppColors.inkDark,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (range != null) {
                      reportsProvider.setDateRange(range.start, range.end);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Account Selector
                _buildFilterTile(
                  context,
                  label: 'ACCOUNT',
                  value: reportsProvider.selectedAccountId == null
                      ? 'All Accounts'
                      : accountProvider.accounts
                          .firstWhere((a) => a.id == reportsProvider.selectedAccountId)
                          .name,
                  onTap: () {
                    _showAccountSelector(context, accountProvider, reportsProvider);
                  },
                ),

                const SizedBox(height: 40),

                // — Action Section —
                _buildSectionTitle('EXPORT FORMATS'),
                const SizedBox(height: 16),

                if (reportsProvider.status == ReportStatus.loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: CircularProgressIndicator(color: AppColors.inkBlue),
                    ),
                  )
                else ...[
                  _buildExportButton(
                    context,
                    label: 'Generate PDF Statement',
                    icon: Icons.picture_as_pdf_outlined,
                    onTap: () => _generate(context, reportsProvider, 'pdf'),
                  ),
                  const SizedBox(height: 12),
                  _buildExportButton(
                    context,
                    label: 'Export to Excel (.xlsx)',
                    icon: Icons.table_chart_outlined,
                    onTap: () => _generate(context, reportsProvider, 'excel'),
                  ),
                ],

                if (reportsProvider.status == ReportStatus.success) ...[
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.paperElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.inkGreen.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppColors.inkGreen, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ready to Save!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.inkDark,
                                    ),
                                  ),
                                  Text(
                                    'Report generated successfully.',
                                    style: AppTypography.bodySmall.copyWith(color: AppColors.inkLight),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final box = context.findRenderObject() as RenderBox?;
                              // ignore: deprecated_member_use
                              await Share.shareXFiles(
                                [XFile(reportsProvider.generatedFilePath!)],
                                text: 'VentExpense Report',
                                sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
                              );
                            },
                            icon: const Icon(Icons.share, size: 20),
                            label: const Text('Share or Save to Files'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.inkBlue,
                              foregroundColor: AppColors.paper,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (reportsProvider.status == ReportStatus.error) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Error: ${reportsProvider.errorMessage}',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.stampRed),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.label.copyWith(
        color: AppColors.inkLight,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildFilterTile(
    BuildContext context, {
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.paperElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.label.copyWith(fontSize: 9),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTypography.titleMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkLight),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.inkBlue,
          side: const BorderSide(color: AppColors.inkBlue),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTypography.titleMedium,
        ),
      ),
    );
  }

  void _showAccountSelector(
    BuildContext context,
    AccountProvider accProvider,
    ReportsProvider reportsProvider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Select Account', style: AppTypography.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('All Accounts'),
              trailing: reportsProvider.selectedAccountId == null ? const Icon(Icons.check, color: AppColors.inkBlue) : null,
              onTap: () {
                reportsProvider.setSelectedAccount(null);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            ...accProvider.accounts.map((account) => ListTile(
                  title: Text(account.name),
                  trailing: reportsProvider.selectedAccountId == account.id ? const Icon(Icons.check, color: AppColors.inkBlue) : null,
                  onTap: () {
                    reportsProvider.setSelectedAccount(account.id);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  void _generate(BuildContext context, ReportsProvider provider, String type) async {
    await provider.generate(type);
    if (!context.mounted) return;
    
    if (provider.status == ReportStatus.success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Report generated successfully!'),
            backgroundColor: AppColors.inkGreen,
            action: SnackBarAction(
              label: 'OK',
              textColor: AppColors.paper,
              onPressed: () {},
            ),
          ),
        );
      }
    } else if (provider.status == ReportStatus.error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: ${provider.errorMessage}'),
            backgroundColor: AppColors.stampRed,
          ),
        );
      }
    }
  }
}
