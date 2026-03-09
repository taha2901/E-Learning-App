// widgets/admin_back_button.dart

import 'package:e_learning/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Circular back button used consistently across all admin screens.
class AdminBackButton extends StatelessWidget {
  const AdminBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}