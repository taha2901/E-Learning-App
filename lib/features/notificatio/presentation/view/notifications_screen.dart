// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// notification_screen.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/notificatio/data/model/notification_model.dart';
import 'package:e_learning/features/notificatio/presentation/logic/notification_cubit.dart';
import 'package:e_learning/features/notificatio/presentation/logic/notification_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        final cubit = context.read<NotificationCubit>();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(context, cubit, state),
          body: _buildBody(context, cubit, state),
        );
      },
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    NotificationCubit cubit,
    NotificationState state,
  ) {
    final hasUnread =
        state is NotificationLoaded && state.unreadCount > 0;

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 18,
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Notifications', style: AppTextStyles.h1),
          if (hasUnread)
            Text(
              '${(state as NotificationLoaded).unreadCount} unread',
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
        ],
      ),
      actions: [
        if (hasUnread)
          TextButton.icon(
            onPressed: () => cubit.markAllAsRead(),
            icon: const Icon(Icons.done_all_rounded, size: 16),
            label: Text(
              'Mark all read',
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
          ),
        if (state is NotificationLoaded && state.notifications.isNotEmpty)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
            color: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppColors.cardBorder),
            ),
            onSelected: (val) {
              if (val == 'clear') {
                _showClearDialog(context, cubit);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Text('Clear all',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody(
    BuildContext context,
    NotificationCubit cubit,
    NotificationState state,
  ) {
    if (state is NotificationLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state is NotificationError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(state.message, style: AppTextStyles.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => cubit.load(),
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

    if (state is NotificationLoaded) {
      if (state.notifications.isEmpty) return _buildEmpty();

      // Group by date
      final grouped = _groupByDate(state.notifications);

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: grouped.length,
        itemBuilder: (context, i) {
          final entry = grouped[i];

          if (entry is String) {
            // Date header
            return Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
              child: Text(
                entry,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            );
          }

          final notification = entry as NotificationModel;
          return _NotificationCard(
            notification: notification,
            onTap: () => cubit.markAsRead(notification.id),
            onDelete: () => cubit.deleteNotification(notification.id),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text('No Notifications Yet', style: AppTextStyles.h2),
          const SizedBox(height: 8),
          Text(
            "You're all caught up!\nWe'll notify you when something new happens.",
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Group by date ────────────────────────────────────────────────────────
  List<dynamic> _groupByDate(List<NotificationModel> notifications) {
    final result = <dynamic>[];
    String? lastLabel;

    for (final n in notifications) {
      final label = _dateLabel(n.createdAt);
      if (label != lastLabel) {
        result.add(label);
        lastLabel = label;
      }
      result.add(n);
    }
    return result;
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEEE').format(dt);
    return DateFormat('MMM d, yyyy').format(dt);
  }

  // ── Clear All Dialog ──────────────────────────────────────────────────────
  void _showClearDialog(BuildContext context, NotificationCubit cubit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Clear All?', style: AppTextStyles.h2),
        content: Text(
          'This will permanently delete all your notifications.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style:
                    AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              cubit.clearAll();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Clear All', style: AppTextStyles.labelMedium),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification Card
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final config = _typeConfig(notification.type);
    final timeStr = _timeAgo(notification.createdAt);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.error, size: 26),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notification.isRead
                ? AppColors.surface
                : AppColors.primary.withOpacity(0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: notification.isRead
                  ? AppColors.cardBorder
                  : AppColors.primary.withOpacity(0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: config.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(config.icon, color: config.color, size: 22),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.h3.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: config.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            config.label,
                            style: AppTextStyles.caption.copyWith(
                              color: config.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeStr,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _TypeConfig _typeConfig(NotificationType type) {
    switch (type) {
      case NotificationType.quiz:
        return _TypeConfig(
          icon: Icons.quiz_rounded,
          color: const Color(0xFF6C63FF),
          label: 'Quiz',
        );
      case NotificationType.course:
        return _TypeConfig(
          icon: Icons.play_circle_rounded,
          color: AppColors.primary,
          label: 'Course',
        );
      case NotificationType.achievement:
        return _TypeConfig(
          icon: Icons.workspace_premium_rounded,
          color: const Color(0xFFF59E0B),
          label: 'Achievement',
        );
      case NotificationType.general:
        return _TypeConfig(
          icon: Icons.notifications_rounded,
          color: AppColors.textSecondary,
          label: 'General',
        );
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

class _TypeConfig {
  final IconData icon;
  final Color color;
  final String label;
  const _TypeConfig({
    required this.icon,
    required this.color,
    required this.label,
  });
}