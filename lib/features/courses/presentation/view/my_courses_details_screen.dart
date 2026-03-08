// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// my_courses_details_screen.dart — ✅ بيبعت courseVideos للـ VideoPlayerScreen
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:e_learning/features/courses/data/repo/course_repo.dart';
import 'package:e_learning/features/courses/presentation/view/reviews_sheet.dart';
import 'package:e_learning/features/home/presentaion/view/vedio_player_screen.dart';
import 'package:e_learning/features/quiz/data/repo/quiz_repo.dart';
import 'package:e_learning/features/quiz/presentation/view/quiz_screen.dart';
import 'package:flutter/material.dart';

class MyCourseDetailsScreen extends StatefulWidget {
  final CourseModel course;
  final String userId;
  final Function(String videoId)? onVideoWatched;

  const MyCourseDetailsScreen({
    super.key,
    required this.course,
    required this.userId,
    this.onVideoWatched,
  });

  @override
  State<MyCourseDetailsScreen> createState() => _MyCourseDetailsScreenState();
}

class _MyCourseDetailsScreenState extends State<MyCourseDetailsScreen> {
  Set<String> _watchedIds = {};
  bool _loading = true;
  Map<String, String> _videoQuizIdMap = {};
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.course.rating;
    _loadProgress();
    _loadQuizMap();
  }

  Future<void> _loadProgress() async {
    final ids = await CoursesRepo()
        .fetchWatchedVideoIds(widget.userId, widget.course.id);
    if (mounted) setState(() {
      _watchedIds = ids;
      _loading = false;
    });
  }

  Future<void> _loadQuizMap() async {
    try {
      final allQuizzes = await QuizRepo().fetchAllQuizzes();
      final map = <String, String>{};
      for (final quiz in allQuizzes) {
        if (quiz.questions.isNotEmpty) {
          map[quiz.videoId] = quiz.id;
        }
      }
      if (mounted) setState(() => _videoQuizIdMap = map);
    } catch (_) {}
  }

  double get _progress {
    final total = widget.course.videos.length;
    if (total == 0) return 0.0;
    return _watchedIds.length / total;
  }

  // ✅ بنبعت courseVideos عشان الـ Up Next يشتغل صح
  Future<void> _openVideo(VideoModel video) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          video: video,
          courseVideos: widget.course.videos, // ✅
          onWatched: () async {
            await CoursesRepo().markVideoWatched(widget.userId, video.id);
            setState(() => _watchedIds.add(video.id));
            widget.onVideoWatched?.call(video.id);
          },
        ),
      ),
    );
  }

  Future<void> _openQuiz(String videoId) async {
    final quizId = _videoQuizIdMap[videoId];
    if (quizId == null) return;
    final allQuizzes = await QuizRepo().fetchAllQuizzes();
    final quiz = allQuizzes.firstWhere(
      (q) => q.id == quizId,
      orElse: () => allQuizzes.firstWhere((q) => q.videoId == videoId),
    );
    if (!mounted) return;
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => QuizScreen(quiz: quiz)));
  }

  Future<void> _openReviews() async {
    final newRating = await showReviewsSheet(
      context,
      courseId: widget.course.id,
      userId: widget.userId,
      courseTitle: widget.course.title,
    );
    if (newRating != null && mounted) {
      setState(() => _currentRating = newRating);
    }
  }

  @override
  Widget build(BuildContext context) {
    final videos = widget.course.videos;
    final watched = _watchedIds.length;
    final total = videos.length;
    final pct = (_progress * 100).toInt();
    final isCompleted = total > 0 && watched >= total;

    final nextVideo = videos.isNotEmpty
        ? videos.firstWhere(
            (v) => !_watchedIds.contains(v.id),
            orElse: () => videos.first,
          )
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
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
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.course.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient)),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7)
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(100)),
                          child: Text(
                            widget.course.category.toUpperCase(),
                            style: AppTextStyles.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(widget.course.title,
                            style: AppTextStyles.h2
                                .copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Progress Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isCompleted
                      ? LinearGradient(colors: [
                          AppColors.success,
                          AppColors.success.withOpacity(0.7)
                        ])
                      : AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: CircularProgressIndicator(
                                value: _progress,
                                strokeWidth: 6,
                                backgroundColor:
                                    Colors.white.withOpacity(0.2),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                              ),
                            ),
                            Text('$pct%',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                isCompleted
                                    ? 'Course Completed! 🎉'
                                    : 'Keep it up!',
                                style: AppTextStyles.h3
                                    .copyWith(color: Colors.white)),
                            const SizedBox(height: 4),
                            Text('$watched of $total lessons watched',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color:
                                        Colors.white.withOpacity(0.85))),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: LinearProgressIndicator(
                                value: _progress,
                                minHeight: 6,
                                backgroundColor:
                                    Colors.white.withOpacity(0.25),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                    if (!isCompleted && nextVideo != null) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _openVideo(nextVideo),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            const Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Continue watching',
                                      style: AppTextStyles.caption.copyWith(
                                          color: Colors.white
                                              .withOpacity(0.7))),
                                  Text(nextVideo.title,
                                      style: AppTextStyles.bodySmall
                                          .copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.white, size: 14),
                          ]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Reviews Button
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: _openReviews,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFF59E0B), size: 22),
                  const SizedBox(width: 10),
                  Text(
                    _currentRating.toStringAsFixed(1),
                    style: AppTextStyles.h3.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 8),
                  Text('Reviews & Ratings', style: AppTextStyles.h3),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: AppColors.textHint),
                ]),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Course Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                _InfoPill(
                    icon: Icons.person_outline_rounded,
                    label: widget.course.instructor),
                const SizedBox(width: 8),
                _InfoPill(
                    icon: Icons.schedule_outlined,
                    label: widget.course.duration),
                const SizedBox(width: 8),
                _InfoPill(
                    icon: Icons.signal_cellular_alt_rounded,
                    label: widget.course.level),
              ]),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Lessons Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Text('Course Content', style: AppTextStyles.h2),
                const Spacer(),
                Text('$total lessons',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          if (_loading)
            const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()))
          else if (videos.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(children: [
                    const Icon(Icons.video_library_outlined,
                        size: 56, color: AppColors.textHint),
                    const SizedBox(height: 12),
                    Text('No lessons available yet',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                  ]),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  final video = videos[i];
                  final isWatched = _watchedIds.contains(video.id);
                  final isCurrent =
                      nextVideo?.id == video.id && !isCompleted;
                  final hasQuiz =
                      _videoQuizIdMap.containsKey(video.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MyLessonItem(
                      video: video,
                      index: i + 1,
                      isWatched: isWatched,
                      isCurrent: isCurrent,
                      hasQuiz: hasQuiz,
                      onTap: () => _openVideo(video),
                      onQuizTap: () => _openQuiz(video.id),
                    ),
                  );
                }, childCount: videos.length),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Info Pill + Lesson Item (unchanged)
// ─────────────────────────────────────────────
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label,
                  style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyLessonItem extends StatelessWidget {
  final VideoModel video;
  final int index;
  final bool isWatched;
  final bool isCurrent;
  final bool hasQuiz;
  final VoidCallback onTap;
  final VoidCallback onQuizTap;

  const _MyLessonItem({
    required this.video,
    required this.index,
    required this.isWatched,
    required this.isCurrent,
    required this.hasQuiz,
    required this.onTap,
    required this.onQuizTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppColors.primary.withOpacity(0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isWatched
                ? AppColors.success.withOpacity(0.4)
                : isCurrent
                    ? AppColors.primary.withOpacity(0.4)
                    : AppColors.cardBorder,
            width: isCurrent ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isWatched
                  ? AppColors.success.withOpacity(0.1)
                  : isCurrent
                      ? AppColors.primary.withOpacity(0.1)
                      : AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: isWatched
                ? const Icon(Icons.check_rounded,
                    color: AppColors.success, size: 22)
                : isCurrent
                    ? const Icon(Icons.play_arrow_rounded,
                        color: AppColors.primary, size: 22)
                    : Center(
                        child: Text('$index',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(video.title,
                    style: AppTextStyles.h3.copyWith(
                        color: isWatched
                            ? AppColors.textSecondary
                            : AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.schedule_outlined,
                      size: 12, color: AppColors.textHint),
                  const SizedBox(width: 4),
                  Text(video.duration, style: AppTextStyles.caption),
                  if (hasQuiz) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onQuizTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                              color: AppColors.warning.withOpacity(0.4)),
                        ),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.quiz_rounded,
                                  size: 10,
                                  color:
                                      AppColors.warning.withOpacity(0.9)),
                              const SizedBox(width: 3),
                              Text('Quiz',
                                  style: AppTextStyles.caption.copyWith(
                                      fontSize: 10,
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.w700)),
                            ]),
                      ),
                    ),
                  ],
                ]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isWatched)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text('Done',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700)),
            )
          else if (isCurrent)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text('Next',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700)),
            )
          else
            const Icon(Icons.play_circle_outline_rounded,
                color: AppColors.textHint, size: 20),
        ]),
      ),
    );
  }
}