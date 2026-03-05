import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepo {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<Either<String, void>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await supabase.auth.signInWithPassword(email: email, password: password);
      return right(null);
    } on AuthException catch (e) {
      return left(e.message);
    } catch (e) {
      return left("Something went wrong");
    }
  }

  Future<Either<String, void>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await supabase.auth.signUp(email: email, password: password);
      return right(null);
    } on AuthException catch (e) {
      return left(e.message);
    } catch (e) {
      return left("Something went wrong");
    }
  }

  Future<void> logout() async => await supabase.auth.signOut();
  User? getCurrentUser() => supabase.auth.currentUser;

  // ── Upload Avatar ─────────────────────────────────────────────────────────
  Future<String?> uploadAvatar(String userId, File file) async {
    try {
      final ext = file.path.split('.').last;
      final fileName = 'avatar_$userId.$ext';
      await supabase.storage.from('avatars').upload(
            fileName, file,
            fileOptions: const FileOptions(upsert: true),
          );
      final url = supabase.storage.from('avatars').getPublicUrl(fileName);
      return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      print('Avatar upload error: $e');
      return null;
    }
  }

  // ── Create Profile ────────────────────────────────────────────────────────
  Future<void> createProfile({
    required String userId,
    required String name,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      // ✅ insert مع onConflict صريح
      await supabase.from('profiles').insert({
        'user_id': userId,
        'name': name,
        'phone': phone ?? '',
        'avatar_url': avatarUrl ?? '',
        'bio': '',
      });
    } catch (_) {
      // لو user عنده profile خد، اعمل update بس
      await supabase.from('profiles').update({
        'name': name,
        'phone': phone ?? '',
        if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
      }).eq('user_id', userId);
    }
  }
}