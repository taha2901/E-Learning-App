import 'package:e_learning/core/constants/app_constants.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/core/widgets/custom_btn.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:e_learning/features/home/presentaion/view/vedio_player_screen.dart';
import 'package:flutter/material.dart';

class CourseDetailsScreen extends StatefulWidget {
  final CourseModel course;
  const CourseDetailsScreen({super.key, required this.course});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  bool _isEnrolled = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _isEnrolled = widget.course.isEnrolled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Hero Image App Bar ────────────
          _CourseHeroAppBar(course: widget.course),

          // ── Course Info ──────────────────
          SliverToBoxAdapter(
            child: _CourseInfoSection(course: widget.course),
          ),

          // ── Tabs ─────────────────────────
          SliverToBoxAdapter(
            child: _DetailsTabs(
              selectedTab: _selectedTab,
              onTabChanged: (i) => setState(() => _selectedTab = i),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // ── Tab Content ──────────────────
          SliverToBoxAdapter(
            child: _selectedTab == 0
                ? _AboutTab(course: widget.course)
                : _LessonsTab(
                    course: widget.course,
                    isEnrolled: _isEnrolled,
                  ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),

      // ── Bottom Enroll Bar ────────────────
      bottomNavigationBar: _BottomEnrollBar(
        isEnrolled: _isEnrolled,
        onEnroll: () => setState(() => _isEnrolled = true),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Hero App Bar
// ─────────────────────────────────────────────
class _CourseHeroAppBar extends StatelessWidget {
  final CourseModel course;
  const _CourseHeroAppBar({required this.course});

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
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.bookmark_border_rounded,
                color: Colors.white, size: 20),
            onPressed: () {},
          ),
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
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
              ),
            ),
            // Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
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

// ─────────────────────────────────────────────
// Course Info Section
// ─────────────────────────────────────────────
class _CourseInfoSection extends StatelessWidget {
  final CourseModel course;
  const _CourseInfoSection({required this.course});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category
          Text(
            course.category.toUpperCase(),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          // Title
          Text(course.title, style: AppTextStyles.h1),
          const SizedBox(height: 12),

          // Instructor Row
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundImage:
                    NetworkImage('https://picsum.photos/seed/instructor/100/100'),
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

          // Stats Chips
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _InfoChip(
                  icon: Icons.star_rounded,
                  label: '${course.rating}',
                  color: const Color(0xFFFBBF24)),
              _InfoChip(
                  icon: Icons.people_outline_rounded,
                  label: '${_formatCount(course.studentsCount)} students'),
              _InfoChip(
                  icon: Icons.play_lesson_outlined,
                  label: '${course.lessonsCount} lessons'),
              _InfoChip(
                  icon: Icons.schedule_outlined,
                  label: course.duration),
              _InfoChip(
                  icon: Icons.signal_cellular_alt_rounded,
                  label: course.level),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCount(int n) =>
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

// ─────────────────────────────────────────────
// Tabs
// ─────────────────────────────────────────────
class _DetailsTabs extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  const _DetailsTabs({required this.selectedTab, required this.onTabChanged});

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
              onTap: () => onTabChanged(0),
            ),
            _Tab(
              label: 'Lessons',
              isSelected: selectedTab == 1,
              onTap: () => onTabChanged(1),
            ),
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
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppConstants.radiusM),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// About Tab
// ─────────────────────────────────────────────
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
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
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

// ─────────────────────────────────────────────
// Lessons Tab
// ─────────────────────────────────────────────
class _LessonsTab extends StatelessWidget {
  final CourseModel course;
  final bool isEnrolled;
  const _LessonsTab({required this.course, required this.isEnrolled});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${course.videos.length} Lessons  •  ${course.duration}',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 16),
          ...course.videos.map(
            (video) => _LessonItem(
              video: video,
              isEnrolled: isEnrolled,
              onTap: () {
                if (!video.isLocked || isEnrolled) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoPlayerScreen(video: video),
                    ),
                  );
                }
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
  final VoidCallback onTap;
  const _LessonItem(
      {required this.video, required this.isEnrolled, required this.onTap});

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
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(
            color: video.isWatched
                ? AppColors.success.withOpacity(0.3)
                : AppColors.cardBorder,
          ),
        ),
        child: Row(
          children: [
            // Play / Check / Lock
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: video.isWatched
                    ? AppColors.success.withOpacity(0.1)
                    : locked
                        ? AppColors.surfaceVariant
                        : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                video.isWatched
                    ? Icons.check_rounded
                    : locked
                        ? Icons.lock_outline_rounded
                        : Icons.play_arrow_rounded,
                color: video.isWatched
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
                  Text(
                    video.title,
                    style: AppTextStyles.h3.copyWith(
                      color: locked
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.schedule_outlined,
                          size: 13, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(video.duration, style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            if (video.isWatched)
              Text(
                'Watched',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bottom Enroll Bar
// ─────────────────────────────────────────────
class _BottomEnrollBar extends StatelessWidget {
  final bool isEnrolled;
  final VoidCallback onEnroll;
  const _BottomEnrollBar({required this.isEnrolled, required this.onEnroll});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppConstants.horizontalPadding, 16, AppConstants.horizontalPadding, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
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
                      style: AppTextStyles.h3.copyWith(
                          color: AppColors.success)),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Continue', style: AppTextStyles.labelLarge),
                  ),
                ],
              )
            : AppPrimaryButton(
                label: 'Enroll Now – Free',
                onTap: onEnroll,
              ),
      ),
    );
  }
}