import 'dart:io';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/features/auth/presentaion/cubit/auth_cubit.dart';
import 'package:e_learning/features/auth/presentaion/cubit/auth_states.dart';
import 'package:e_learning/features/auth/presentaion/view/widget/register/register_avatar_header.dart';
import 'package:e_learning/features/auth/presentaion/view/widget/register/register_back_button.dart';
import 'package:e_learning/features/auth/presentaion/view/widget/register/register_form_card.dart';
import 'package:e_learning/features/auth/presentaion/view/widget/register/register_gradient_background.dart';
import 'package:e_learning/features/auth/presentaion/view/widget/register/register_image_picker_sheet.dart';
import 'package:e_learning/features/auth/presentaion/view/widget/register/register_sign_in_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  File? _selectedImage;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _acceptedTerms = false;

  String? _emailError;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasMinLength = false;

  bool get _passwordStrong =>
      _hasUppercase && _hasLowercase && _hasDigit && _hasMinLength;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    _passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    final v = _passwordController.text;
    setState(() {
      _hasUppercase = v.contains(RegExp(r'[A-Z]'));
      _hasLowercase = v.contains(RegExp(r'[a-z]'));
      _hasDigit = v.contains(RegExp(r'[0-9]'));
      _hasMinLength = v.length >= 8;
    });
  }

  void _onRegister() {
    if (!_acceptedTerms) {
      _showSnack(
        'Please accept the Terms & Conditions to continue',
        icon: Icons.info_outline_rounded,
        color: AppColors.warning,
      );
      return;
    }
    if (!_passwordStrong) {
      _showSnack(
        "Your password doesn't meet the requirements",
        icon: Icons.lock_outline_rounded,
      );
      return;
    }
    setState(() => _emailError = null);
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().register(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            avatar: _selectedImage,
          );
    }
  }

  void _onRegisterSuccess() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account created successfully! 🎉',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Sign in with ${_emailController.text.trim()}',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _handleRegisterError(String message) {
    final msg = message.toLowerCase();
    setState(() => _emailError = null);

    // Network & Timeout
    if (msg.contains('no internet') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection refused') ||
        msg.contains('socketexception')) {
      _showSnack('No internet connection. Check your network.',
          icon: Icons.wifi_off_rounded);
      return;
    }
    if (msg.contains('timed out') || msg.contains('timeout')) {
      _showSnack('Connection timed out. Please try again.',
          icon: Icons.hourglass_disabled_rounded, color: AppColors.warning);
      return;
    }
    if (msg.contains('server error') || msg.contains('status code: 5')) {
      _showSnack('Server error. Please try again later.',
          icon: Icons.cloud_off_rounded);
      return;
    }

    // Auth errors
    if (msg.contains('already registered') ||
        msg.contains('already exists') ||
        msg.contains('email address is already') ||
        msg.contains('user already registered')) {
      setState(() => _emailError = 'This email is already registered');
      _formKey.currentState?.validate();
    } else if (msg.contains('invalid email') ||
        msg.contains('email is invalid')) {
      setState(() => _emailError = 'Enter a valid email address');
      _formKey.currentState?.validate();
    } else if (msg.contains('password') && msg.contains('weak')) {
      _showSnack('Choose a stronger password',
          icon: Icons.lock_outline_rounded);
    } else if (msg.contains('too many requests') ||
        msg.contains('rate limit')) {
      _showSnack('Too many attempts. Please wait and try again.',
          icon: Icons.timer_outlined, color: AppColors.warning);
    } else {
      _showSnack('Something went wrong. Please try again.');
    }
  }

  void _showSnack(String msg,
      {IconData icon = Icons.error_outline_rounded, Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
                child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: color ?? AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is SignUpSuccess) _onRegisterSuccess();
        if (state is SignUpFailure) _handleRegisterError(state.message);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            const RegisterGradientBackground(),
            const RegisterBackButton(),
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    RegisterAvatarHeader(
                      selectedImage: _selectedImage,
                      fadeAnim: _fadeAnim,
                      slideAnim: _slideAnim,
                      onTap: () => RegisterImagePickerSheet.show(
                        context,
                        onImageSelected: (file) =>
                            setState(() => _selectedImage = file),
                      ),
                    ),
                    const SizedBox(height: 32),

                    RegisterFormCard(
                      formKey: _formKey,
                      nameController: _nameController,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      phoneController: _phoneController,
                      emailError: _emailError,
                      onEmailErrorClear: () {
                        if (_emailError != null) {
                          setState(() => _emailError = null);
                        }
                      },
                      acceptedTerms: _acceptedTerms,
                      onTermsToggle: () =>
                          setState(() => _acceptedTerms = !_acceptedTerms),
                      hasUppercase: _hasUppercase,
                      hasLowercase: _hasLowercase,
                      hasDigit: _hasDigit,
                      hasMinLength: _hasMinLength,
                      onRegister: _onRegister,
                      fadeAnim: _fadeAnim,
                      slideAnim: _slideAnim,
                    ),

                    const SizedBox(height: 24),
                    const RegisterSignInFooter(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}