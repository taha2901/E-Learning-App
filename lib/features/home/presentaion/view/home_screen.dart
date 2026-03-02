import 'package:e_learning/core/constants/app_constants.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/core/widgets/category_chip.dart';
import 'package:e_learning/core/widgets/sec_header.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:e_learning/features/courses/presentation/view/courses_details.dart';
import 'package:e_learning/features/courses/presentation/view/widgets/course_card.dart';
import 'package:e_learning/features/home/presentaion/cubit/home_cubit.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _vm = HomeViewModel();
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────
            SliverToBoxAdapter(child: _HomeAppBar()),

            // ── Search Bar ──────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.horizontalPadding,
                  vertical: 12,
                ),
                child: _SearchBar(controller: _searchController),
              ),
            ),

            // ── Categories ──────────────────
            SliverToBoxAdapter(
              child: _CategorySelector(vm: _vm),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Featured Section ────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.horizontalPadding),
                child: SectionHeader(
                  title: 'Featured Courses',
                  actionLabel: 'See all',
                  onActionTap: () {},
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverToBoxAdapter(
              child: _FeaturedCoursesList(vm: _vm),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ── All Courses ─────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.horizontalPadding),
                child: SectionHeader(
                  title: 'All Courses',
                  actionLabel: 'Filter',
                  onActionTap: () {},
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ── Course Grid ─────────────────
            _CourseGrid(vm: _vm),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Home App Bar
// ─────────────────────────────────────────────
class _HomeAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.horizontalPadding,
        20,
        AppConstants.horizontalPadding,
        0,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, Ahmed 👋', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 2),
              Text('What do you want to\nlearn today?',
                  style: AppTextStyles.h1),
            ],
          ),
          const Spacer(),
          // Notification Button
          _IconButton(
            icon: Icons.notifications_outlined,
            onTap: () {},
          ),
          const SizedBox(width: 8),
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(MockData.currentUser.avatarUrl),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Search Bar
// ─────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusL),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: TextField(
        controller: controller,
        style: AppTextStyles.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Search courses, instructors...',
          hintStyle: AppTextStyles.bodyMedium,
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textHint, size: 22),
          suffixIcon: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Category Selector
// ─────────────────────────────────────────────
class _CategorySelector extends StatefulWidget {
  final HomeViewModel vm;
  const _CategorySelector({required this.vm});

  @override
  State<_CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<_CategorySelector> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.horizontalPadding),
        itemCount: widget.vm.categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = widget.vm.categories[i];
          return CategoryChip(
            label: cat,
            isSelected: widget.vm.selectedCategory == cat,
            onTap: () {
              setState(() => widget.vm.onCategorySelected(cat));
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Featured Courses Horizontal List
// ─────────────────────────────────────────────
class _FeaturedCoursesList extends StatelessWidget {
  final HomeViewModel vm;
  const _FeaturedCoursesList({required this.vm});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.horizontalPadding),
        itemCount: MockData.courses.take(4).length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (ctx, i) {
          final course = MockData.courses[i];
          return CourseHorizontalCard(
            course: course,
            onTap: () => _openDetails(ctx, course),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// All Courses Grid
// ─────────────────────────────────────────────
class _CourseGrid extends StatelessWidget {
  final HomeViewModel vm;
  const _CourseGrid({required this.vm});

  @override
  Widget build(BuildContext context) {
    final courses = MockData.courses;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.horizontalPadding),
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
  }
}

// ─────────────────────────────────────────────
// Icon Button
// ─────────────────────────────────────────────
class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 22),
      ),
    );
  }
}

void _openDetails(BuildContext context, course) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CourseDetailsScreen(course: course),
    ),
  );
}