import 'package:e_learning/features/courses/presentation/cubit/course_cubit.dart';
import 'package:e_learning/features/courses/presentation/cubit/course_states.dart';
import 'package:e_learning/features/courses/presentation/view/widgets/course_card.dart';
import 'package:e_learning/features/courses/presentation/view/widgets/my_courses_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_learning/features/courses/data/repo/course_repo.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';

class MyCoursesScreen extends StatefulWidget {
  final String userId;
  const MyCoursesScreen({super.key, required this.userId});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  int _selectedTab = 0;
  Map<String, Set<String>> _watchedMap = {};
  List<CourseModel> _wishlist = [];

  void _updateWatched(String courseId, String videoId) {
    setState(() {
      _watchedMap[courseId] = (_watchedMap[courseId] ?? {})..add(videoId);
    });
  }

  double _progress(CourseModel c) {
    final total = c.videos.length;
    if (total == 0) return 0.0;
    return (_watchedMap[c.id]?.length ?? 0) / total;
  }

  void _prefetch(List<CourseModel> courses) {
    for (final c in courses) {
      if (!_watchedMap.containsKey(c.id)) {
        _watchedMap[c.id] = {};
        CoursesRepo()
            .fetchWatchedVideoIds(widget.userId, c.id)
            .then((ids) { if (mounted) setState(() => _watchedMap[c.id] = ids); });
      }
    }
  }

  Future<void> _loadWishlist() async {
    final list = await CoursesRepo().fetchWishlist(widget.userId);
    if (mounted) setState(() => _wishlist = list);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CoursesCubit(CoursesRepo(), widget.userId)..fetchMyCourses(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: BlocBuilder<CoursesCubit, CoursesState>(
            builder: (context, state) {
              if (state is CoursesLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is CoursesError) {
                return Center(child: Text(state.message));
              } else if (state is CoursesLoaded) {
                final enrolled = state.courses;
                _prefetch(enrolled);

                final completed = enrolled
                    .where((c) => c.videos.isNotEmpty && _progress(c) >= 1.0)
                    .toList();
                final inProgress = enrolled
                    .where((c) => _progress(c) < 1.0)
                    .toList();

                List<CourseModel> displayList;
                if (_selectedTab == 0) displayList = inProgress;
                else if (_selectedTab == 1) displayList = completed;
                else displayList = _wishlist;

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('My Courses', style: AppTextStyles.displayMedium),
                            const SizedBox(height: 4),
                            Text('${enrolled.length} courses enrolled',
                                style: AppTextStyles.bodyMedium),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    SliverToBoxAdapter(
                      child: _StatsRow(
                        count: enrolled.length,
                        completed: completed.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    SliverToBoxAdapter(
                      child: _FilterTabs(
                        selected: _selectedTab,
                        onSelect: (i) {
                          setState(() => _selectedTab = i);
                          if (i == 2 && _wishlist.isEmpty) _loadWishlist();
                        },
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 20)),
                    if (displayList.isEmpty)
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
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(color: AppColors.textSecondary),
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
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final course = displayList[i];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: MyCourseCard(
                                  course: course,
                                  progress: _progress(course),
                                  onTap: () async {
                                    await Navigator.push(
                                      ctx,
                                      MaterialPageRoute(
                                        builder: (_) => MyCourseDetailsScreen(
                                          course: course,
                                          userId: widget.userId,
                                          onVideoWatched: (videoId) =>
                                              _updateWatched(course.id, videoId),
                                        ),
                                      ),
                                    );
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

// ─────────────────────────────────────────────
// Stats Row
// ─────────────────────────────────────────────
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
        child: Row(
          children: [
            _GradientStat(value: '$count', label: 'Enrolled'),
            _VerticalDivider(),
            _GradientStat(value: '$completed', label: 'Completed'),
            _VerticalDivider(),
            _GradientStat(value: '$completed', label: 'Certificates'),
          ],
        ),
      ),
    );
  }
}

class _GradientStat extends StatelessWidget {
  final String value;
  final String label;
  const _GradientStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.displayMedium.copyWith(color: Colors.white)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.bodySmall
                  .copyWith(color: Colors.white.withOpacity(0.8))),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

// ─────────────────────────────────────────────
// Filter Tabs
// ─────────────────────────────────────────────
class _FilterTabs extends StatelessWidget {
  final int selected;
  final Function(int) onSelect;
  const _FilterTabs({required this.selected, required this.onSelect});

  final tabs = const ['In Progress', 'Completed', 'Wishlist'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = selected == i;
          return Padding(
            padding: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.cardBorder,
                  ),
                ),
                child: Text(
                  tabs[i],
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}