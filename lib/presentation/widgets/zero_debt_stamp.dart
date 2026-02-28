import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// A subtle inline badge indicating the user is debt-free.
class ZeroDebtStamp extends StatelessWidget {
  const ZeroDebtStamp({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inkGreen.withValues(alpha: 0.1),
        border: Border.all(color: AppColors.inkGreen.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 12, color: AppColors.inkGreen),
          const SizedBox(width: 4),
          Text(
            'DEBT FREE',
            style: AppTypography.label.copyWith(
              color: AppColors.inkGreen,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
