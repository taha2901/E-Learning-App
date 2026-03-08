// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// notification_repo.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'package:e_learning/features/notificatio/data/model/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepo {
  final SupabaseClient _db = Supabase.instance.client;

  // ── جيب كل نوتيفيكيشنز اليوزر ───────────────────────────────────────────
  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    try {
      final res =
          await _db
                  .from('notifications')
                  .select()
                  .eq('user_id', userId)
                  .order('created_at', ascending: false)
                  .limit(50)
              as List;

      return res
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── عدد اللي لسه متقراش ──────────────────────────────────────────────────
  Future<int> fetchUnreadCount(String userId) async {
    try {
      final res =
          await _db
                  .from('notifications')
                  .select('id')
                  .eq('user_id', userId)
                  .eq('is_read', false)
              as List;
      return res.length;
    } catch (_) {
      return 0;
    }
  }

  // ── اعمل نوتيفيكيشن جديد ────────────────────────────────────────────────
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    NotificationType type = NotificationType.general,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      await _db.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'metadata': metadata,
      });
    } catch (_) {}
  }

  // ── اعمل نوتيفيكيشن ﻗﺮﺃﻫﺎ ─────────────────────────────────────────────
  Future<void> markAsRead(String notificationId) async {
    try {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (_) {}
  }

  // ── اعمل كل النوتيفيكيشنز متقرأه ────────────────────────────────────────
  Future<void> markAllAsRead(String userId) async {
    try {
      await _db
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (_) {}
  }

  // ── امسح نوتيفيكيشن ─────────────────────────────────────────────────────
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _db.from('notifications').delete().eq('id', notificationId);
    } catch (_) {}
  }

  // ── امسح كل النوتيفيكيشنز ───────────────────────────────────────────────
  Future<void> clearAll(String userId) async {
    try {
      await _db.from('notifications').delete().eq('user_id', userId);
    } catch (_) {}
  }

  // ── Real-time stream ─────────────────────────────────────────────────────
  // ✅ الطريقة الصح
  Stream<List<Map<String, dynamic>>> notificationsStream(String userId) {
    return _db
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }
}
