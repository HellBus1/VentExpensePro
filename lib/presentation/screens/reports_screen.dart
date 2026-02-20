import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../painters/paper_background.dart';

/// The reports screen — PDF / Excel generation and viewing.
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PaperBackground(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.description_outlined,
                size: 48,
                color: AppColors.disabled,
              ),
              const SizedBox(height: 16),
              Text(
                'Reports coming soon',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.inkLight,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Generate PDF & Excel ledger statements',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
