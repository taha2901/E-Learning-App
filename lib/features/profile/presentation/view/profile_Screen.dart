import 'dart:io';
import 'package:e_learning/core/constants/app_constants.dart';
import 'package:e_learning/core/erros/app_error_widget.dart';
import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/core/widgets/stat_card.dart';
import 'package:e_learning/features/auth/presentaion/view/login_screen.dart';
import 'package:e_learning/features/notificatio/presentation/logic/notification_cubit.dart';
import 'package:e_learning/features/notificatio/presentation/logic/notification_states.dart';
import 'package:e_learning/features/notificatio/presentation/view/notifications_screen.dart';
import 'package:e_learning/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:e_learning/features/profile/presentation/cubit/profile_states.dart';
import 'package:e_learning/features/profile/presentation/view/certificate_screen.dart';
import 'package:e_learning/features/watchlist/presentation/view/saved_courses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
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

            // ✅ Error State — AppErrorWidget مع Retry
            if (state is ProfileError) {
              return AppErrorWidget(
                exception: UnknownException(state.message),
                onRetry: () =>
                    context.read<ProfileCubit>().fetchUser(userId),
              );
            }

            if (state is ProfileLoaded) {
              final user = state.userData;
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _ProfileHeader(
                      user: user,
                      userId: userId,
                      onEditTap: () =>
                          _showEditDialog(context, user, userId),
                      onAvatarTap: () =>
                          _pickAndUploadAvatar(context, userId),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.horizontalPadding,
                      ),
                      child: Row(
                        children: [
                          StatCard(
                            value:
                                '${user['enrolled_courses_count'] ?? 0}',
                            label: 'Enrolled',
                            icon: Icons.play_circle_outline_rounded,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          StatCard(
                            value:
                                '${user['completed_courses_count'] ?? 0}',
                            label: 'Completed',
                            icon: Icons.check_circle_outline_rounded,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 12),
                          StatCard(
                            value:
                                '${user['certificates_count'] ?? 0}',
                            label: 'Certificates',
                            icon: Icons.workspace_premium_outlined,
                            color: AppColors.warning,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 28)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.horizontalPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Account', style: AppTextStyles.h2),
                          const SizedBox(height: 12),
                          _MenuGroup(
                            items: [
                              _MenuItem(
                                icon: Icons.person_outline_rounded,
                                label: 'Edit Profile',
                                onTap: () => _showEditDialog(
                                    context, user, userId),
                              ),
                              _MenuItem(
                                icon: Icons.notifications_outlined,
                                label: 'Notifications',
                                trailing: BlocBuilder<NotificationCubit,
                                    NotificationState>(
                                  builder: (context, state) {
                                    final count =
                                        state is NotificationLoaded
                                            ? state.unreadCount
                                            : 0;
                                    return count > 0
                                        ? _Badge(count: count)
                                        : const SizedBox.shrink();
                                  },
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => BlocProvider.value(
                                      value: context
                                          .read<NotificationCubit>(),
                                      child:
                                          const NotificationsScreen(),
                                    ),
                                  ),
                                ),
                              ),
                              _MenuItem(
                                icon: Icons.lock_outline_rounded,
                                label: 'Privacy & Security',
                                onTap: () {},
                              ),
                              _MenuItem(
                                icon: Icons.bookmark_rounded,
                                label: 'Saved Courses',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        SavedCoursesScreen(userId: userId),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text('Learning', style: AppTextStyles.h2),
                          const SizedBox(height: 12),
                          _MenuGroup(
                            items: [
                              _MenuItem(
                                icon: Icons.workspace_premium_outlined,
                                label: 'My Certificates',
                                onTap: () => _showCertificates(
                                    context, user, userId),
                              ),
                              _MenuItem(
                                icon: Icons.history_rounded,
                                label: 'Watch History',
                                onTap: () =>
                                    _showWatchHistory(context, userId),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text('Support', style: AppTextStyles.h2),
                          const SizedBox(height: 12),
                          _MenuGroup(
                            items: [
                              _MenuItem(
                                icon: Icons.help_outline_rounded,
                                label: 'Help Center',
                                onTap: () {},
                              ),
                              _MenuItem(
                                icon: Icons.info_outline_rounded,
                                label: 'About LearnFlow',
                                onTap: () => _showAbout(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _LogoutButton(
                            onTap: () async {
                              context.read<NotificationCubit>().close();
                              await Supabase.instance.client.auth
                                  .signOut();
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                  (_) => false,
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 40),
                        ],
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

  void _pickAndUploadAvatar(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 20),
              Text('Change Photo', style: AppTextStyles.h2),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SourceTile(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () async {
                        Navigator.pop(ctx);
                        final picked = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                          imageQuality: 80,
                        );
                        if (picked != null && context.mounted) {
                          context.read<ProfileCubit>().updateAvatar(
                                userId: userId,
                                image: File(picked.path),
                              );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceTile(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      onTap: () async {
                        Navigator.pop(ctx);
                        final picked = await ImagePicker().pickImage(
                          source: ImageSource.camera,
                          imageQuality: 80,
                        );
                        if (picked != null && context.mounted) {
                          context.read<ProfileCubit>().updateAvatar(
                                userId: userId,
                                image: File(picked.path),
                              );
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    Map<String, dynamic> user,
    String userId,
  ) {
    final nameCtrl =
        TextEditingController(text: user['name']?.toString() ?? '');
    final bioCtrl =
        TextEditingController(text: user['bio']?.toString() ?? '');
    final phoneCtrl =
        TextEditingController(text: user['phone']?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24, 24, 24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Edit Profile', style: AppTextStyles.h2),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _EditField(
              controller: nameCtrl,
              label: 'Full Name',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 14),
            _EditField(
              controller: phoneCtrl,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            _EditField(
              controller: bioCtrl,
              label: 'Bio',
              icon: Icons.edit_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await context.read<ProfileCubit>().updateProfile(
                        userId: userId,
                        name: nameCtrl.text.trim(),
                        bio: bioCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                      );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text('Save Changes',
                    style: AppTextStyles.labelLarge),
              ),
            ),
          ],
        ),
      ),
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
      builder: (_) => _WatchHistorySheet(userId: userId),
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
      builder: (_) => _CertificatesSheet(userId: userId, user: user),
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
            child:
                Text('Close', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Certificates Sheet — with error handling
// ─────────────────────────────────────────────────────────────────────────────
class _CertificatesSheet extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> user;
  const _CertificatesSheet(
      {required this.userId, required this.user});

  @override
  State<_CertificatesSheet> createState() => _CertificatesSheetState();
}

class _CertificatesSheetState extends State<_CertificatesSheet> {
  List<Map<String, dynamic>> _completedCourses = [];
  bool _loading = true;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    _loadCompletedCourses();
  }

  Future<void> _loadCompletedCourses() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final enrollmentsRaw = await Supabase.instance.client
          .from('enrollments')
          .select('course_id, completed_at')
          .eq('user_id', widget.userId)
          .not('completed_at', 'is', null)
          .order('completed_at', ascending: false);

      final enrollments =
          (enrollmentsRaw as List).cast<Map<String, dynamic>>();

      if (enrollments.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final courseIds =
          enrollments.map((e) => e['course_id'] as String).toList();

      final coursesRaw = await Supabase.instance.client
          .from('courses')
          .select('id, title, instructor')
          .inFilter('id', courseIds);

      final coursesMap = {
        for (final c in (coursesRaw as List).cast<Map<String, dynamic>>())
          c['id'] as String: c,
      };

      final merged = enrollments.map((e) {
        final courseId = e['course_id'] as String;
        final course = coursesMap[courseId] ?? {};
        return {
          'course_id': courseId,
          'completed_at': e['completed_at'],
          'courses': course,
        };
      }).toList();

      setState(() {
        _completedCourses = merged;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = NetworkExceptionHandler.handle(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (ctx, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorder,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('My Certificates', style: AppTextStyles.h2),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_loading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              // ✅ Error state مع Retry
              Expanded(
                child: AppErrorWidget(
                  exception: _error!,
                  onRetry: _loadCompletedCourses,
                ),
              )
            else if (_completedCourses.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.workspace_premium_outlined,
                        size: 56,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Complete a course to earn your first certificate!',
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  itemCount: _completedCourses.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final enrollment = _completedCourses[i];
                    final course = enrollment['courses']
                            as Map<String, dynamic>? ??
                        {};
                    final courseTitle =
                        course['title']?.toString() ??
                            'Course #${i + 1}';
                    final instructor =
                        course['instructor']?.toString() ??
                            'Instructor';
                    final completedAt = DateTime.tryParse(
                          enrollment['completed_at']?.toString() ??
                              '',
                        ) ??
                        DateTime.now();
                    final studentName =
                        widget.user['name']?.toString() ?? 'Student';
                    final certId =
                        'LF-${enrollment['course_id'].toString().substring(0, 8).toUpperCase()}';

                    return _CertificateListTile(
                      index: i + 1,
                      courseTitle: courseTitle,
                      completedAt: completedAt,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CertificateScreen(
                              data: CertificateData(
                                studentName: studentName,
                                courseName: courseTitle,
                                instructorName: instructor,
                                completionDate: completedAt,
                                certificateId: certId,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Certificate List Tile
// ─────────────────────────────────────────────
class _CertificateListTile extends StatelessWidget {
  final int index;
  final String courseTitle;
  final DateTime completedAt;
  final VoidCallback onTap;

  const _CertificateListTile({
    required this.index,
    required this.courseTitle,
    required this.completedAt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${completedAt.day}/${completedAt.month}/${completedAt.year}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: AppColors.warning, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Certificate of Completion #$index',
                      style: AppTextStyles.h3),
                  const SizedBox(height: 2),
                  Text(courseTitle,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('Completed $dateStr',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textHint)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  color: AppColors.primary, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Profile Header
// ─────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> user;
  final String userId;
  final VoidCallback onEditTap;
  final VoidCallback onAvatarTap;
  const _ProfileHeader({
    required this.user,
    required this.userId,
    required this.onEditTap,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user['avatar_url']?.toString() ?? '';
    final name = user['name']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';
    final bio = user['bio']?.toString() ?? '';
    final phone = user['phone']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppConstants.horizontalPadding, 0,
          AppConstants.horizontalPadding, 28),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Profile', style: AppTextStyles.h1),
                IconButton(
                  icon: const Icon(Icons.settings_outlined,
                      color: AppColors.textPrimary),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onAvatarTap,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    backgroundImage: avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl.isEmpty
                        ? Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : 'U',
                            style: AppTextStyles.h1
                                .copyWith(color: AppColors.primary),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 30, height: 30,
                      decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(name, style: AppTextStyles.h1),
            const SizedBox(height: 4),
            Text(email,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.primary)),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone_outlined,
                      size: 14, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(phone,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ],
            if (bio.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(bio,
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Edit Field
// ─────────────────────────────────────────────
class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  const _EditField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(icon),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Source Tile
// ─────────────────────────────────────────────
class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.primary.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 30),
            const SizedBox(height: 8),
            Text(label,
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Watch History Sheet — with error handling
// ─────────────────────────────────────────────
class _WatchHistorySheet extends StatefulWidget {
  final String userId;
  const _WatchHistorySheet({required this.userId});

  @override
  State<_WatchHistorySheet> createState() => _WatchHistorySheetState();
}

class _WatchHistorySheetState extends State<_WatchHistorySheet> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await Supabase.instance.client
          .from('video_progress')
          .select(
            'video_id, watched_at, videos(title, duration, courses(title))',
          )
          .eq('user_id', widget.userId)
          .eq('watched', true)
          .order('watched_at', ascending: false)
          .limit(20);
      setState(() {
        _history = (result as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = NetworkExceptionHandler.handle(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (ctx, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          children: [
            Row(
              children: [
                Text('Watch History', style: AppTextStyles.h2),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Expanded(
                  child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              // ✅ Error state مع Retry
              Expanded(
                child: AppErrorWidget(
                  exception: _error!,
                  onRetry: _load,
                ),
              )
            else if (_history.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_rounded,
                          size: 56, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      Text('No watch history yet',
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  controller: scrollCtrl,
                  itemCount: _history.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppColors.divider),
                  itemBuilder: (_, i) {
                    final item = _history[i];
                    final video =
                        item['videos'] as Map<String, dynamic>? ?? {};
                    final course =
                        video['courses'] as Map<String, dynamic>? ?? {};
                    final watchedAt =
                        DateTime.tryParse(item['watched_at'] ?? '') ??
                            DateTime.now();
                    final diff = DateTime.now().difference(watchedAt);
                    final timeAgo = diff.inDays > 0
                        ? '${diff.inDays}d ago'
                        : diff.inHours > 0
                            ? '${diff.inHours}h ago'
                            : 'Recently';

                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 8),
                      leading: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.play_circle_outline_rounded,
                            color: AppColors.primary),
                      ),
                      title: Text(video['title'] ?? 'Unknown video',
                          style: AppTextStyles.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${course['title'] ?? ''} • ${video['duration'] ?? ''}',
                        style: AppTextStyles.caption,
                      ),
                      trailing: Text(timeAgo,
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textHint)),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Menu Components
// ─────────────────────────────────────────────
class _MenuGroup extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: List.generate(
          items.length,
          (i) => Column(
            children: [
              items[i],
              if (i < items.length - 1)
                const Divider(
                  height: 1,
                  color: AppColors.divider,
                  indent: 56,
                  endIndent: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(label, style: AppTextStyles.bodyLarge),
      trailing: trailing ??
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textHint, size: 22),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text('$count',
          style: AppTextStyles.caption.copyWith(
              color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.08),
          borderRadius:
              BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(color: AppColors.error.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded,
                color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Text('Log Out',
                style: AppTextStyles.labelLarge
                    .copyWith(color: AppColors.error)),
          ],
        ),
      ),
    );
  }
}