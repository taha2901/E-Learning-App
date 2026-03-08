// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// notification_banner.dart — In-App Overlay Banner + Sound
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'package:audioplayers/audioplayers.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/notificatio/data/model/notification_model.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────
// NotificationBannerService — استخدمه من أي حتة في التطبيق
// ─────────────────────────────────────────────────────────────────
class NotificationBannerService {
  static OverlayEntry? _currentEntry;
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String body,
    NotificationType type = NotificationType.general,
    VoidCallback? onTap,
  }) async {
    // أخفي اللي قبله لو موجود
    _currentEntry?.remove();
    _currentEntry = null;

    // شغّل الصوت
    try {
      await _player.play(AssetSource('sounds/notification.mp3'));
    } catch (_) {}

    final overlay = Overlay.of(context);

    _currentEntry = OverlayEntry(
      builder: (_) => _NotificationBanner(
        title: title,
        body: body,
        type: type,
        onTap: onTap,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );

    overlay.insert(_currentEntry!);

    // اختفي تلقائي بعد 4 ثواني
    await Future.delayed(const Duration(seconds: 4));
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

// ─────────────────────────────────────────────────────────────────
// البانر نفسه
// ─────────────────────────────────────────────────────────────────
class _NotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final NotificationType type;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const _NotificationBanner({
    required this.title,
    required this.body,
    required this.type,
    required this.onDismiss,
    this.onTap,
  });

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final config = _typeConfig(widget.type);

    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: GestureDetector(
            onTap: () {
              _dismiss();
              widget.onTap?.call();
            },
            onVerticalDragUpdate: (d) {
              if (d.delta.dy < -5) _dismiss(); // swipe up to dismiss
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: config.color.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: config.color.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: config.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(config.icon, color: config.color, size: 24),
                    ),
                    const SizedBox(width: 12),

                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: AppTextStyles.h3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.body,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Close
                    GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _TypeConfig _typeConfig(NotificationType type) {
    switch (type) {
      case NotificationType.quiz:
        return _TypeConfig(
          icon: Icons.quiz_rounded,
          color: const Color(0xFF6C63FF),
        );
      case NotificationType.course:
        return _TypeConfig(
          icon: Icons.play_circle_rounded,
          color: AppColors.primary,
        );
      case NotificationType.achievement:
        return _TypeConfig(
          icon: Icons.workspace_premium_rounded,
          color: const Color(0xFFF59E0B),
        );
      case NotificationType.general:
        return _TypeConfig(
          icon: Icons.notifications_rounded,
          color: AppColors.textSecondary,
        );
    }
  }
}

class _TypeConfig {
  final IconData icon;
  final Color color;
  const _TypeConfig({required this.icon, required this.color});
}