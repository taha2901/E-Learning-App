import 'package:e_learning/core/constants/app_constants.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:e_learning/features/courses/presentation/view/courses_details.dart';
import 'package:e_learning/features/courses/presentation/view/widgets/course_card.dart';
import 'package:flutter/material.dart';

class MyCoursesScreen extends StatelessWidget {
  const MyCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final enrolled =
        MockData.courses.where((c) => c.isEnrolled).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ───────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppConstants.horizontalPadding, 24,
                    AppConstants.horizontalPadding, 0),
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

            // ── Stats ────────────────────────
            SliverToBoxAdapter(
              child: _StatsRow(count: enrolled.length),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Filter Tabs ──────────────────
            SliverToBoxAdapter(
              child: _FilterTabs(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Course List ──────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.horizontalPadding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final progresses = [0.65, 0.3, 0.1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: MyCourseCard(
                        course: enrolled[i],
                        progress: i < progresses.length ? progresses[i] : 0.0,
                        onTap: () {
                          Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CourseDetailsScreen(course: enrolled[i]),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  childCount: enrolled.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
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
  const _StatsRow({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.horizontalPadding),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(AppConstants.radiusXL),
        ),
        child: Row(
          children: [
            _GradientStat(value: '$count', label: 'Enrolled'),
            _VerticalDivider(),
            const _GradientStat(value: '1', label: 'Completed'),
            _VerticalDivider(),
            const _GradientStat(value: '1', label: 'Certificates'),
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
          Text(
            value,
            style: AppTextStyles.displayMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.8)),
          ),
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
class _FilterTabs extends StatefulWidget {
  @override
  State<_FilterTabs> createState() => _FilterTabsState();
}

class _FilterTabsState extends State<_FilterTabs> {
  int _selected = 0;
  final tabs = ['In Progress', 'Completed', 'Wishlist'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.horizontalPadding),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = _selected == i;
          return Padding(
            padding: EdgeInsets.only(right: i < tabs.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => setState(() => _selected = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color:
                        selected ? AppColors.primary : AppColors.cardBorder,
                  ),
                ),
                child: Text(
                  tabs[i],
                  style: AppTextStyles.bodySmall.copyWith(
                    color: selected ? Colors.white : AppColors.textSecondary,
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