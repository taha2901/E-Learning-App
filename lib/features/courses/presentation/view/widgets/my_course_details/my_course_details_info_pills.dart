import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:flutter/material.dart';

class MyCourseDetailsInfoPills extends StatelessWidget {
  final String instructor;
  final String duration;
  final String level;

  const MyCourseDetailsInfoPills({
    super.key,
    required this.instructor,
    required this.duration,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _InfoPill(icon: Icons.person_outline_rounded, label: instructor),
        const SizedBox(width: 8),
        _InfoPill(icon: Icons.schedule_outlined, label: duration),
        const SizedBox(width: 8),
        _InfoPill(icon: Icons.signal_cellular_alt_rounded, label: level),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}