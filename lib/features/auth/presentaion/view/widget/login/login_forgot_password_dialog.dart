import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/core/widgets/custom_text_feild.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginForgotPasswordDialog extends StatelessWidget {
  const LoginForgotPasswordDialog({super.key});

  /// استخدم هذا المتود عشان تفتح الدايلوج من أي مكان
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const LoginForgotPasswordDialog(),
    );
  }

  void _showSnack(BuildContext context, String msg, {IconData? icon, Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon ?? Icons.info_outline_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: color ?? AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController();

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Reset Password', style: AppTextStyles.h2),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enter your email and we'll send you a reset link.",
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Email Address',
            hint: 'you@example.com',
            prefixIcon: Icons.email_outlined,
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            if (ctrl.text.trim().isEmpty) return;
            try {
              await Supabase.instance.client.auth.resetPasswordForEmail(
                ctrl.text.trim(),
              );
              if (context.mounted) {
                _showSnack(
                  context,
                  'Reset link sent! Check your email.',
                  icon: Icons.mark_email_read_outlined,
                  color: AppColors.success,
                );
              }
            } catch (_) {
              if (context.mounted) {
                _showSnack(context, 'Could not send reset email. Try again.');
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text('Send Link', style: AppTextStyles.labelMedium),
        ),
      ],
    );
  }
}