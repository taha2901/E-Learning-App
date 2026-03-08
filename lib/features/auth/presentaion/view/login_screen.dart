import 'package:e_learning/core/constants/app_constants.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/core/widgets/custom_btn.dart';
import 'package:e_learning/core/widgets/custom_text_feild.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/view/instructor_dashboard.dart';
import 'package:e_learning/features/auth/data/repo/auth_repo.dart';
import 'package:e_learning/features/auth/presentaion/cubit/auth_cubit.dart';
import 'package:e_learning/features/auth/presentaion/cubit/auth_states.dart';
import 'package:e_learning/features/auth/presentaion/view/register_screen.dart';
import 'package:e_learning/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // ── inline error messages (من الـ server)
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ── تحليل رسالة الـ error من Supabase وتوزيعها على الحقول
  void _handleAuthError(String message) {
    final msg = message.toLowerCase();

    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    // ── Network & Timeout (جديد) ──────────────────────────────────
    if (msg.contains('no internet') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection refused') ||
        msg.contains('socketexception')) {
      _showSnack(
        'No internet connection. Check your network and try again.',
        icon: Icons.wifi_off_rounded,
        color: AppColors.error,
      );
      return;
    }

    if (msg.contains('timed out') || msg.contains('timeout')) {
      _showSnack(
        'Connection timed out. Please try again.',
        icon: Icons.hourglass_disabled_rounded,
        color: AppColors.warning,
      );
      return;
    }

    if (msg.contains('server error') || msg.contains('status code: 5')) {
      _showSnack(
        'Server error. Please try again later.',
        icon: Icons.cloud_off_rounded,
        color: AppColors.error,
      );
      return;
    }

    // ── Auth errors (موجودة عندك) ─────────────────────────────────
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials') ||
        msg.contains('wrong password') ||
        msg.contains('incorrect password')) {
      setState(() => _passwordError = 'Incorrect email or password');
    } else if (msg.contains('email not confirmed') ||
        msg.contains('not confirmed')) {
      setState(() => _emailError = 'Please verify your email first');
    } else if (msg.contains('user not found') ||
        msg.contains('no user') ||
        msg.contains('not registered')) {
      setState(() => _emailError = 'No account found with this email');
    } else if (msg.contains('too many requests') ||
        msg.contains('rate limit')) {
      _showSnack(
        'Too many attempts. Please wait a moment and try again.',
        icon: Icons.timer_outlined,
        color: AppColors.warning,
      );
    } else {
      _showSnack(
        'Something went wrong. Please try again.',
        icon: Icons.error_outline_rounded,
        color: AppColors.error,
      );
    }

    _formKey.currentState?.validate();
  }
  void _showSnack(
    String msg, {
    IconData icon = Icons.info_outline_rounded,
    Color? color,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
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

  void _login() {
    print("Login pressed");
    // clear server errors أول ما اليوزر يحاول تاني
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is LoginSuccess) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (!mounted) return;
    
                if (state.role == 'instructor' || state.role == 'admin') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          InstructorDashboard(userId: state.userId),
                    ),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MainShell(userId: state.userId),
                    ),
                  );
                }
              });
            }
    
            if (state is LoginFailure) {
              _handleAuthError(state.message);
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
                      Text(
                        'Welcome back 👋',
                        style: AppTextStyles.displayMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue your learning journey',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 36),
    
                      // ── Email field
                      AppTextField(
                        label: 'Email Address',
                        hint: 'you@example.com',
                        prefixIcon: Icons.email_outlined,
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) {
                          if (_emailError != null) {
                            setState(() => _emailError = null);
                          }
                        },
                        validator: (v) {
                          if (_emailError != null) return _emailError;
                          if (v == null || v.isEmpty)
                            return 'Enter your email';
                          if (!RegExp(
                            r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$',
                          ).hasMatch(v)) {
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
                        onChanged: (_) {
                          if (_passwordError != null) {
                            setState(() => _passwordError = null);
                          }
                        },
                        validator: (v) {
                          if (_passwordError != null) return _passwordError;
                          if (v == null || v.isEmpty)
                            return 'Enter your password';
                          if (v.length < 6) return 'Password is too short';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
    
                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => _showForgotPasswordDialog(context),
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
                      const SizedBox(height: 24),
    
                      // ── Sign In button
                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          if (state is LoginLoading) {
                            return Container(
                              height: 54,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                            );
                          }
                          return AppPrimaryButton(
                            label: 'Sign In',
                            onTap: _login,
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      const _OrDivider(),
                      const SizedBox(height: 32),
                      _SocialLoginButton(
                        icon: Icons.g_mobiledata_rounded,
                        label: 'Continue with Google',
                        onTap: () {},
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
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
        );
      },
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (ctrl.text.trim().isEmpty) return;
              try {
                await Supabase.instance.client.auth.resetPasswordForEmail(
                  ctrl.text.trim(),
                );
                if (context.mounted) {
                  _showSnack(
                    'Reset link sent! Check your email.',
                    icon: Icons.mark_email_read_outlined,
                    color: AppColors.success,
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  _showSnack('Could not send reset email. Try again.');
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
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Brand Header
// ─────────────────────────────────────────────
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
          child: const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 26,
          ),
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
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
