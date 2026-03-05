import 'package:e_learning/core/constants/app_constants.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:e_learning/features/courses/data/repo/course_repo.dart';
import 'package:e_learning/features/courses/presentation/cubit/course_cubit.dart';
import 'package:e_learning/features/home/presentaion/view/courses_details.dart';
import 'package:e_learning/features/courses/presentation/view/widgets/course_card.dart';
import 'package:e_learning/features/home/presentaion/cubit/home_cubit.dart';
import 'package:e_learning/features/home/presentaion/cubit/home_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeCubit(CoursesRepo())..fetchCourses(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              if (state is HomeLoading || state is HomeInitial) {
                return const _HomeShimmer();
              }
              if (state is HomeError) {
                return _ErrorView(
                  message: state.message,
                  onRetry: () => context.read<HomeCubit>().fetchCourses(),
                );
              }
              return const _HomeContent();
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Home Content (shown when loaded)
// ─────────────────────────────────────────────────────────────────────────────
class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _HomeAppBar()),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        SliverToBoxAdapter(child: _SearchBar()),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(child: _CategorySelector()),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(child: _SectionHeader(title: 'Featured Courses')),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverToBoxAdapter(child: _FeaturedCoursesList()),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
        SliverToBoxAdapter(child: _SectionHeader(title: 'All Courses')),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        _CourseGrid(),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App Bar — بيجيب اسم اليوزر الحقيقي
// ─────────────────────────────────────────────────────────────────────────────
class _HomeAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final meta = user?.userMetadata;
    final name =
        meta?['name'] as String? ?? user?.email?.split('@').first ?? 'there';
    final firstName = name.split(' ').first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.horizontalPadding,
        20,
        AppConstants.horizontalPadding,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $firstName 👋',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'What do you want to\nlearn today?',
                  style: AppTextStyles.h1,
                ),
              ],
            ),
          ),
          // Avatar
          FutureBuilder<Map<String, dynamic>?>(
            future: _fetchAvatar(user?.id ?? ''),
            builder: (ctx, snap) {
              final avatarUrl = snap.data?['avatar_url'] as String? ?? '';
              return Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                  color: AppColors.primary.withOpacity(0.1),
                ),
                child: ClipOval(
                  child: avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _avatarFallback(firstName),
                        )
                      : _avatarFallback(firstName),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _fetchAvatar(String userId) async {
    if (userId.isEmpty) return null;
    try {
      return await Supabase.instance.client
          .from('profiles')
          .select('avatar_url')
          .eq('user_id', userId)
          .maybeSingle();
    } catch (_) {
      return null;
    }
  }

  Widget _avatarFallback(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: AppTextStyles.h3.copyWith(color: AppColors.primary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.horizontalPadding,
      ),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.h2),
          const Spacer(),
          Text(
            'See all',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Bar
// ─────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatefulWidget {
  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.horizontalPadding,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _controller,
          onChanged: (v) => context.read<HomeCubit>().searchCourses(v),
          decoration: InputDecoration(
            hintText: 'Search courses...',
            hintStyle: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textHint,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textHint,
              size: 22,
            ),
            suffixIcon: BlocBuilder<HomeCubit, HomeState>(
              builder: (ctx, state) {
                final query = state is HomeLoaded ? state.searchQuery : '';
                if (query.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () {
                    _controller.clear();
                    ctx.read<HomeCubit>().searchCourses('');
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textHint,
                    size: 18,
                  ),
                );
              },
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Selector — مضبوطة صح
// ─────────────────────────────────────────────────────────────────────────────
class _CategorySelector extends StatelessWidget {
  static const _categories = [
    'All',
    'Mobile Dev',
    'Web Dev',
    'Design',
    'Data Science',
    'AI & ML',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final selected = state is HomeLoaded ? state.selectedCategory : 'All';

        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.horizontalPadding,
            ),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final isSelected = selected == cat;
              return GestureDetector(
                onTap: () => context.read<HomeCubit>().selectCategory(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.cardBorder,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    cat,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Featured Courses List
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturedCoursesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is! HomeLoaded) return const SizedBox.shrink();
        final featured = state.featuredCourses;
        if (featured.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.horizontalPadding,
            ),
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemCount: featured.length,
            itemBuilder: (_, i) => CourseHorizontalCard(
              course: featured[i],
              onTap: () => _openDetails(context, featured[i]),
            ),
          ),
        );
      },
    );
  }

  void _openDetails(BuildContext context, CourseModel course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CoursesCubit>(),
          child: CourseDetailsScreen(course: course),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Course Grid — مع empty state
// ─────────────────────────────────────────────────────────────────────────────
class _CourseGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is! HomeLoaded) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        final courses = context.read<HomeCubit>().filteredCourses;

        if (courses.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 56,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No courses found',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.horizontalPadding,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: CourseCard(
                  course: courses[i],
                  onTap: () => _openDetails(ctx, courses[i]),
                ),
              ),
              childCount: courses.length,
            ),
          ),
        );
      },
    );
  }

  void _openDetails(BuildContext context, CourseModel course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CoursesCubit>(),
          child: CourseDetailsScreen(course: course),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer Loading
// ─────────────────────────────────────────────────────────────────────────────
class _HomeShimmer extends StatefulWidget {
  const _HomeShimmer();

  @override
  State<_HomeShimmer> createState() => _HomeShimmerState();
}

class _HomeShimmerState extends State<_HomeShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.horizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // AppBar shimmer
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(w: 120, h: 14, opacity: _anim.value),
                      const SizedBox(height: 8),
                      _ShimmerBox(w: 200, h: 22, opacity: _anim.value),
                      const SizedBox(height: 4),
                      _ShimmerBox(w: 160, h: 22, opacity: _anim.value),
                    ],
                  ),
                  const Spacer(),
                  _ShimmerBox(w: 46, h: 46, radius: 100, opacity: _anim.value),
                ],
              ),
              const SizedBox(height: 24),
              // Search shimmer
              _ShimmerBox(
                w: double.infinity,
                h: 52,
                radius: 14,
                opacity: _anim.value,
              ),
              const SizedBox(height: 20),
              // Categories shimmer
              Row(
                children: List.generate(
                  4,
                  (i) => Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                    child: _ShimmerBox(
                      w: 80,
                      h: 36,
                      radius: 100,
                      opacity: _anim.value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Featured label
              _ShimmerBox(w: 140, h: 18, opacity: _anim.value),
              const SizedBox(height: 12),
              // Featured cards
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (_, __) => _ShimmerBox(
                    w: 260,
                    h: 220,
                    radius: 20,
                    opacity: _anim.value,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              // All courses label
              _ShimmerBox(w: 100, h: 18, opacity: _anim.value),
              const SizedBox(height: 12),
              // Course cards
              ...List.generate(
                3,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ShimmerBox(
                    w: double.infinity,
                    h: 110,
                    radius: 16,
                    opacity: _anim.value,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double w;
  final double h;
  final double radius;
  final double opacity;

  const _ShimmerBox({
    required this.w,
    required this.h,
    this.radius = 10,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: AppColors.cardBorder,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error View
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.error,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Oops! Something went wrong',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
