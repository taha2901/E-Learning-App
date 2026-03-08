import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:flutter/material.dart';

class AppErrorWidget extends StatelessWidget {
  final AppException exception;
  final VoidCallback? onRetry;

  const AppErrorWidget({
    super.key,
    required this.exception,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final config = _ErrorConfig.from(exception);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: config.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(config.icon, size: 40, color: config.color),
            ),
            const SizedBox(height: 20),
            Text(
              config.title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              exception.details ?? exception.message,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Color(0xFF9E9E9E),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Try Again',
                    style: TextStyle(
                        fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorConfig {
  final IconData icon;
  final String title;
  final Color color;
  const _ErrorConfig({required this.icon, required this.title, required this.color});

  factory _ErrorConfig.from(AppException e) {
    if (e is NoInternetException) {
      return const _ErrorConfig(
          icon: Icons.wifi_off_rounded,
          title: 'No Internet',
          color: Color(0xFF607D8B));
    }
    if (e is TimeoutException) {
      return const _ErrorConfig(
          icon: Icons.hourglass_disabled_rounded,
          title: 'Request Timed Out',
          color: Color(0xFFFF9800));
    }
    if (e is ServerException) {
      return const _ErrorConfig(
          icon: Icons.cloud_off_rounded,
          title: 'Server Error',
          color: Color(0xFFF44336));
    }
    if (e is AppAuthException) {
      return const _ErrorConfig(
          icon: Icons.lock_outline_rounded,
          title: 'Authentication Error',
          color: Color(0xFF9C27B0));
    }
    return const _ErrorConfig(
        icon: Icons.error_outline_rounded,
        title: 'Something Went Wrong',
        color: Color(0xFF757575));
  }
}