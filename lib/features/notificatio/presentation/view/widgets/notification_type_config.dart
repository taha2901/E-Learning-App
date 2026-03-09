// utils/notification_type_config.dart

import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/features/notificatio/data/model/notification_model.dart';
import 'package:flutter/material.dart';

/// Value object holding display properties for each notification type.
/// Extracted here so both [NotificationCard] and any future widgets
/// can use the same mapping without duplication.
class NotificationTypeConfig {
  final IconData icon;
  final Color color;
  final String label;

  const NotificationTypeConfig({
    required this.icon,
    required this.color,
    required this.label,
  });

  factory NotificationTypeConfig.from(NotificationType type) {
    switch (type) {
      case NotificationType.quiz:
        return const NotificationTypeConfig(
          icon: Icons.quiz_rounded,
          color: Color(0xFF6C63FF),
          label: 'Quiz',
        );
      case NotificationType.course:
        return NotificationTypeConfig(
          icon: Icons.play_circle_rounded,
          color: AppColors.primary,
          label: 'Course',
        );
      case NotificationType.achievement:
        return const NotificationTypeConfig(
          icon: Icons.workspace_premium_rounded,
          color: Color(0xFFF59E0B),
          label: 'Achievement',
        );
      case NotificationType.general:
        return NotificationTypeConfig(
          icon: Icons.notifications_rounded,
          color: AppColors.textSecondary,
          label: 'General',
        );
    }
  }
}