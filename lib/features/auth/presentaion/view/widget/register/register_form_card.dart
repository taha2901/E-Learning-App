import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/widgets/custom_text_feild.dart';
import 'package:e_learning/features/auth/presentaion/view/widget/register/register_password_strength_bar.dart';
import 'package:e_learning/features/auth/presentaion/view/widget/register/register_submit_button.dart';
import 'package:e_learning/features/auth/presentaion/view/widget/register/register_terms_checkbox.dart';
import 'package:flutter/material.dart';

class RegisterFormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController phoneController;
  final String? emailError;
  final VoidCallback onEmailErrorClear;
  final bool acceptedTerms;
  final VoidCallback onTermsToggle;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasMinLength;
  final VoidCallback onRegister;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;

  const RegisterFormCard({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.phoneController,
    required this.emailError,
    required this.onEmailErrorClear,
    required this.acceptedTerms,
    required this.onTermsToggle,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasMinLength,
    required this.onRegister,
    required this.fadeAnim,
    required this.slideAnim,
  });

  bool get _passwordStrong =>
      hasUppercase && hasLowercase && hasDigit && hasMinLength;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                AppTextField(
                  label: 'Full Name',
                  hint: 'Ahmed Mohamed',
                  prefixIcon: Icons.person_outline_rounded,
                  controller: nameController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter your full name';
                    if (v.trim().length < 3) return 'Name is too short';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                AppTextField(
                  label: 'Phone Number',
                  hint: '01012345678',
                  prefixIcon: Icons.phone_outlined,
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your phone number';
                    if (!RegExp(r'^[0-9+\-\s]{7,15}$').hasMatch(v)) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
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
                    if (!RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$')
                        .hasMatch(v)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                AppTextField(
                  label: 'Password',
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  controller: passwordController,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter a password';
                    if (!_passwordStrong) return "Password doesn't meet requirements";
                    return null;
                  },
                ),

                // Password strength indicator
                if (passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  RegisterPasswordStrengthBar(
                    hasUppercase: hasUppercase,
                    hasLowercase: hasLowercase,
                    hasDigit: hasDigit,
                    hasMinLength: hasMinLength,
                  ),
                ],
                const SizedBox(height: 16),

                // Confirm password
                AppTextField(
                  label: 'Confirm Password',
                  hint: '••••••••',
                  prefixIcon: Icons.lock_outline_rounded,
                  isPassword: true,
                  controller: confirmPasswordController,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirm your password';
                    if (v != passwordController.text) return "Passwords don't match";
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Terms
                RegisterTermsCheckbox(
                  accepted: acceptedTerms,
                  onToggle: onTermsToggle,
                ),
                const SizedBox(height: 24),

                // Submit button
                RegisterSubmitButton(onTap: onRegister),
              ],
            ),
          ),
        ),
      ),
    );
  }
}