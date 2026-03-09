import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/core/widgets/custom_text_feild.dart';
import 'package:e_learning/features/auth/presentaion/view/widget/login/login_forgot_password_dialog.dart';
import 'package:flutter/material.dart';

class LoginFormSection extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? emailError;
  final String? passwordError;
  final VoidCallback onEmailErrorClear;
  final VoidCallback onPasswordErrorClear;

  const LoginFormSection({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.emailError,
    required this.passwordError,
    required this.onEmailErrorClear,
    required this.onPasswordErrorClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Email field
        AppTextField(
          label: 'Email Address',
          hint: 'you@example.com',
          prefixIcon: Icons.email_outlined,
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => onEmailErrorClear(),
          validator: (v) {
            if (emailError != null) return emailError;
            if (v == null || v.isEmpty) return 'Enter your email';
            if (!RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(v)) {
              return 'Enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // ── Password field
        AppTextField(
          label: 'Password',
          hint: '••••••••',
          prefixIcon: Icons.lock_outline_rounded,
          isPassword: true,
          controller: passwordController,
          onChanged: (_) => onPasswordErrorClear(),
          validator: (v) {
            if (passwordError != null) return passwordError;
            if (v == null || v.isEmpty) return 'Enter your password';
            if (v.length < 6) return 'Password is too short';
            return null;
          },
        ),
        const SizedBox(height: 8),

        // ── Forgot password
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => LoginForgotPasswordDialog.show(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Forgot password?',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}