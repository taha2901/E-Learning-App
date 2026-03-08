import 'package:e_learning/core/constants/app_constants.dart';
import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/networking/notification_banner_services.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:e_learning/features/courses/data/repo/course_repo.dart';
import 'package:e_learning/features/courses/presentation/cubit/course_cubit.dart';
import 'package:e_learning/features/home/presentaion/view/courses_details.dart';
import 'package:e_learning/features/home/presentaion/cubit/home_cubit.dart';
import 'package:e_learning/features/home/presentaion/cubit/home_states.dart';
import 'package:e_learning/features/notificatio/presentation/logic/notification_cubit.dart';
import 'package:e_learning/features/notificatio/presentation/logic/notification_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => HomeCubit(CoursesRepo())..fetchCourses(),
        ),
      ],
      child: const _HomeListener(),
    );
  }
}

class _HomeListener extends StatelessWidget {
  const _HomeListener();

  @override
  Widget build(BuildContext context) {
    return BlocListener<NotificationCubit, NotificationState>(
      listener: (context, state) {
        if (state is NotificationLoaded && state.notifications.isNotEmpty) {
          final latest = state.notifications.first;
          final isNew =
              DateTime.now().difference(latest.createdAt).inSeconds < 5;
          if (!latest.isRead && isNew) {
            NotificationBannerService.show(
              context,
              title: latest.title,
              body: latest.body,
              type: latest.type,
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              if (state is HomeLoading || state is HomeInitial) {
                return const _HomeShimmer();
              }
              if (state is HomeError) {
                return _HomeErrorView(
                  exception: state.exception,
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

// ─────────────────────────────────────────────────────────────────
// ✅ Smart Error View — icon + title + subtitle حسب نوع الـ exception
// ─────────────────────────────────────────────────────────────────
class _HomeErrorView extends StatelessWidget {
  final AppException? exception;
  final String message;
  final VoidCallback onRetry;

  const _HomeErrorView({
    required this.exception,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = _config(exception);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Animated Icon Container ──────────────────────────
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: cfg.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(cfg.icon, color: cfg.color, size: 40),
              ),
            ),
            const SizedBox(height: 24),
            // ── Title ────────────────────────────────────────────
            Text(
              cfg.title,
              style: AppTextStyles.h1,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            // ── Subtitle ─────────────────────────────────────────
            Text(
              cfg.subtitle,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // ── Retry Button ─────────────────────────────────────
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
        subtitle:
            'Looks like you\'re offline.\nCheck your Wi-Fi or mobile data and try again.',
      );
    }
    if (e is TimeoutException) {
      return _ErrorConfig(
        icon: Icons.hourglass_disabled_rounded,
        color: const Color(0xFFF59E0B),
        title: 'Connection Timed Out',
        subtitle:
            'The server is taking too long to respond.\nPlease try again in a moment.',
      );
    }
    if (e is ServerException) {
      return _ErrorConfig(
        icon: Icons.cloud_off_rounded,
        color: const Color(0xFFEF4444),
        title: 'Server Error',
        subtitle:
            'Something went wrong on our end.\nWe\'re working on it — please try again.',
      );
    }
    // AppAuthException or Unknown
    return _ErrorConfig(
      icon: Icons.error_outline_rounded,
      color: const Color(0xFF6B7280),
      title: 'Something Went Wrong',
      subtitle: 'An unexpected error occurred.\nPlease try again.',
    );
  }
}

class _ErrorConfig {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _ErrorConfig({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}

// ─────────────────────────────────────────────────────────────────
// Home Content
// ─────────────────────────────────────────────────────────────────
class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _HomeAppBar()),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(child: _SearchBar()),
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
        SliverToBoxAdapter(child: _CategorySelector()),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            child: Row(children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(width: 8),
              Text('Featured', style: AppTextStyles.h2),
            ]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        SliverToBoxAdapter(child: _FeaturedCoursesList()),
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            child: Row(children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(width: 8),
              Text('All Courses', style: AppTextStyles.h2),
              const Spacer(),
              BlocBuilder<HomeCubit, HomeState>(
                builder: (ctx, state) {
                  final count = state is HomeLoaded
                      ? ctx.read<HomeCubit>().filteredCourses.length
                      : 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '$count courses',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 14)),
        _CoursesList(),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// App Bar
// ─────────────────────────────────────────────────────────────────
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
          AppConstants.horizontalPadding, 20,
          AppConstants.horizontalPadding, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $firstName 👋',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text('What will you\nlearn today?', style: AppTextStyles.h1),
              ],
            ),
          ),
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
                      color: AppColors.primary.withOpacity(0.3), width: 2),
                  color: AppColors.primary.withOpacity(0.08),
                ),
                child: ClipOval(
                  child: avatarUrl.isNotEmpty
                      ? Image.network(avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _avatarFallback(firstName))
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

  Widget _avatarFallback(String name) => Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: AppTextStyles.h3.copyWith(
              color: AppColors.primary, fontWeight: FontWeight.w700),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────
// Search Bar
// ─────────────────────────────────────────────────────────────────
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
          horizontal: AppConstants.horizontalPadding),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: TextField(
          controller: _controller,
          onChanged: (v) => context.read<HomeCubit>().searchCourses(v),
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search courses...',
            hintStyle:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.textHint, size: 20),
            suffixIcon: BlocBuilder<HomeCubit, HomeState>(
              builder: (ctx, state) {
                final query = state is HomeLoaded ? state.searchQuery : '';
                if (query.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: () {
                    _controller.clear();
                    ctx.read<HomeCubit>().searchCourses('');
                  },
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.textHint, size: 18),
                );
              },
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Category Selector
// ─────────────────────────────────────────────────────────────────
class _CategorySelector extends StatelessWidget {
  static const _categories = [
    'All', 'Mobile Dev', 'Web Dev', 'Design', 'Data Science', 'AI & ML',
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final selected = state is HomeLoaded ? state.selectedCategory : 'All';
        return SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final cat = _categories[i];
              final sel = selected == cat;
              return GestureDetector(
                onTap: () => context.read<HomeCubit>().selectCategory(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                        color: sel ? AppColors.primary : AppColors.cardBorder),
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: AppTextStyles.caption.copyWith(
                        color: sel ? Colors.white : AppColors.textSecondary,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      ),
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

// ─────────────────────────────────────────────────────────────────
// Featured Courses
// ─────────────────────────────────────────────────────────────────
class _FeaturedCoursesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is! HomeLoaded) return const SizedBox.shrink();
        final featured = state.featuredCourses;
        if (featured.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding),
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemCount: featured.length,
            itemBuilder: (_, i) => _FeaturedCard(
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
      MaterialPageRoute(builder: (_) => CourseDetailsScreen(course: course)),
    ).then((_) {
      if (context.mounted) context.read<HomeCubit>().fetchCourses();
    });
  }
}

class _FeaturedCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;
  const _FeaturedCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              course.thumbnailUrl.isNotEmpty
                  ? Image.network(course.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _gradientBg())
                  : _gradientBg(),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.78),
                    ],
                    stops: const [0.3, 1.0],
                  ),
                ),
              ),
              Positioned(
                bottom: 14, left: 14, right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        course.category,
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      course.title,
                      style: AppTextStyles.h3.copyWith(color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Row(children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFBBF24), size: 13),
                      const SizedBox(width: 3),
                      Text(
                        course.rating.toStringAsFixed(1),
                        style: AppTextStyles.caption.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.schedule_outlined,
                          color: Colors.white60, size: 12),
                      const SizedBox(width: 3),
                      Text(
                        course.duration,
                        style: AppTextStyles.caption
                            .copyWith(color: Colors.white60),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradientBg() => Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: const Center(
            child: Icon(Icons.school_outlined, color: Colors.white38, size: 48)),
      );
}

// ─────────────────────────────────────────────────────────────────
// All Courses — vertical list
// ─────────────────────────────────────────────────────────────────
class _CoursesList extends StatelessWidget {
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
              padding: const EdgeInsets.only(top: 48),
              child: Column(children: [
                Icon(Icons.search_off_rounded,
                    size: 52, color: AppColors.textHint),
                const SizedBox(height: 12),
                Text('No courses found',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
              ]),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.horizontalPadding),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CourseRowCard(
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
    ).then((_) {
      if (context.mounted) context.read<HomeCubit>().fetchCourses();
    });
  }
}

// ─────────────────────────────────────────────────────────────────
// Course Row Card
// ─────────────────────────────────────────────────────────────────
class _CourseRowCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onTap;
  const _CourseRowCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 82,
              height: 82,
              child: course.thumbnailUrl.isNotEmpty
                  ? Image.network(course.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbFallback())
                  : _thumbFallback(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.category.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(course.title,
                    style: AppTextStyles.h3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(course.instructor,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFBBF24), size: 13),
                  const SizedBox(width: 2),
                  Text(course.rating.toStringAsFixed(1),
                      style: AppTextStyles.caption
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                          color: AppColors.textHint, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(course.duration,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(course.level,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary, fontSize: 10)),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _thumbFallback() => Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: const Center(
            child: Icon(Icons.play_lesson_outlined,
                color: Colors.white54, size: 28)),
      );
}

// ─────────────────────────────────────────────────────────────────
// Shimmer
// ─────────────────────────────────────────────────────────────────
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
            width: w,
            height: h,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.horizontalPadding),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 20),
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _box(110, 13),
              const SizedBox(height: 8),
              _box(170, 22),
              const SizedBox(height: 4),
              _box(140, 22),
            ]),
            const Spacer(),
            _box(46, 46, r: 100),
          ]),
          const SizedBox(height: 20),
          _box(double.infinity, 50, r: 14),
          const SizedBox(height: 20),
          Row(children: [
            _box(50, 34, r: 100),
            const SizedBox(width: 8),
            _box(90, 34, r: 100),
            const SizedBox(width: 8),
            _box(70, 34, r: 100),
          ]),
          const SizedBox(height: 28),
          _box(90, 18),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, __) => _box(240, 190, r: 20),
            ),
          ),
          const SizedBox(height: 28),
          _box(100, 18),
          const SizedBox(height: 14),
          ...List.generate(
              3,
              (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _box(double.infinity, 102, r: 16),
                  )),
        ]),
      ),
    );
  }
}