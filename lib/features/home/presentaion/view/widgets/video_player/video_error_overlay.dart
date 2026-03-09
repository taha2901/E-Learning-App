import 'package:e_learning/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

enum VideoErrorType { noInternet, timeout, unavailable, unknown }

class VideoErrorOverlay extends StatelessWidget {
  final VideoErrorType errorType;
  final VoidCallback? onRetry;

  const VideoErrorOverlay({
    super.key,
    required this.errorType,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = _config(errorType);
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(cfg.icon, color: Colors.white60, size: 34),
              ),
              const SizedBox(height: 16),
              Text(
                cfg.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                cfg.subtitle,
                style: const TextStyle(
                  color: Colors.white54,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null && errorType != VideoErrorType.unavailable) ...[
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: onRetry,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Try Again',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  _VideoErrorConfig _config(VideoErrorType type) {
    switch (type) {
      case VideoErrorType.noInternet:
        return _VideoErrorConfig(
          icon: Icons.wifi_off_rounded,
          title: 'No Internet Connection',
          subtitle: 'Check your Wi-Fi or mobile data\nthen try again.',
        );
      case VideoErrorType.timeout:
        return _VideoErrorConfig(
          icon: Icons.hourglass_disabled_rounded,
          title: 'Video Took Too Long',
          subtitle: 'The video is taking too long to load.\nPlease try again.',
        );
      case VideoErrorType.unavailable:
        return _VideoErrorConfig(
          icon: Icons.videocam_off_rounded,
          title: 'Video Unavailable',
          subtitle: 'This video is no longer available\nor has been removed.',
        );
      case VideoErrorType.unknown:
        return _VideoErrorConfig(
          icon: Icons.error_outline_rounded,
          title: 'Failed to Load Video',
          subtitle:
              'Something went wrong while loading\nthis video. Please try again.',
        );
    }
  }
}

class _VideoErrorConfig {
  final IconData icon;
  final String title;
  final String subtitle;
  const _VideoErrorConfig(
      {required this.icon, required this.title, required this.subtitle});
}