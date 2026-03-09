import 'package:e_learning/core/erros/app_error_widget.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:e_learning/features/courses/data/repo/course_repo.dart';
import 'package:e_learning/features/courses/presentation/view/widgets/my_course_details/my_course_details_app_bar.dart';
import 'package:e_learning/features/courses/presentation/view/widgets/my_course_details/my_course_details_info_pills.dart';
import 'package:e_learning/features/courses/presentation/view/widgets/my_course_details/my_course_details_lesson_item.dart';
import 'package:e_learning/features/courses/presentation/view/widgets/my_course_details/my_course_details_progress_card.dart';
import 'package:e_learning/features/courses/presentation/view/widgets/my_course_details/my_course_details_reviews_row.dart';
import 'package:e_learning/features/home/presentaion/cubit/my_course_details_cubit.dart';
import 'package:e_learning/features/home/presentaion/cubit/my_course_details_states.dart';
import 'package:e_learning/features/home/presentaion/view/vedio_player_screen.dart';
import 'package:e_learning/features/quiz/data/repo/quiz_repo.dart';
import 'package:e_learning/features/reviews_sheet/presentation/view/reviews_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyCourseDetailsScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          MyCourseDetailsCubit(CoursesRepo(), QuizRepo())
            ..loadData(userId: userId, courseId: course.id),
      child: _MyCourseDetailsBody(
        course: course,
        userId: userId,
        onVideoWatched: onVideoWatched,
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _MyCourseDetailsBody extends StatefulWidget {
  final CourseModel course;
  final String userId;
  final Function(String videoId)? onVideoWatched;

  const _MyCourseDetailsBody({
    required this.course,
    required this.userId,
    this.onVideoWatched,
  });

  @override
  State<_MyCourseDetailsBody> createState() => _MyCourseDetailsBodyState();
}

class _MyCourseDetailsBodyState extends State<_MyCourseDetailsBody> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.course.rating;
  }

  // ── Open video ────────────────────────────────────────────────────────────
  Future<void> _openVideo(VideoModel video) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          video: video,
          courseVideos: widget.course.videos,
          onWatched: () async {
            await CoursesRepo().markVideoWatched(widget.userId, video.id);
            // بنحدث الـ state في الـ cubit مش في الـ setState
            context.read<MyCourseDetailsCubit>().markVideoWatched(video.id);
            widget.onVideoWatched?.call(video.id);
          },
        ),
      ),
    );
  }

  // ── Open reviews ──────────────────────────────────────────────────────────
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
    return BlocBuilder<MyCourseDetailsCubit, MyCourseDetailsState>(
      builder: (context, state) {
        // ── Error ─────────────────────────────────────────────────────────
        if (state is MyCourseDetailsError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: AppErrorWidget(
              exception: state.exception,
              onRetry: () => context.read<MyCourseDetailsCubit>().loadData(
                userId: widget.userId,
                courseId: widget.course.id,
              ),
            ),
          );
        }

        // ── Loading or Loaded ─────────────────────────────────────────────
        final isLoading =
            state is MyCourseDetailsLoading || state is MyCourseDetailsInitial;
        final watchedIds = state is MyCourseDetailsLoaded
            ? state.watchedIds
            : <String>{};
        final videoQuizIdMap = state is MyCourseDetailsLoaded
            ? state.videoQuizIdMap
            : <String, String>{};

        final videos = widget.course.videos;
        final watched = watchedIds.length;
        final total = videos.length;
        final progress = total > 0 ? watched / total : 0.0;
        final isCompleted = total > 0 && watched >= total;

        final nextVideo = videos.isNotEmpty
            ? videos.firstWhere(
                (v) => !watchedIds.contains(v.id),
                orElse: () => videos.first,
              )
            : null;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              MyCourseDetailsAppBar(course: widget.course),

              // Progress Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: MyCourseDetailsProgressCard(
                    progress: progress,
                    watched: watched,
                    total: total,
                    isCompleted: isCompleted,
                    nextVideo: nextVideo,
                    onContinueTap: nextVideo != null
                        ? () {
                            _openVideo(nextVideo);
                          }
                        : null,
                  ),
                ),
              ),

              // Reviews Row
              SliverToBoxAdapter(
                child: MyCourseDetailsReviewsRow(
                  currentRating: _currentRating,
                  onTap: () {
                    _openReviews();
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Info Pills
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: MyCourseDetailsInfoPills(
                    instructor: widget.course.instructor,
                    duration: widget.course.duration,
                    level: widget.course.level,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Lessons Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text('Course Content', style: AppTextStyles.h2),
                      const Spacer(),
                      Text(
                        '$total lessons',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Lessons List
              if (isLoading)
                const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (videos.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.video_library_outlined,
                            size: 56,
                            color: AppColors.textHint,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No lessons available yet',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((ctx, i) {
                      final video = videos[i];
                      final isWatched = watchedIds.contains(video.id);
                      final isCurrent =
                          nextVideo?.id == video.id && !isCompleted;
                      final hasQuiz = videoQuizIdMap.containsKey(video.id);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: MyCourseDetailsLessonItem(
                          video: video,
                          index: i + 1,
                          isWatched: isWatched,
                          isCurrent: isCurrent,
                          hasQuiz: hasQuiz,

                          onTap: () {
                            _openVideo(video);
                          },

                          // الكويز بيتفتح من جوا الـ VideoPlayerScreen مش من هنا
                          onQuizTap: hasQuiz
                              ? () {
                                  _openVideo(video);
                                }
                              : null,
                        ),
                      );
                    }, childCount: videos.length),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        );
      },
    );
  }
}
