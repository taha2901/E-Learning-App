import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:e_learning/features/courses/data/repo/course_repo.dart';
import 'package:e_learning/features/courses/presentation/cubit/course_cubit.dart';
import 'package:e_learning/features/home/presentaion/view/vedio_player_screen.dart';
import 'package:e_learning/features/home/presentaion/view/widgets/course_details/course_about_tab.dart';
import 'package:e_learning/features/home/presentaion/view/widgets/course_details/course_bottom_enroll_bar.dart';
import 'package:e_learning/features/home/presentaion/view/widgets/course_details/course_details_tabs.dart';
import 'package:e_learning/features/home/presentaion/view/widgets/course_details/course_hero_app_bar.dart';
import 'package:e_learning/features/home/presentaion/view/widgets/course_details/course_info_section.dart';
import 'package:e_learning/features/home/presentaion/view/widgets/course_details/course_lessons_tab.dart';
import 'package:e_learning/features/home/presentaion/view/widgets/course_details/course_progress_section.dart';
import 'package:e_learning/features/home/presentaion/view/widgets/course_details/course_reviews_row.dart';
import 'package:e_learning/features/reviews_sheet/presentation/view/reviews_sheet.dart';
import 'package:e_learning/features/watchlist/presentation/logic/wishlist_cubit.dart';
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

  @override
  Widget build(BuildContext context) {
    final total = widget.course.videos.length;
    final watched = _watchedVideoIds.length;
    final progress = total > 0 ? watched / total : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: CourseBottomEnrollBar(
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
      body: CustomScrollView(
        slivers: [
          CourseHeroAppBar(course: widget.course, userId: _userId),
          SliverToBoxAdapter(
            child: CourseInfoSection(
                course: widget.course, currentRating: _currentRating),
          ),
          if (_isEnrolled && total > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: CourseProgressSection(
                    progress: progress, watched: watched, total: total),
              ),
            ),
          SliverToBoxAdapter(
            child: CourseReviewsRow(
              currentRating: _currentRating,
              onTap: _openReviews,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: CourseDetailsTabs(
                selectedTab: _selectedTab,
                onTabChanged: (i) => setState(() => _selectedTab = i),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          SliverToBoxAdapter(
            child: _selectedTab == 0
                ? CourseAboutTab(course: widget.course)
                : CourseLessonsTab(
                    course: widget.course,
                    isEnrolled: _isEnrolled,
                    watchedVideoIds: _watchedVideoIds,
                    onVideoTap: _openVideo,
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}