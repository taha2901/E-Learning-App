import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:e_learning/features/courses/data/repo/course_repo.dart';
import 'package:e_learning/features/courses/presentation/cubit/course_cubit.dart';
import 'package:e_learning/features/courses/presentation/cubit/course_states.dart';
import 'package:e_learning/features/courses/presentation/view/widgets/course_card.dart';
import 'package:e_learning/features/courses/presentation/view/my_courses_details_screen.dart';
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

  // courseId → Set of watched video IDs (from DB)
  final Map<String, Set<String>> _watchedMap = {};

  // courseIds currently being fetched → prevent duplicate calls
  final Set<String> _fetchingIds = {};

  // Wishlist
  List<CourseModel> _wishlist = [];
  bool _wishlistLoading = false;
  String? _wishlistError;

  // ─────────────────────────────────────────────────────────────
  // Progress helpers
  // ─────────────────────────────────────────────────────────────
  double _progress(CourseModel c) {
    final total = c.videos.length;
    if (total == 0) return 0.0;
    final watched = _watchedMap[c.id]?.length ?? 0;
    return watched / total;
  }

  bool _isFetching(String courseId) => _fetchingIds.contains(courseId);

  // ─────────────────────────────────────────────────────────────
  // ✅ FIX 1: Fetch watched IDs from DB — always fresh
  // Only skip if already fetching RIGHT NOW (prevent duplicate calls)
  // ─────────────────────────────────────────────────────────────
  void _fetchWatched(CourseModel c) {
    if (_fetchingIds.contains(c.id)) return; // already in-flight
    if (c.videos.isEmpty) return;           // nothing to track

    _fetchingIds.add(c.id);

    CoursesRepo()
        .fetchWatchedVideoIds(widget.userId, c.id)
        .then((ids) {
      if (mounted) {
        setState(() {
          _watchedMap[c.id] = ids;
          _fetchingIds.remove(c.id);
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _fetchingIds.remove(c.id));
    });
  }

  // ✅ FIX 2: called from onVideoWatched — instant local update
  void _markVideoWatched(String courseId, String videoId) {
    setState(() {
      _watchedMap[courseId] = (_watchedMap[courseId] ?? {})..add(videoId);
    });
  }

  // ✅ FIX 3: called after returning from details screen
  // Clears cache for this course → forces fresh DB fetch on next build
  void _invalidateAndRefresh(BuildContext ctx, String courseId) {
    setState(() {
      _watchedMap.remove(courseId);
      _fetchingIds.remove(courseId);
    });
    ctx.read<CoursesCubit>().fetchMyCourses();
  }

  // ✅ FIX 4: full cache clear on pull-to-refresh / refresh button
  void _clearCacheAndRefresh(BuildContext ctx) {
    setState(() {
      _watchedMap.clear();
      _fetchingIds.clear();
    });
    ctx.read<CoursesCubit>().fetchMyCourses();
    if (_selectedTab == 2) _loadWishlist();
  }

  // ─────────────────────────────────────────────────────────────
  // Wishlist
  // ─────────────────────────────────────────────────────────────
  Future<void> _loadWishlist() async {
    setState(() {
      _wishlistLoading = true;
      _wishlistError = null;
    });
    try {
      final list = await CoursesRepo().fetchWishlist(widget.userId);
      if (mounted) {
        setState(() {
          _wishlist = list;
          _wishlistLoading = false;
        });
      }
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
    if (e is NoInternetException) return 'No internet connection.\nCannot load wishlist.';
    if (e is TimeoutException) return 'Request timed out.\nPlease try again.';
    return 'Could not load wishlist.\nPlease try again.';
  }

  // ─────────────────────────────────────────────────────────────
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
              if (state is CoursesLoading) return const _MyCoursesShimmer();

              if (state is CoursesError) {
                return _MyCoursesErrorView(
                  exception: state.exception,
                  message: state.message,
                  onRetry: () => context.read<CoursesCubit>().fetchMyCourses(),
                );
              }

              if (state is CoursesLoaded) {
                final enrolled = state.courses;

                // ✅ trigger fetch for courses not in cache
                for (final c in enrolled) {
                  if (!_watchedMap.containsKey(c.id)) {
                    _fetchWatched(c);
                  }
                }

                final completed = enrolled
                    .where((c) =>
                        c.videos.isNotEmpty && _progress(c) >= 1.0)
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
                      // ── Header ──────────────────────────────
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 24, 16, 0),
                          child: Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('My Courses',
                                      style: AppTextStyles.displayMedium),
                                  const SizedBox(height: 4),
                                  Text(
                                      '${enrolled.length} courses enrolled',
                                      style: AppTextStyles.bodyMedium),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _clearCacheAndRefresh(context),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.cardBorder),
                                ),
                                child: const Icon(Icons.refresh_rounded,
                                    color: AppColors.primary, size: 20),
                              ),
                            ),
                          ]),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      SliverToBoxAdapter(
                        child: _StatsRow(
                            count: enrolled.length,
                            completed: completed.length),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                      SliverToBoxAdapter(
                        child: _FilterTabs(
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

                      // ── Wishlist error banner ────────────────
                      if (_selectedTab == 2 && _wishlistError != null)
                        SliverToBoxAdapter(
                          child: _InlineErrorBanner(
                            message: _wishlistError!,
                            onRetry: _loadWishlist,
                          ),
                        ),

                      // ── Wishlist loading ─────────────────────
                      if (_selectedTab == 2 && _wishlistLoading)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.only(top: 48),
                            child: Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary)),
                          ),
                        )

                      // ── Empty ────────────────────────────────
                      else if (displayList.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: Center(
                              child: Column(children: [
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
                              ]),
                            ),
                          ),
                        )

                      // ── Course list ──────────────────────────
                      else
                        SliverPadding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) {
                                final course = displayList[i];
                                final fetching = _isFetching(course.id);

                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 14),
                                  child: MyCourseCard(
                                    course: course,
                                    progress: _progress(course),
                                    isLoadingProgress: fetching,
                                    onTap: () async {
                                      await Navigator.push(
                                        ctx,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              MyCourseDetailsScreen(
                                            course: course,
                                            userId: widget.userId,
                                            // ✅ instant UI update while watching
                                            onVideoWatched: (videoId) =>
                                                _markVideoWatched(
                                                    course.id, videoId),
                                          ),
                                        ),
                                      );
                                      // ✅ after returning: invalidate cache
                                      // → forces fresh DB fetch = accurate %
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

// ─────────────────────────────────────────────────────────────────
// Error View
// ─────────────────────────────────────────────────────────────────
class _MyCoursesErrorView extends StatelessWidget {
  final AppException? exception;
  final String message;
  final VoidCallback onRetry;
  const _MyCoursesErrorView(
      {required this.exception,
      required this.message,
      required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cfg = _config(exception);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                    color: cfg.color.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: Icon(cfg.icon, color: cfg.color, size: 40),
              ),
            ),
            const SizedBox(height: 24),
            Text(cfg.title,
                style: AppTextStyles.h1, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(cfg.subtitle,
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary, height: 1.6),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cfg.color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ErrorConfig _config(AppException? e) {
    if (e is NoInternetException) {
      return _ErrorConfig(
          icon: Icons.wifi_off_rounded,
          color: const Color(0xFF6B7280),
          title: 'No Internet Connection',
          subtitle: 'Check your network and try again.');
    }
    if (e is TimeoutException) {
      return _ErrorConfig(
          icon: Icons.hourglass_disabled_rounded,
          color: const Color(0xFFF59E0B),
          title: 'Connection Timed Out',
          subtitle: 'The server took too long.\nPlease try again.');
    }
    if (e is ServerException) {
      return _ErrorConfig(
          icon: Icons.cloud_off_rounded,
          color: const Color(0xFFEF4444),
          title: 'Server Error',
          subtitle: 'Something went wrong.\nPlease try again.');
    }
    return _ErrorConfig(
        icon: Icons.error_outline_rounded,
        color: const Color(0xFF6B7280),
        title: 'Something Went Wrong',
        subtitle: 'An unexpected error occurred.\nPlease try again.');
  }
}

class _ErrorConfig {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _ErrorConfig(
      {required this.icon,
      required this.color,
      required this.title,
      required this.subtitle});
}

// ─────────────────────────────────────────────────────────────────
// Inline Error Banner (Wishlist)
// ─────────────────────────────────────────────────────────────────
class _InlineErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _InlineErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFFFBBF24).withOpacity(0.5)),
        ),
        child: Row(children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: AppTextStyles.bodySmall.copyWith(
                    color: const Color(0xFF92400E), height: 1.4)),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('Retry',
                  style: AppTextStyles.caption.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Shimmer
// ─────────────────────────────────────────────────────────────────
class _MyCoursesShimmer extends StatefulWidget {
  const _MyCoursesShimmer();
  @override
  State<_MyCoursesShimmer> createState() => _MyCoursesShimmerState();
}

class _MyCoursesShimmerState extends State<_MyCoursesShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _box(double w, double h, {double r = 10}) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Opacity(
          opacity: _anim.value,
          child: Container(
            width: w, height: h,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(r),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _box(120, 22), const SizedBox(height: 8), _box(160, 14),
          ]),
          const Spacer(),
          _box(40, 40, r: 100),
        ]),
        const SizedBox(height: 20),
        _box(double.infinity, 90, r: 24),
        const SizedBox(height: 24),
        Row(children: [
          _box(100, 38, r: 100), const SizedBox(width: 8),
          _box(100, 38, r: 100), const SizedBox(width: 8),
          _box(80, 38, r: 100),
        ]),
        const SizedBox(height: 20),
        ...List.generate(4, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _box(double.infinity, 110, r: 16),
            )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Stats Row + Filter Tabs
// ─────────────────────────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int count;
  final int completed;
  const _StatsRow({required this.count, required this.completed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(children: [
          _GStat(value: '$count', label: 'Enrolled'),
          _VDiv(),
          _GStat(value: '$completed', label: 'Completed'),
          _VDiv(),
          _GStat(value: '$completed', label: 'Certificates'),
        ]),
      ),
    );
  }
}

class _GStat extends StatelessWidget {
  final String value;
  final String label;
  const _GStat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value,
              style: AppTextStyles.displayMedium
                  .copyWith(color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: Colors.white.withOpacity(0.8))),
        ]),
      );
}

class _VDiv extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 40,
        color: Colors.white.withOpacity(0.2),
        margin: const EdgeInsets.symmetric(horizontal: 4),
      );
}

class _FilterTabs extends StatelessWidget {
  final int selected;
  final Function(int) onSelect;
  const _FilterTabs({required this.selected, required this.onSelect});
  static const _tabs = ['In Progress', 'Completed', 'Wishlist'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final sel = selected == i;
          return Padding(
            padding: EdgeInsets.only(right: i < _tabs.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                      color: sel
                          ? AppColors.primary
                          : AppColors.cardBorder),
                ),
                child: Text(_tabs[i],
                    style: AppTextStyles.bodySmall.copyWith(
                      color: sel ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ),
          );
        }),
      ),
    );
  }
}