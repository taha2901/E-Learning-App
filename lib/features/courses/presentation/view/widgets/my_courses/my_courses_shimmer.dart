import 'package:e_learning/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class MyCoursesShimmer extends StatefulWidget {
  const MyCoursesShimmer({super.key});

  @override
  State<MyCoursesShimmer> createState() => _MyCoursesShimmerState();
}

class _MyCoursesShimmerState extends State<MyCoursesShimmer>
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _box(120, 22),
              const SizedBox(height: 8),
              _box(160, 14),
            ]),
            const Spacer(),
            _box(40, 40, r: 100),
          ]),
          const SizedBox(height: 20),
          _box(double.infinity, 90, r: 24),
          const SizedBox(height: 24),
          Row(children: [
            _box(100, 38, r: 100),
            const SizedBox(width: 8),
            _box(100, 38, r: 100),
            const SizedBox(width: 8),
            _box(80, 38, r: 100),
          ]),
          const SizedBox(height: 20),
          ...List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _box(double.infinity, 110, r: 16),
            ),
          ),
        ],
      ),
    );
  }
}