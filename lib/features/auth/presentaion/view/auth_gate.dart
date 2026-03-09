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
    await Future.delayed(const Duration(milliseconds: 300));
    final user = Supabase.instance.client.auth.currentUser;

    if (!mounted) return;

    if (user == null) {
      _goTo(const LoginScreen());
      return;
    }

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
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}