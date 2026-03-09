import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:e_learning/features/courses/data/repo/course_repo.dart';
import 'package:e_learning/features/courses/presentation/cubit/course_cubit.dart';
import 'package:e_learning/features/courses/presentation/cubit/course_states.dart';
import 'package:e_learning/features/courses/presentation/view/widgets/my_courses/my_course_card.dart';
import 'package:e_learning/features/courses/presentation/view/widgets/my_courses/my_courses_error_view.dart';
import 'package:e_learning/features/courses/presentation/view/widgets/my_courses/my_courses_filter_tabs.dart';
import 'package:e_learning/features/courses/presentation/view/widgets/my_courses/my_courses_header.dart';
import 'package:e_learning/features/courses/presentation/view/widgets/my_courses/my_courses_inline_error_banner.dart';
import 'package:e_learning/features/courses/presentation/view/widgets/my_courses/my_courses_shimmer.dart';
import 'package:e_learning/features/courses/presentation/view/widgets/my_courses/my_courses_stats_row.dart';
import 'package:e_learning/features/courses/presentation/view/my_course_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyCoursesScreen extends StatefulWidget {
  final String userId;

  const MyCoursesScreen({super.key, required this.userId});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  int _selectedTab = 0;
  final Map<String, Set<String>> _watchedMap = {};
  final Set<String> _fetchingIds = {};

  List<CourseModel> _wishlist = [];
  bool _wishlistLoading = false;
  String? _wishlistError;

  // ── Progress helpers ───────────────────────────────────────────
  double _progress(CourseModel c) {
    final total = c.videos.length;
    if (total == 0) return 0.0;
    return (_watchedMap[c.id]?.length ?? 0) / total;
  }

  bool _isFetching(String courseId) => _fetchingIds.contains(courseId);

  void _fetchWatched(CourseModel c) {
    if (_fetchingIds.contains(c.id)) return;
    if (c.videos.isEmpty) return;
    _fetchingIds.add(c.id);
    CoursesRepo().fetchWatchedVideoIds(widget.userId, c.id).then((ids) {
      if (mounted) setState(() {
        _watchedMap[c.id] = ids;
        _fetchingIds.remove(c.id);
      });
    }).catchError((_) {
      if (mounted) setState(() => _fetchingIds.remove(c.id));
    });
  }

  void _markVideoWatched(String courseId, String videoId) {
    setState(() {
      _watchedMap[courseId] = (_watchedMap[courseId] ?? {})..add(videoId);
    });
  }

  void _invalidateAndRefresh(BuildContext ctx, String courseId) {
    setState(() {
      _watchedMap.remove(courseId);
      _fetchingIds.remove(courseId);
    });
    ctx.read<CoursesCubit>().fetchMyCourses();
  }

  void _clearCacheAndRefresh(BuildContext ctx) {
    setState(() {
      _watchedMap.clear();
      _fetchingIds.clear();
    });
    ctx.read<CoursesCubit>().fetchMyCourses();
    if (_selectedTab == 2) _loadWishlist();
  }

  // ── Wishlist ───────────────────────────────────────────────────
  Future<void> _loadWishlist() async {
    setState(() {
      _wishlistLoading = true;
      _wishlistError = null;
    });
    try {
      final list = await CoursesRepo().fetchWishlist(widget.userId);
      if (mounted) setState(() {
        _wishlist = list;
        _wishlistLoading = false;
      });
    } catch (e) {
      if (mounted) {
        final ex = NetworkExceptionHandler.handle(e);
        setState(() {
          _wishlistLoading = false;
          _wishlistError = _wishlistMsg(ex);
        });
      }
    }
  }

  String _wishlistMsg(AppException e) {
    if (e is NoInternetException) {
      return 'No internet connection.\nCannot load wishlist.';
    }
    if (e is TimeoutException) return 'Request timed out.\nPlease try again.';
    return 'Could not load wishlist.\nPlease try again.';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CoursesCubit(CoursesRepo(), widget.userId)..fetchMyCourses(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: BlocBuilder<CoursesCubit, CoursesState>(
            builder: (context, state) {
              if (state is CoursesLoading) return const MyCoursesShimmer();

              if (state is CoursesError) {
                return MyCoursesErrorView(
                  exception: state.exception,
                  message: state.message,
                  onRetry: () => context.read<CoursesCubit>().fetchMyCourses(),
                );
              }

              if (state is CoursesLoaded) {
                final enrolled = state.courses;

                for (final c in enrolled) {
                  if (!_watchedMap.containsKey(c.id)) _fetchWatched(c);
                }

                final completed = enrolled
                    .where((c) => c.videos.isNotEmpty && _progress(c) >= 1.0)
                    .toList();
                final inProgress =
                    enrolled.where((c) => _progress(c) < 1.0).toList();

                final displayList = _selectedTab == 0
                    ? inProgress
                    : _selectedTab == 1
                        ? completed
                        : _wishlist;

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => _clearCacheAndRefresh(context),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Header
                      SliverToBoxAdapter(
                        child: MyCoursesHeader(
                          enrolledCount: enrolled.length,
                          onRefresh: () => _clearCacheAndRefresh(context),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),

                      // Stats
                      SliverToBoxAdapter(
                        child: MyCoursesStatsRow(
                          enrolled: enrolled.length,
                          completed: completed.length,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),

                      // Filter Tabs
                      SliverToBoxAdapter(
                        child: MyCoursesFilterTabs(
                          selected: _selectedTab,
                          onSelect: (i) {
                            setState(() => _selectedTab = i);
                            if (i == 2 &&
                                _wishlist.isEmpty &&
                                _wishlistError == null) {
                              _loadWishlist();
                            }
                          },
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),

                      // Wishlist error banner
                      if (_selectedTab == 2 && _wishlistError != null)
                        SliverToBoxAdapter(
                          child: MyCoursesInlineErrorBanner(
                            message: _wishlistError!,
                            onRetry: _loadWishlist,
                          ),
                        ),

                      // Wishlist loading
                      if (_selectedTab == 2 && _wishlistLoading)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 48),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary)),
                          ),
                        )

                      // Empty state
                      else if (displayList.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    _selectedTab == 2
                                        ? Icons.bookmark_border_rounded
                                        : Icons.school_outlined,
                                    size: 64,
                                    color: AppColors.textHint,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _selectedTab == 0
                                        ? 'No courses in progress'
                                        : _selectedTab == 1
                                            ? 'No completed courses yet'
                                            : 'Your wishlist is empty',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )

                      // Course list
                      else
                        SliverPadding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) {
                                final course = displayList[i];
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 14),
                                  child: MyCourseCard(
                                    course: course,
                                    progress: _progress(course),
                                    isLoadingProgress:
                                        _isFetching(course.id),
                                    onTap: () async {
                                      await Navigator.push(
                                        ctx,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              MyCourseDetailsScreen(
                                            course: course,
                                            userId: widget.userId,
                                            onVideoWatched: (videoId) =>
                                                _markVideoWatched(
                                                    course.id, videoId),
                                          ),
                                        ),
                                      );
                                      if (ctx.mounted) {
                                        _invalidateAndRefresh(
                                            ctx, course.id);
                                      }
                                    },
                                  ),
                                );
                              },
                              childCount: displayList.length,
                            ),
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}