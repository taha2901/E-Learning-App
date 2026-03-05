import 'package:e_learning/core/constants/app_constants.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/core/widgets/custom_btn.dart';
import 'package:e_learning/core/widgets/custom_text_feild.dart';
import 'package:e_learning/features/auth/data/repo/auth_repo.dart';
import 'package:e_learning/features/auth/presentaion/cubit/auth_cubit.dart';
import 'package:e_learning/features/auth/presentaion/cubit/auth_states.dart';
import 'package:e_learning/features/auth/presentaion/view/register_screen.dart';
import 'package:e_learning/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit(AuthRepo()),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is LoginSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => MainShell(userId: state.userId),
              ),
            );
          }

          if (state is LoginFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    const _BrandHeader(),
                    const SizedBox(height: 40),

                    Text('Welcome back 👋', style: AppTextStyles.displayMedium),
                    const SizedBox(height: 8),

                    Text(
                      'Sign in to continue your learning journey',
                      style: AppTextStyles.bodyMedium,
                    ),

                    const SizedBox(height: 36),

                    /// EMAIL
                    AppTextField(
                      label: 'Email Address',
                      hint: 'you@example.com',
                      prefixIcon: Icons.email_outlined,
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter email";
                        }
                        if (!value.contains("@")) {
                          return "Invalid email";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    /// PASSWORD
                    AppTextField(
                      label: 'Password',
                      hint: '••••••••',
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                      controller: passwordController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Enter password";
                        }
                        if (value.length < 6) {
                          return "Password too short";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    /// BUTTON
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        if (state is LoginLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return AppPrimaryButton(
                          label: 'Sign In',
                          onTap: () {
                            if (_formKey.currentState!.validate()) {
                              context.read<AuthCubit>().login(
                                email: emailController.text.trim(),
                                password: passwordController.text.trim(),
                              );
                            }
                          },
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    /// OR Divider
                    const _OrDivider(),
                    const SizedBox(height: 32),

                    // Social Login
                    _SocialLoginButton(
                      icon: Icons.g_mobiledata_rounded,
                      label: 'Continue with Google',
                      onTap: () {},
                    ),

                    const SizedBox(height: 40),

                    // Register Link
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: AppTextStyles.bodyMedium,
                            children: [
                              TextSpan(
                                text: 'Sign Up',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.school_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConstants.appName,
              style: AppTextStyles.h1.copyWith(color: AppColors.primary),
            ),
            Text(AppConstants.appTagline, style: AppTextStyles.caption),
          ],
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.cardBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('or', style: AppTextStyles.bodySmall),
        ),
        const Expanded(child: Divider(color: AppColors.cardBorder)),
      ],
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialLoginButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppConstants.radiusL),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 26),
            const SizedBox(width: 10),
            Text(label,
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}