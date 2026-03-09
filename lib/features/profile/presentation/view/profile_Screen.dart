import 'package:e_learning/core/constants/app_constants.dart';
import 'package:e_learning/core/erros/app_error_widget.dart';
import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/core/widgets/stat_card.dart';
import 'package:e_learning/features/auth/presentaion/view/login_screen.dart';
import 'package:e_learning/features/notificatio/presentation/logic/notification_cubit.dart';
import 'package:e_learning/features/notificatio/presentation/logic/notification_states.dart';
import 'package:e_learning/features/notificatio/presentation/view/notifications_screen.dart';
import 'package:e_learning/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:e_learning/features/profile/presentation/cubit/profile_states.dart';
import 'package:e_learning/features/profile/presentation/view/widgets/profile/avatar_picker_sheet.dart';
import 'package:e_learning/features/profile/presentation/view/widgets/profile/certificates_sheet.dart';
import 'package:e_learning/features/profile/presentation/view/widgets/profile/edit_profile_sheet.dart';
import 'package:e_learning/features/profile/presentation/view/widgets/profile/menu_widgets.dart';
import 'package:e_learning/features/profile/presentation/view/widgets/profile/profile_header.dart';
import 'package:e_learning/features/profile/presentation/view/widgets/profile/watch_history_sheet.dart';
import 'package:e_learning/features/watchlist/presentation/view/saved_courses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatelessWidget {
  final String userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProfileCubit()..fetchUser(userId),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<ProfileCubit, ProfileStates>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProfileError) {
              return AppErrorWidget(
                exception: UnknownException(state.message),
                onRetry: () => context.read<ProfileCubit>().fetchUser(userId),
              );
            }

            if (state is ProfileLoaded) {
              final user = state.userData;
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: ProfileHeader(
                      user: user,
                      userId: userId,
                      onEditTap: () => _showEditProfile(context, user, userId),
                      onAvatarTap: () => _showAvatarPicker(context, userId),
                    ),
                  ),
                  SliverToBoxAdapter(child: _StatsRow(user: user)),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.horizontalPadding,
                      ),
                      child: _ProfileMenuSection(
                        user: user,
                        userId: userId,
                      ),
                    ),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  // ── Sheet helpers ────────────────────────────────────────

  void _showAvatarPicker(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AvatarPickerSheet(userId: userId),
    );
  }

  void _showEditProfile(
    BuildContext context,
    Map<String, dynamic> user,
    String userId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EditProfileSheet(user: user, userId: userId),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Row
// ─────────────────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final Map<String, dynamic> user;
  const _StatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.horizontalPadding,
      ),
      child: Row(
        children: [
          StatCard(
            value: '${user['enrolled_courses_count'] ?? 0}',
            label: 'Enrolled',
            icon: Icons.play_circle_outline_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          StatCard(
            value: '${user['completed_courses_count'] ?? 0}',
            label: 'Completed',
            icon: Icons.check_circle_outline_rounded,
            color: AppColors.success,
          ),
          const SizedBox(width: 12),
          StatCard(
            value: '${user['certificates_count'] ?? 0}',
            label: 'Certificates',
            icon: Icons.workspace_premium_outlined,
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu Section  (Account / Learning / Support + Logout)
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileMenuSection extends StatelessWidget {
  final Map<String, dynamic> user;
  final String userId;

  const _ProfileMenuSection({required this.user, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account', style: AppTextStyles.h2),
        const SizedBox(height: 12),
        MenuGroup(
          items: [
            MenuItem(
              icon: Icons.person_outline_rounded,
              label: 'Edit Profile',
              onTap: () => _showEditProfile(context, user, userId),
            ),
            MenuItem(
              icon: Icons.notifications_outlined,
              label: 'Notifications',
              trailing: _NotificationsBadge(),
              onTap: () => _goToNotifications(context),
            ),
            MenuItem(
              icon: Icons.lock_outline_rounded,
              label: 'Privacy & Security',
              onTap: () {},
            ),
            MenuItem(
              icon: Icons.bookmark_rounded,
              label: 'Saved Courses',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SavedCoursesScreen(userId: userId),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Learning', style: AppTextStyles.h2),
        const SizedBox(height: 12),
        MenuGroup(
          items: [
            MenuItem(
              icon: Icons.workspace_premium_outlined,
              label: 'My Certificates',
              onTap: () => _showCertificates(context, user, userId),
            ),
            MenuItem(
              icon: Icons.history_rounded,
              label: 'Watch History',
              onTap: () => _showWatchHistory(context, userId),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Support', style: AppTextStyles.h2),
        const SizedBox(height: 12),
        MenuGroup(
          items: [
            MenuItem(
              icon: Icons.help_outline_rounded,
              label: 'Help Center',
              onTap: () {},
            ),
            MenuItem(
              icon: Icons.info_outline_rounded,
              label: 'About LearnFlow',
              onTap: () => _showAbout(context),
            ),
          ],
        ),
        const SizedBox(height: 24),
        LogoutButton(
          onTap: () => _logout(context),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Navigation helpers ───────────────────────────────────

  void _goToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<NotificationCubit>(),
          child: const NotificationsScreen(),
        ),
      ),
    );
  }

  void _showCertificates(
    BuildContext context,
    Map<String, dynamic> user,
    String userId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => CertificatesSheet(userId: userId, user: user),
    );
  }

  void _showWatchHistory(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => WatchHistorySheet(userId: userId),
    );
  }

  void _showEditProfile(
    BuildContext context,
    Map<String, dynamic> user,
    String userId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => EditProfileSheet(user: user, userId: userId),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.school_rounded,
                  color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Text('LearnFlow', style: AppTextStyles.h2),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0', style: AppTextStyles.bodySmall),
            const SizedBox(height: 8),
            Text(
              'LearnFlow helps you learn new skills with high-quality courses.',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    context.read<NotificationCubit>().close();
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }
}

// ─────────────────────────────────────────────
// Notifications Badge  (reads from NotificationCubit)
// ─────────────────────────────────────────────
class _NotificationsBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      builder: (context, state) {
        final count =
            state is NotificationLoaded ? state.unreadCount : 0;
        return count > 0
            ? BadgeWidget(count: count)
            : const SizedBox.shrink();
      },
    );
  }
}