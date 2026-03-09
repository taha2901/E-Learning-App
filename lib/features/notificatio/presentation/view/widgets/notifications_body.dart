import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/notificatio/data/model/notification_model.dart';
import 'package:e_learning/features/notificatio/presentation/logic/notification_cubit.dart';
import 'package:e_learning/features/notificatio/presentation/logic/notification_states.dart';
import 'package:e_learning/features/notificatio/presentation/view/widgets/notification_card.dart';
import 'package:e_learning/features/notificatio/presentation/view/widgets/notification_date_grouper.dart';
import 'package:e_learning/features/notificatio/presentation/view/widgets/notifications_empty.dart';
import 'package:flutter/material.dart';

class NotificationsBody extends StatelessWidget {
  final NotificationState state;
  final NotificationCubit cubit;

  const NotificationsBody({
    super.key,
    required this.state,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    if (state is NotificationLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state is NotificationError) {
      return _ErrorBody(
        message: (state as NotificationError).message,
        onRetry: cubit.load,
      );
    }

    if (state is NotificationLoaded) {
      final notifications = (state as NotificationLoaded).notifications;
      if (notifications.isEmpty) return const NotificationsEmpty();
      return _NotificationList(notifications: notifications, cubit: cubit);
    }

    return const SizedBox.shrink();
  }
}

// ─────────────────────────────────────────────
// Error body
// ─────────────────────────────────────────────
class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBody({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 56, color: AppColors.textHint),
          const SizedBox(height: 12),
          Text(message, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Retry', style: AppTextStyles.labelMedium),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Grouped notification list
// ─────────────────────────────────────────────
class _NotificationList extends StatelessWidget {
  final List<NotificationModel> notifications;
  final NotificationCubit cubit;

  const _NotificationList({
    required this.notifications,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = NotificationDateGrouper.group(notifications);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: grouped.length,
      itemBuilder: (context, i) {
        final entry = grouped[i];

        // Date header
        if (entry is String) {
          return _DateHeader(label: entry);
        }

        final notification = entry as NotificationModel;
        return NotificationCard(
          notification: notification,
          onTap: () => cubit.markAsRead(notification.id),
          onDelete: () => cubit.deleteNotification(notification.id),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Date section header
// ─────────────────────────────────────────────
class _DateHeader extends StatelessWidget {
  final String label;
  const _DateHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textHint,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}