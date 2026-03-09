// widgets/notifications_app_bar.dart

import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/notificatio/presentation/logic/notification_cubit.dart';
import 'package:e_learning/features/notificatio/presentation/logic/notification_states.dart';
import 'package:flutter/material.dart';

class NotificationsAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final NotificationState state;
  final NotificationCubit cubit;

  const NotificationsAppBar({
    super.key,
    required this.state,
    required this.cubit,
  });

  bool get _hasUnread =>
      state is NotificationLoaded &&
      (state as NotificationLoaded).unreadCount > 0;

  bool get _hasItems =>
      state is NotificationLoaded &&
      (state as NotificationLoaded).notifications.isNotEmpty;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      leading: _BackButton(),
      title: _AppBarTitle(state: state, hasUnread: _hasUnread),
      actions: [
        if (_hasUnread) _MarkAllReadButton(cubit: cubit),
        if (_hasItems) _MoreMenuButton(cubit: cubit, context: context),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Back Button
// ─────────────────────────────────────────────
class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
    );
  }
}

// ─────────────────────────────────────────────
// Title + unread count subtitle
// ─────────────────────────────────────────────
class _AppBarTitle extends StatelessWidget {
  final NotificationState state;
  final bool hasUnread;

  const _AppBarTitle({required this.state, required this.hasUnread});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notifications', style: AppTextStyles.h1),
        if (hasUnread)
          Text(
            '${(state as NotificationLoaded).unreadCount} unread',
            style:
                AppTextStyles.caption.copyWith(color: AppColors.primary),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Mark All Read Button
// ─────────────────────────────────────────────
class _MarkAllReadButton extends StatelessWidget {
  final NotificationCubit cubit;
  const _MarkAllReadButton({required this.cubit});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => cubit.markAllAsRead(),
      icon: const Icon(Icons.done_all_rounded, size: 16),
      label: Text(
        'Mark all read',
        style: AppTextStyles.caption.copyWith(color: AppColors.primary),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// More Menu (Clear All)
// ─────────────────────────────────────────────
class _MoreMenuButton extends StatelessWidget {
  final NotificationCubit cubit;
  final BuildContext context;

  const _MoreMenuButton({required this.cubit, required this.context});

  @override
  Widget build(BuildContext outerContext) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded,
          color: AppColors.textPrimary),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      onSelected: (val) {
        if (val == 'clear') _showClearDialog(outerContext);
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'clear',
          child: Row(
            children: [
              const Icon(Icons.delete_sweep_rounded,
                  color: AppColors.error, size: 18),
              const SizedBox(width: 8),
              Text('Clear all',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.error)),
            ],
          ),
        ),
      ],
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Clear All?', style: AppTextStyles.h2),
        content: Text(
          'This will permanently delete all your notifications.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
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
            child:
                Text('Clear All', style: AppTextStyles.labelMedium),
          ),
        ],
      ),
    );
  }
}