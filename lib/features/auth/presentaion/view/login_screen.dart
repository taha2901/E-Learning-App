import 'package:e_learning/core/constants/app_constants.dart';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/features/admin_panel/add_courses/presentation/view/instructor_dashboard.dart';
import 'package:e_learning/features/auth/presentaion/cubit/auth_cubit.dart';
import 'package:e_learning/features/auth/presentaion/cubit/auth_states.dart';
import 'package:e_learning/features/auth/presentaion/view/widget/login/login_brand_header.dart';
import 'package:e_learning/features/auth/presentaion/view/widget/login/login_form_section.dart';
import 'package:e_learning/features/auth/presentaion/view/widget/login/login_or_divider.dart';
import 'package:e_learning/features/auth/presentaion/view/widget/login/login_sign_up_footer.dart';
import 'package:e_learning/features/auth/presentaion/view/widget/login/login_social_button.dart';
import 'package:e_learning/features/auth/presentaion/view/widget/login/login_submit_button.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── تحليل رسالة الـ error من Supabase وتوزيعها على الحقول
  void _handleAuthError(String message) {
    final msg = message.toLowerCase();

    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    // ── Network & Timeout ─────────────────────────────────────────
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

    // ── Auth errors ───────────────────────────────────────────────
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

  void _showSnack(String msg, {IconData icon = Icons.info_outline_rounded, Color? color}) {
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

  void _onLogin() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    }
  }

  void _onLoginSuccess(LoginSuccess state) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      if (state.role == 'instructor' || state.role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => InstructorDashboard(userId: state.userId),
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is LoginSuccess) _onLoginSuccess(state);
        if (state is LoginFailure) _handleAuthError(state.message);
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
                  const LoginBrandHeader(),
                  const SizedBox(height: 40),
                  Text('Welcome back 👋', style: AppTextStyles.displayMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue your learning journey',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 36),

                  LoginFormSection(
                    emailController: _emailController,
                    passwordController: _passwordController,
                    emailError: _emailError,
                    passwordError: _passwordError,
                    onEmailErrorClear: () {
                      if (_emailError != null) setState(() => _emailError = null);
                    },
                    onPasswordErrorClear: () {
                      if (_passwordError != null) setState(() => _passwordError = null);
                    },
                  ),
                  const SizedBox(height: 24),

                  LoginSubmitButton(onTap: _onLogin),
                  const SizedBox(height: 32),

                  const LoginOrDivider(),
                  const SizedBox(height: 32),

                  LoginSocialButton(
                    icon: Icons.g_mobiledata_rounded,
                    label: 'Continue with Google',
                    onTap: () {},
                  ),
                  const SizedBox(height: 40),

                  const LoginSignUpFooter(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}