import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:e_learning/features/home/presentaion/view/courses_details.dart';
import 'package:e_learning/features/watchlist/presentation/logic/watchlist.dart';
import 'package:flutter/material.dart';

class SavedCoursesScreen extends StatefulWidget {
  final String userId;
  const SavedCoursesScreen({super.key, required this.userId});

  @override
  State<SavedCoursesScreen> createState() => _SavedCoursesScreenState();
}

class _SavedCoursesScreenState extends State<SavedCoursesScreen> {
  @override
  void initState() {
    super.initState();
    WishlistNotifier().load(widget.userId);
    WishlistNotifier().addListener(_rebuild);
  }

  @override
  void dispose() {
    WishlistNotifier().removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final courses = WishlistNotifier().savedCourses;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ───────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: AppColors.textPrimary),
              ),
            ),
            title: Text('Saved Courses', style: AppTextStyles.h2),
            centerTitle: false,
          ),

          // ── Count ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Text(
                '${courses.length} course${courses.length != 1 ? 's' : ''} saved',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),

          // ── Empty State ───────────────────────────────────────────────────
          if (courses.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bookmark_border_rounded,
                          size: 48, color: AppColors.primary),
                    ),
                    const SizedBox(height: 20),
                    Text('No saved courses yet',
                        style: AppTextStyles.h2),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the bookmark icon on any course\nto save it for later',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            // ── Courses List ────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _SavedCourseCard(
                    course: courses[i],
                    userId: widget.userId,
                    onTap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => CourseDetailsScreen(
                          course: courses[i],
                          userId: widget.userId,
                        ),
                      ),
                    ),
                    onRemove: () =>
                        WishlistNotifier().toggle(widget.userId, courses[i]),
                  ),
                  childCount: courses.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Saved Course Card
// ─────────────────────────────────────────────
class _SavedCourseCard extends StatelessWidget {
  final CourseModel course;
  final String userId;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _SavedCourseCard({
    required this.course,
    required this.userId,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                course.thumbnailUrl,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient),
                  child: const Icon(Icons.school_rounded,
                      color: Colors.white, size: 32),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Text(
                    course.category.toUpperCase(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Title
                  Text(
                    course.title,
                    style: AppTextStyles.h3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Meta
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 13, color: Color(0xFFFBBF24)),
                      const SizedBox(width: 3),
                      Text('${course.rating}',
                          style: AppTextStyles.caption
                              .copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      const Icon(Icons.schedule_outlined,
                          size: 13, color: AppColors.textHint),
                      const SizedBox(width: 3),
                      Text(course.duration,
                          style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),

            // Remove Button
            GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bookmark_remove_rounded,
                    color: AppColors.error, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}