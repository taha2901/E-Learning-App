import 'package:e_learning/core/networking/supabase_services.dart';
import 'package:e_learning/features/auth/presentaion/view/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:e_learning/features/auth/data/repo/auth_repo.dart';
import 'package:e_learning/features/auth/presentaion/cubit/auth_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseServices.init();

 runApp(
  MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => AuthCubit(AuthRepo()),
      ),
    ],
    child: const ELearningApp(),
  ),
);
}

class ELearningApp extends StatelessWidget {
  const ELearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LearnFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
