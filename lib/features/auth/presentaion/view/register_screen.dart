import 'package:e_learning/core/theme/app_colors.dart';
import 'package:e_learning/core/theme/text_styles.dart';
import 'package:e_learning/core/widgets/custom_btn.dart';
import 'package:e_learning/core/widgets/custom_text_feild.dart';
import 'package:e_learning/features/auth/data/repo/auth_repo.dart';
import 'package:e_learning/features/auth/presentaion/cubit/auth_cubit.dart';
import 'package:e_learning/features/auth/presentaion/cubit/auth_states.dart';
import 'package:e_learning/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_learning/core/constants/app_constants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool acceptedTerms = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void register() {
    if (!acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Accept terms first")),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().register(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
    
        if (state is SignUpSuccess) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainShell()),
            (_) => false,
          );
        }
    
        if (state is SignUpFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
    
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
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
    
                  const SizedBox(height: 8),
    
                  Text('Create Account ✨', style: AppTextStyles.displayMedium),
                  const SizedBox(height: 8),
    
                  Text(
                    'Start your learning journey today',
                    style: AppTextStyles.bodyMedium,
                  ),
    
                  const SizedBox(height: 36),
    
                  /// NAME
                  AppTextField(
                    label: 'Full Name',
                    hint: 'Ahmed Mohamed',
                    prefixIcon: Icons.person_outline_rounded,
                    controller: nameController,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Enter name";
                      }
                      return null;
                    },
                  ),
    
                  const SizedBox(height: 20),
    
                  /// EMAIL
                  AppTextField(
                    label: 'Email Address',
                    hint: 'you@example.com',
                    prefixIcon: Icons.email_outlined,
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Enter email";
                      }
                      if (!v.contains("@")) {
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
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Enter password";
                      }
                      if (v.length < 6) {
                        return "Password too short";
                      }
                      return null;
                    },
                  ),
    
                  const SizedBox(height: 20),
    
                  /// CONFIRM PASSWORD
                  AppTextField(
                    label: 'Confirm Password',
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline_rounded,
                    isPassword: true,
                    controller: confirmPasswordController,
                    validator: (v) {
                      if (v != passwordController.text) {
                        return "Passwords don't match";
                      }
                      return null;
                    },
                  ),
    
                  const SizedBox(height: 16),
    
                  /// TERMS
                  Row(
                    children: [
                      Checkbox(
                        value: acceptedTerms,
                        onChanged: (v) {
                          setState(() {
                            acceptedTerms = v!;
                          });
                        },
                      ),
                      const Text("Accept terms")
                    ],
                  ),
    
                  const SizedBox(height: 28),
    
                  /// BUTTON
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
    
                      if (state is SignUpLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
    
                      return AppPrimaryButton(
                        label: 'Create Account',
                        onTap: register,
                      );
                    },
                  ),
    
                  const SizedBox(height: 32),
    
                  Center(
                    child: GestureDetector(
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
  }
}