import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:flutter/material.dart';

class MyCoursesErrorView extends StatelessWidget {
  final AppException? exception;
  final String message;
  final VoidCallback onRetry;

  const MyCoursesErrorView({
    super.key,
    required this.exception,
    required this.message,
    required this.onRetry,
  });

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
            Text(
              cfg.subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
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