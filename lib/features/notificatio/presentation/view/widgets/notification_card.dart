import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/notificatio/data/model/notification_model.dart';
import 'package:e_learning/features/notificatio/presentation/view/widgets/notification_type_config.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: _SwipeDeleteBackground(),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: _CardContainer(notification: notification),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Swipe-to-delete red background
// ─────────────────────────────────────────────
class _SwipeDeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(Icons.delete_outline_rounded,
          color: AppColors.error, size: 26),
    );
  }
}

// ─────────────────────────────────────────────
// Animated card container
// ─────────────────────────────────────────────
class _CardContainer extends StatelessWidget {
  final NotificationModel notification;
  const _CardContainer({required this.notification});

  @override
  Widget build(BuildContext context) {
    final config = NotificationTypeConfig.from(notification.type);

    return AnimatedContainer(
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
          _TypeIcon(config: config),
          const SizedBox(width: 12),
          Expanded(
            child: _CardContent(
              notification: notification,
              config: config,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Type icon box (left side)
// ─────────────────────────────────────────────
class _TypeIcon extends StatelessWidget {
  final NotificationTypeConfig config;
  const _TypeIcon({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(config.icon, color: config.color, size: 22),
    );
  }
}

// ─────────────────────────────────────────────
// Card content (title + body + meta row)
// ─────────────────────────────────────────────
class _CardContent extends StatelessWidget {
  final NotificationModel notification;
  final NotificationTypeConfig config;

  const _CardContent({
    required this.notification,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TitleRow(notification: notification),
        const SizedBox(height: 4),
        Text(
          notification.body,
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        _MetaRow(notification: notification, config: config),
      ],
    );
  }
}

class _TitleRow extends StatelessWidget {
  final NotificationModel notification;
  const _TitleRow({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Row(
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
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  final NotificationModel notification;
  final NotificationTypeConfig config;

  const _MetaRow({
    required this.notification,
    required this.config,
  });

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TypeBadge(config: config),
        const SizedBox(width: 8),
        Text(
          _timeAgo(notification.createdAt),
          style: AppTextStyles.caption
              .copyWith(color: AppColors.textHint),
        ),
      ],
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final NotificationTypeConfig config;
  const _TypeBadge({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
    );
  }
}