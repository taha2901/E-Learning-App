// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// courses_details.dart
// ✅ Rating بيتحدث live بعد ما اليوزر يعمل review
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'package:e_learning/core/constants/app_constants.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/core/widgets/custom_btn.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:e_learning/features/courses/data/repo/course_repo.dart';
import 'package:e_learning/features/courses/presentation/cubit/course_cubit.dart';
import 'package:e_learning/features/courses/presentation/view/reviews_sheet.dart';
import 'package:e_learning/features/home/presentaion/view/vedio_player_screen.dart';
import 'package:e_learning/features/watchlist/presentation/logic/wishlist_cubit.dart';
import 'package:e_learning/features/watchlist/presentation/logic/wishlist_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CourseDetailsScreen extends StatefulWidget {
  final CourseModel course;
  final String? userId;
  final Function(String videoId)? onVideoWatched;

  const CourseDetailsScreen({
    super.key,
    required this.course,
    this.userId,
    this.onVideoWatched,
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  bool _isEnrolled = false;
  int _selectedTab = 0;
  Set<String> _watchedVideoIds = {};

  // ✅ Rating قابل للتحديث
  late double _currentRating;

  String get _userId =>
      widget.userId ??
      Supabase.instance.client.auth.currentUser?.id ??
      '';

  @override
  void initState() {
    super.initState();
    _isEnrolled = widget.course.isEnrolled;
    _currentRating = widget.course.rating;
    _loadWatchedVideos();
    if (_userId.isNotEmpty) {
      context.read<WishlistCubit>().load();
    }
  }

  Future<void> _loadWatchedVideos() async {
    if (_userId.isEmpty) return;
    final ids = await CoursesRepo()
        .fetchWatchedVideoIds(_userId, widget.course.id);
    if (mounted) setState(() => _watchedVideoIds = ids);
  }

  // ✅ فتح الـ Reviews Sheet وتحديث الـ rating لو تغيّر
  Future<void> _openReviews() async {
    final newRating = await showReviewsSheet(
      context,
      courseId: widget.course.id,
      userId: _userId,
      courseTitle: widget.course.title,
    );
    if (newRating != null && mounted) {
      setState(() => _currentRating = newRating);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.course.videos.length;
    final watched = _watchedVideoIds.length;
    final progress = total > 0 ? watched / total : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _CourseHeroAppBar(
              course: widget.course,
              userId: _userId,
              currentRating: _currentRating),
          SliverToBoxAdapter(
              child: _CourseInfoSection(
                  course: widget.course, currentRating: _currentRating)),
          if (_isEnrolled && total > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _ProgressSection(
                    progress: progress, watched: watched, total: total),
              ),
            ),

          // ✅ Reviews Row
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: _openReviews,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFF59E0B), size: 20),
                    const SizedBox(width: 8),
                    Text(_currentRating.toStringAsFixed(1),
                        style: AppTextStyles.h3.copyWith(
                            fontWeight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    Text('· Reviews & Ratings',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: AppColors.textHint),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: _DetailsTabs(
              selectedTab: _selectedTab,
              onTabChanged: (i) => setState(() => _selectedTab = i),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: _selectedTab == 0
                ? _AboutTab(course: widget.course)
                : _LessonsTab(
                    course: widget.course,
                    isEnrolled: _isEnrolled,
                    watchedVideoIds: _watchedVideoIds,
                    onVideoTap: _openVideo,
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      bottomNavigationBar: _BottomEnrollBar(
        isEnrolled: _isEnrolled,
        onEnroll: _enrollCourse,
        onContinue: () {
          final next = widget.course.videos.firstWhere(
            (v) => !_watchedVideoIds.contains(v.id),
            orElse: () => widget.course.videos.first,
          );
          _openVideo(next);
        },
      ),
    );
  }

  Future<void> _openVideo(VideoModel video) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          video: video,
          courseVideos: widget.course.videos,
          onWatched: () async {
            if (_userId.isNotEmpty) {
              await CoursesRepo().markVideoWatched(_userId, video.id);
              setState(() => _watchedVideoIds.add(video.id));
              widget.onVideoWatched?.call(video.id);
            }
          },
        ),
      ),
    );
  }

  Future<void> _enrollCourse() async {
    try {
      await CoursesRepo().enrollInCourse(_userId, widget.course.id);
      if (mounted) {
        setState(() => _isEnrolled = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Enrolled successfully! 🎉'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        try {
          context.read<CoursesCubit>().fetchMyCourses();
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

// ── Hero App Bar ──────────────────────────────────────────────────
class _CourseHeroAppBar extends StatelessWidget {
  final CourseModel course;
  final String userId;
  final double currentRating;

  const _CourseHeroAppBar({
    required this.course,
    required this.userId,
    required this.currentRating,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
        ),
      ),
      actions: [
        BlocBuilder<WishlistCubit, WishlistState>(
          builder: (ctx, state) {
            final saved = ctx.read<WishlistCubit>().isSaved(course.id);
            return GestureDetector(
              onTap: () async {
                if (userId.isEmpty) return;
                await ctx.read<WishlistCubit>().toggle(course);
                if (ctx.mounted) {
                  final nowSaved =
                      ctx.read<WishlistCubit>().isSaved(course.id);
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text(nowSaved
                        ? 'Saved to wishlist ❤️'
                        : 'Removed from wishlist'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ));
                }
              },
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: saved
                      ? Colors.white.withOpacity(0.25)
                      : Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    key: ValueKey(saved),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              course.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration:
                    const BoxDecoration(gradient: AppColors.primaryGradient),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Progress ──────────────────────────────────────────────────────
class _ProgressSection extends StatelessWidget {
  final double progress;
  final int watched;
  final int total;
  const _ProgressSection(
      {required this.progress, required this.watched, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toInt();
    final done = watched >= total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: done
            ? AppColors.success.withOpacity(0.08)
            : AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.check_circle_rounded : Icons.play_lesson_outlined,
                color: done ? AppColors.success : AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                done
                    ? 'Course Completed! 🎉'
                    : '$watched of $total lessons watched',
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: done ? AppColors.success : AppColors.primary,
                ),
              ),
              const Spacer(),
              Text('$pct%',
                  style: AppTextStyles.h3.copyWith(
                      color:
                          done ? AppColors.success : AppColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(
                  done ? AppColors.success : AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Section — مع الـ rating الحي ────────────────────────────
class _CourseInfoSection extends StatelessWidget {
  final CourseModel course;
  final double currentRating;
  const _CourseInfoSection(
      {required this.course, required this.currentRating});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.all(AppConstants.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.category.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Text(course.title, style: AppTextStyles.h1),
          const SizedBox(height: 12),
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(
                    'https://picsum.photos/seed/instructor/100/100'),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Instructor', style: AppTextStyles.caption),
                  Text(course.instructor,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              // ✅ Rating يعرض القيمة الحية
              _InfoChip(
                icon: Icons.star_rounded,
                label: currentRating.toStringAsFixed(1),
                color: const Color(0xFFFBBF24),
              ),
              _InfoChip(
                icon: Icons.people_outline_rounded,
                label: '${_fmt(course.studentsCount)} students',
              ),
              _InfoChip(
                icon: Icons.play_lesson_outlined,
                label:
                    '${course.videos.isNotEmpty ? course.videos.length : course.lessonsCount} lessons',
              ),
              _InfoChip(
                  icon: Icons.schedule_outlined, label: course.duration),
              _InfoChip(
                  icon: Icons.signal_cellular_alt_rounded,
                  label: course.level),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : n.toString();
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.textHint),
          const SizedBox(width: 5),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

// ── Tabs ──────────────────────────────────────────────────────────
class _DetailsTabs extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  const _DetailsTabs(
      {required this.selectedTab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.horizontalPadding),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
        ),
        child: Row(
          children: [
            _Tab(
                label: 'About',
                isSelected: selectedTab == 0,
                onTap: () => onTabChanged(0)),
            _Tab(
                label: 'Lessons',
                isSelected: selectedTab == 1,
                onTap: () => onTabChanged(1)),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _Tab(
      {required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color:
                isSelected ? AppColors.surface : Colors.transparent,
            borderRadius:
                BorderRadius.circular(AppConstants.radiusM),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Center(
            child: Text(label,
                style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400)),
          ),
        ),
      ),
    );
  }
}

// ── About Tab ─────────────────────────────────────────────────────
class _AboutTab extends StatelessWidget {
  final CourseModel course;
  const _AboutTab({required this.course});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About this Course', style: AppTextStyles.h2),
          const SizedBox(height: 12),
          Text(course.description,
              style: AppTextStyles.bodyLarge.copyWith(height: 1.7)),
          const SizedBox(height: 24),
          Text('What you will learn', style: AppTextStyles.h2),
          const SizedBox(height: 12),
          ...const [
            'Build real-world projects from scratch',
            'Understand core concepts deeply',
            'Write clean and maintainable code',
            'Deploy and publish your projects',
          ].map((item) => _LearnItem(text: item)),
        ],
      ),
    );
  }
}

class _LearnItem extends StatelessWidget {
  final String text;
  const _LearnItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
                color: AppColors.success, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 13),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text, style: AppTextStyles.bodyLarge)),
        ],
      ),
    );
  }
}

// ── Lessons Tab ───────────────────────────────────────────────────
class _LessonsTab extends StatelessWidget {
  final CourseModel course;
  final bool isEnrolled;
  final Set<String> watchedVideoIds;
  final Function(VideoModel) onVideoTap;

  const _LessonsTab({
    required this.course,
    required this.isEnrolled,
    required this.watchedVideoIds,
    required this.onVideoTap,
  });

  @override
  Widget build(BuildContext context) {
    if (course.videos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.video_library_outlined,
                  size: 64, color: AppColors.textHint),
              SizedBox(height: 16),
              Text('No lessons available yet',
                  style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              '${course.videos.length} Lessons  •  ${course.duration}',
              style: AppTextStyles.bodyMedium),
          const SizedBox(height: 16),
          ...course.videos.map(
            (video) => _LessonItem(
              video: video,
              isEnrolled: isEnrolled,
              isWatched: watchedVideoIds.contains(video.id),
              onTap: () {
                if (!video.isLocked || isEnrolled) onVideoTap(video);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonItem extends StatelessWidget {
  final VideoModel video;
  final bool isEnrolled;
  final bool isWatched;
  final VoidCallback onTap;

  const _LessonItem({
    required this.video,
    required this.isEnrolled,
    required this.isWatched,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = video.isLocked && !isEnrolled;
    return GestureDetector(
      onTap: locked ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(
            color: isWatched
                ? AppColors.success.withOpacity(0.3)
                : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isWatched
                    ? AppColors.success.withOpacity(0.1)
                    : locked
                        ? AppColors.surfaceVariant
                        : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isWatched
                    ? Icons.check_rounded
                    : locked
                        ? Icons.lock_outline_rounded
                        : Icons.play_arrow_rounded,
                color: isWatched
                    ? AppColors.success
                    : locked
                        ? AppColors.textHint
                        : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(video.title,
                      style: AppTextStyles.h3.copyWith(
                          color: locked
                              ? AppColors.textHint
                              : AppColors.textPrimary)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.schedule_outlined,
                          size: 13, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(video.duration,
                          style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            if (isWatched)
              Text('Watched ✓',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Bar ────────────────────────────────────────────────────
class _BottomEnrollBar extends StatelessWidget {
  final bool isEnrolled;
  final VoidCallback onEnroll;
  final VoidCallback onContinue;

  const _BottomEnrollBar({
    required this.isEnrolled,
    required this.onEnroll,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: isEnrolled
            ? Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: 24),
                  const SizedBox(width: 10),
                  Text('You are enrolled!',
                      style: AppTextStyles.h3
                          .copyWith(color: AppColors.success)),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Continue',
                        style: AppTextStyles.labelLarge),
                  ),
                ],
              )
            : AppPrimaryButton(
                label: 'Enroll Now – Free', onTap: onEnroll),
      ),
    );
  }
}