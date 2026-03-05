import 'dart:io';
import 'package:e_learning/features/profile/presentation/cubit/profile_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileCubit extends Cubit<ProfileStates> {
  ProfileCubit() : super(ProfileInitial());
  final SupabaseClient _db = Supabase.instance.client;

  Future<void> fetchUser(String userId) async {
    emit(ProfileLoading());
    try {
      final profile = await _db
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      final authUser = _db.auth.currentUser;

      final enrollments = await _db
          .from('enrollments')
          .select('course_id')
          .eq('user_id', userId) as List;

      int completedCount = 0;
      if (enrollments.isNotEmpty) {
        final ids = enrollments.map((e) => e['course_id'] as String).toList();
        final videos = await _db.from('videos').select('id, course_id').inFilter('course_id', ids) as List;
        final watched = await _db.from('video_progress').select('video_id').eq('user_id', userId).eq('watched', true) as List;
        final watchedSet = watched.map((e) => e['video_id'] as String).toSet();
        final Map<String, List<String>> map = {};
        for (final v in videos) {
          map.putIfAbsent(v['course_id'] as String, () => []).add(v['id'] as String);
        }
        for (final e in map.entries) {
          if (e.value.isNotEmpty && e.value.where((id) => watchedSet.contains(id)).length >= e.value.length) {
            completedCount++;
          }
        }
      }

      emit(ProfileLoaded({
        'id': userId,
        'email': authUser?.email ?? '',
        'name': profile?['name'] ?? '',
        'phone': profile?['phone'] ?? '',
        'avatar_url': profile?['avatar_url'] ?? '',
        'bio': profile?['bio'] ?? '',
        'enrolled_courses_count': enrollments.length,
        'completed_courses_count': completedCount,
        'certificates_count': completedCount,
      }));
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  // ── Update Name + Bio + Phone ─────────────────────────────────────────────
  Future<void> updateProfile({
    required String userId,
    required String name,
    required String bio,
    String? phone,
  }) async {
    try {
      // ✅ جرب update الأول، لو مفيش row اعمل insert
      final existing = await _db.from('profiles').select('id').eq('user_id', userId).maybeSingle();
      if (existing != null) {
        await _db.from('profiles').update({
          'name': name,
          'bio': bio,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        }).eq('user_id', userId);
      } else {
        await _db.from('profiles').insert({
          'user_id': userId,
          'name': name,
          'bio': bio,
          'phone': phone ?? '',
          'avatar_url': '',
        });
      }
      await fetchUser(userId);
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  // ── Update Avatar ─────────────────────────────────────────────────────────
  Future<void> updateAvatar({required String userId, required File image}) async {
    try {
      final ext = image.path.split('.').last;
      final fileName = 'avatar_$userId.$ext';
      await Supabase.instance.client.storage.from('avatars').upload(
            fileName, image,
            fileOptions: const FileOptions(upsert: true),
          );
      final url = Supabase.instance.client.storage.from('avatars').getPublicUrl(fileName);
      final urlWithBust = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      final existing = await _db.from('profiles').select('id').eq('user_id', userId).maybeSingle();
      if (existing != null) {
        await _db.from('profiles').update({'avatar_url': urlWithBust}).eq('user_id', userId);
      } else {
        await _db.from('profiles').insert({'user_id': userId, 'avatar_url': urlWithBust, 'name': '', 'phone': '', 'bio': ''});
      }
      await fetchUser(userId);
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }
}