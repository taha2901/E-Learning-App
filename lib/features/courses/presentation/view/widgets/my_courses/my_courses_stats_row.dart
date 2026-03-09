import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:flutter/material.dart';

class MyCoursesStatsRow extends StatelessWidget {
  final int enrolled;
  final int completed;

  const MyCoursesStatsRow({
    super.key,
    required this.enrolled,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            _StatItem(value: '$enrolled', label: 'Enrolled'),
            _Divider(),
            _StatItem(value: '$completed', label: 'Completed'),
            _Divider(),
            _StatItem(value: '$completed', label: 'Certificates'),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.displayMedium.copyWith(color: Colors.white)),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall
                .copyWith(color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}