// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// auth_gate.dart
// Path: lib/features/auth/presentaion/view/auth_gate.dart
//
// ✅ لو في session محفوظة → روح للـ home/dashboard مباشرة
// ✅ لو مفيش → LoginScreen
// ✅ Supabase بيحفظ الـ session أوتوماتيك على الجهاز
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'package:e_learning/features/admin_panel/add_courses/presentation/view/instructor_dashboard.dart';
import 'package:e_learning/features/auth/data/repo/auth_repo.dart';
import 'package:e_learning/features/auth/presentaion/view/login_screen.dart';
import 'package:e_learning/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // انتظر ثانية صغيرة عشان Supabase يستعيد الـ session
    await Future.delayed(const Duration(milliseconds: 300));

    final user = Supabase.instance.client.auth.currentUser;

    if (!mounted) return;

    if (user == null) {
      // مفيش session → LoginScreen
      _goTo(const LoginScreen());
      return;
    }

    // في session → جيب الـ role وروح للشاشة المناسبة
    final role = await AuthRepo().fetchUserRole(user.id);

    if (!mounted) return;

    if (role == 'instructor' || role == 'admin') {
      _goTo(InstructorDashboard(userId: user.id));
    } else {
      _goTo(MainShell(userId: user.id));
    }
  }

  void _goTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Splash بسيط أثناء الـ check
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}