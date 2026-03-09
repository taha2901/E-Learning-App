import 'package:e_learning/core/constants/app_constants.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/courses/data/model/courses.dart';
import 'package:flutter/material.dart';

class CourseAboutTab extends StatelessWidget {
  final CourseModel course;

  const CourseAboutTab({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('About this Course', style: AppTextStyles.h2),
          const SizedBox(height: 12),
          Text(course.description,
              style: AppTextStyles.bodyLarge.copyWith(height: 1.7)),
          const SizedBox(height: 24),
          Text('What you will learn', style: AppTextStyles.h2),
          const SizedBox(height: 12),
          ...const [
            'Build real-world projects from scratch',
            'Understand core concepts deeply',
            'Write clean and maintainable code',
            'Deploy and publish your projects',
          ].map((item) => _LearnItem(text: item)),
        ],
      ),
    );
  }
}

class _LearnItem extends StatelessWidget {
  final String text;

  const _LearnItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 3),
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
                color: AppColors.success, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 13),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text, style: AppTextStyles.bodyLarge)),
        ],
      ),
    );
  }
}