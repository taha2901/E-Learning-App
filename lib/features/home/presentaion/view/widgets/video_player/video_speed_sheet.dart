import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:flutter/material.dart';

class VideoSpeedSheet extends StatelessWidget {
  final double currentSpeed;
  final List<double> speeds;
  final ValueChanged<double> onSpeedSelected;

  const VideoSpeedSheet({
    super.key,
    required this.currentSpeed,
    required this.speeds,
    required this.onSpeedSelected,
  });

  static void show(
    BuildContext context, {
    required double currentSpeed,
    required List<double> speeds,
    required ValueChanged<double> onSpeedSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => VideoSpeedSheet(
        currentSpeed: currentSpeed,
        speeds: speeds,
        onSpeedSelected: onSpeedSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(100),
            ),
          ),
          const SizedBox(height: 16),
          Text('Playback Speed', style: AppTextStyles.h2),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: speeds.map((s) {
              final selected = s == currentSpeed;
              return GestureDetector(
                onTap: () {
                  onSpeedSelected(s);
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color:
                        selected ? AppColors.primary : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Text(
                    '${s}x',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}