import 'dart:io';
import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/core/widgets/custom_btn.dart';
import 'package:e_learning/core/widgets/custom_text_feild.dart';
import 'package:e_learning/features/auth/presentaion/cubit/auth_cubit.dart';
import 'package:e_learning/features/auth/presentaion/cubit/auth_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_learning/core/constants/app_constants.dart';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  File? selectedImage;
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final phoneController = TextEditingController();
  bool acceptedTerms = false;

  // server-side errors
  String? _emailError;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // password strength
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasMinLength = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
            CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    final v = passwordController.text;
    setState(() {
      _hasUppercase = v.contains(RegExp(r'[A-Z]'));
      _hasLowercase = v.contains(RegExp(r'[a-z]'));
      _hasDigit = v.contains(RegExp(r'[0-9]'));
      _hasMinLength = v.length >= 8;
    });
  }

  bool get _passwordStrong =>
      _hasUppercase && _hasLowercase && _hasDigit && _hasMinLength;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) setState(() => selectedImage = File(picked.path));
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(100)),
              ),
              const SizedBox(height: 20),
              Text('Choose Photo', style: AppTextStyles.h2),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: _ImageSourceTile(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ImageSourceTile(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRegisterError(String message) {
    final msg = message.toLowerCase();

    setState(() => _emailError = null);

    // ── Network & Timeout (جديد) ──────────────────────────────────
    if (msg.contains('no internet') ||
        msg.contains('failed host lookup') ||
        msg.contains('network is unreachable') ||
        msg.contains('connection refused') ||
        msg.contains('socketexception')) {
      _showSnack(
        'No internet connection. Check your network.',
        icon: Icons.wifi_off_rounded,
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
      );
      return;
    }

    // ── Auth errors (موجودة عندك) ─────────────────────────────────
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
      _showSnack('Choose a stronger password', icon: Icons.lock_outline_rounded);
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
        content: Row(children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
        ]),
        backgroundColor: color ?? AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _register() {
    if (!acceptedTerms) {
      _showSnack('Please accept the Terms & Conditions to continue',
          icon: Icons.info_outline_rounded, color: AppColors.warning);
      return;
    }
    if (!_passwordStrong) {
      _showSnack('Your password doesn\'t meet the requirements',
          icon: Icons.lock_outline_rounded);
      return;
    }
    setState(() => _emailError = null);
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().register(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
            name: nameController.text.trim(),
            phone: phoneController.text.trim(),
            avatar: selectedImage,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is SignUpSuccess) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(children: [
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
                            fontSize: 14),
                      ),
                      Text(
                        'Sign in with ${emailController.text.trim()}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ]),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
        if (state is SignUpFailure) {
          _handleRegisterError(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Top gradient
            Positioned(
              top: 0, left: 0, right: 0, height: 280,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Stack(children: [
                  Positioned(
                    top: -30, right: -30,
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.07)),
                    ),
                  ),
                  Positioned(
                    bottom: 20, left: -20,
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05)),
                    ),
                  ),
                ]),
              ),
            ),

            // Back button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Avatar
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(children: [
                          GestureDetector(
                            onTap: _showImagePicker,
                            child: Stack(alignment: Alignment.center, children: [
                              Container(
                                width: 110, height: 110,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withOpacity(0.5),
                                        width: 3)),
                              ),
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                backgroundImage: selectedImage != null
                                    ? FileImage(selectedImage!)
                                    : null,
                                child: selectedImage == null
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.add_a_photo_rounded,
                                              color: Colors.white, size: 28),
                                          const SizedBox(height: 4),
                                          Text('Add Photo',
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                      color: Colors.white70,
                                                      fontSize: 10)),
                                        ],
                                      )
                                    : null,
                              ),
                              if (selectedImage != null)
                                Positioned(
                                  bottom: 4, right: 4,
                                  child: Container(
                                    width: 28, height: 28,
                                    decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle),
                                    child: Icon(Icons.edit_rounded,
                                        size: 15, color: AppColors.primary),
                                  ),
                                ),
                            ]),
                          ),
                          const SizedBox(height: 12),
                          Text('Create Account ✨',
                              style:
                                  AppTextStyles.h1.copyWith(color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('Start your learning journey today',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: Colors.white70)),
                        ]),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Form card
                    FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
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
                                  offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
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
                                    if (v == null || v.trim().isEmpty)
                                      return 'Enter your full name';
                                    if (v.trim().length < 3)
                                      return 'Name is too short';
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
                                    if (v == null || v.isEmpty)
                                      return 'Enter your phone number';
                                    if (!RegExp(r'^[0-9+\-\s]{7,15}$')
                                        .hasMatch(v)) {
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
                                            r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$')
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
                                    if (v == null || v.isEmpty)
                                      return 'Enter a password';
                                    if (!_passwordStrong)
                                      return 'Password doesn\'t meet requirements';
                                    return null;
                                  },
                                ),

                                // ── Password strength indicator
                                if (passwordController.text.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  _PasswordStrengthBar(
                                    hasUppercase: _hasUppercase,
                                    hasLowercase: _hasLowercase,
                                    hasDigit: _hasDigit,
                                    hasMinLength: _hasMinLength,
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
                                    if (v == null || v.isEmpty)
                                      return 'Confirm your password';
                                    if (v != passwordController.text)
                                      return "Passwords don't match";
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Terms
                                GestureDetector(
                                  onTap: () => setState(
                                      () => acceptedTerms = !acceptedTerms),
                                  child: Row(children: [
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      width: 22, height: 22,
                                      decoration: BoxDecoration(
                                        color: acceptedTerms
                                            ? AppColors.primary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: acceptedTerms
                                              ? AppColors.primary
                                              : AppColors.cardBorder,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: acceptedTerms
                                          ? const Icon(Icons.check_rounded,
                                              color: Colors.white, size: 15)
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: AppTextStyles.bodySmall,
                                          children: [
                                            const TextSpan(
                                                text: 'I agree to the '),
                                            TextSpan(
                                              text: 'Terms & Conditions',
                                              style:
                                                  AppTextStyles.bodySmall.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ]),
                                ),
                                const SizedBox(height: 24),

                                // Register button
                                BlocBuilder<AuthCubit, AuthState>(
                                  builder: (context, state) {
                                    if (state is SignUpLoading) {
                                      return Container(
                                        height: 54,
                                        decoration: BoxDecoration(
                                          gradient: AppColors.primaryGradient,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5),
                                        ),
                                      );
                                    }
                                    return AppPrimaryButton(
                                      label: 'Create Account',
                                      onTap: _register,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: TextSpan(
                          text: 'Already have an account? ',
                          style: AppTextStyles.bodyMedium,
                          children: [
                            TextSpan(
                              text: 'Sign In',
                              style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
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

// ─────────────────────────────────────────────
// Password Strength Bar
// ─────────────────────────────────────────────
class _PasswordStrengthBar extends StatelessWidget {
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasMinLength;

  const _PasswordStrengthBar({
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasMinLength,
  });

  int get _score =>
      (hasUppercase ? 1 : 0) +
      (hasLowercase ? 1 : 0) +
      (hasDigit ? 1 : 0) +
      (hasMinLength ? 1 : 0);

  Color get _barColor {
    if (_score <= 1) return AppColors.error;
    if (_score == 2) return AppColors.warning;
    if (_score == 3) return const Color(0xFF3B82F6);
    return AppColors.success;
  }

  String get _label {
    if (_score <= 1) return 'Weak';
    if (_score == 2) return 'Fair';
    if (_score == 3) return 'Good';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // strength bar
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(
                value: _score / 4,
                minHeight: 4,
                backgroundColor: AppColors.cardBorder,
                valueColor: AlwaysStoppedAnimation(_barColor),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(_label,
              style: AppTextStyles.caption
                  .copyWith(color: _barColor, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 8),

        // requirements checklist
        Wrap(spacing: 12, runSpacing: 6, children: [
          _Req(label: '8+ chars', met: hasMinLength),
          _Req(label: 'Uppercase', met: hasUppercase),
          _Req(label: 'Lowercase', met: hasLowercase),
          _Req(label: 'Number', met: hasDigit),
        ]),
      ],
    );
  }
}

class _Req extends StatelessWidget {
  final String label;
  final bool met;
  const _Req({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(
        met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
        size: 13,
        color: met ? AppColors.success : AppColors.textHint,
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: met ? AppColors.success : AppColors.textHint,
          fontWeight: met ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────
// Image Source Tile
// ─────────────────────────────────────────────
class _ImageSourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ImageSourceTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        ),
        child: Column(children: [
          Icon(icon, color: AppColors.primary, size: 32),
          const SizedBox(height: 8),
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}