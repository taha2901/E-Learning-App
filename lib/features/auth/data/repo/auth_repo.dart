import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepo {
  final SupabaseClient supabase = Supabase.instance.client;

  static const _timeout = Duration(seconds: 15);

  // ── Sign In ────────────────────────────────────────────────────────────────
  Future<Either<String, User>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth
          .signInWithPassword(email: email, password: password)
          .timeout(_timeout);

      if (response.user == null) return left('Login failed');
      return right(response.user!);
    } on AuthException catch (e) {
      // Supabase auth errors (wrong password, not confirmed…) — keep as string
      // so existing _handleAuthError() in login_screen still works
      return left(e.message);
    } catch (e) {
      // Network / timeout / unknown → convert to AppException message
      final ex = NetworkExceptionHandler.handle(e);
      return left(ex.message);
    }
  }

  // ── Sign Up ────────────────────────────────────────────────────────────────
  Future<Either<String, void>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await supabase.auth
          .signUp(email: email, password: password)
          .timeout(_timeout);
      return right(null);
    } on AuthException catch (e) {
      return left(e.message);
    } catch (e) {
      final ex = NetworkExceptionHandler.handle(e);
      return left(ex.message);
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> logout() async => supabase.auth.signOut();

  // ── Current User ───────────────────────────────────────────────────────────
  User? getCurrentUser() => supabase.auth.currentUser;

  // ── Fetch Role ─────────────────────────────────────────────────────────────
  Future<String> fetchUserRole(String userId) async {
    try {
      final res = await supabase
          .from('profiles')
          .select('role')
          .eq('user_id', userId)
          .maybeSingle()
          .timeout(_timeout);

      if (res == null) return 'student';
      return (res)['role'] as String? ?? 'student';
    } catch (_) {
      return 'student'; // graceful fallback — role fetch failure never blocks login
    }
  }

  // ── Upload Avatar ──────────────────────────────────────────────────────────
  Future<String?> uploadAvatar(String userId, File file) async {
    try {
      final ext = file.path.split('.').last;
      final fileName = 'avatar_$userId.$ext';
      await supabase.storage
          .from('avatars')
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));
      final url = supabase.storage.from('avatars').getPublicUrl(fileName);
      return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (_) {
      return null;
    }
  }

  // ── Create Profile ─────────────────────────────────────────────────────────
  Future<void> createProfile({
    required String userId,
    required String name,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      await supabase.from('profiles').insert({
        'user_id': userId,
        'name': name,
        'phone': phone ?? '',
        'avatar_url': avatarUrl ?? '',
        'bio': '',
        'role': 'student',
      }).timeout(_timeout);
    } catch (_) {
      await supabase
          .from('profiles')
          .update({
            'name': name,
            'phone': phone ?? '',
            if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
          })
          .eq('user_id', userId)
          .timeout(_timeout);
    }
  }
}