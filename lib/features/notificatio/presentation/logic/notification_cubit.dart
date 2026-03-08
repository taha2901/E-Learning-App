// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// notification_cubit.dart
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:e_learning/features/notificatio/data/model/notification_model.dart';
import 'package:e_learning/features/notificatio/data/repo/notification_repo.dart';
import 'package:e_learning/features/notificatio/presentation/logic/notification_states.dart';
import 'package:flutter/material.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepo _repo;
  final String userId;
  StreamSubscription? _streamSub;

  NotificationCubit(this._repo, {required this.userId})
      : super(NotificationInitial());

  // ── Load & subscribe real-time ────────────────────────────────────────────
 void load() {
  emit(NotificationLoading());
  _streamSub?.cancel();

  _streamSub = _repo.notificationsStream(userId).listen(
    (rawList) {
      debugPrint('📬 notifications received: ${rawList.length}'); // ← ضيف ده
      final notifications =
          rawList.map((e) => NotificationModel.fromJson(e)).toList();
      final unread = notifications.where((n) => !n.isRead).length;
      emit(NotificationLoaded(
        notifications: notifications,
        unreadCount: unread,
      ));
    },
    onError: (e) {
      debugPrint('❌ stream error: $e'); // ← وده
      _fallbackFetch();
    },
  );
}
  // ── Fallback لو الـ stream فشل ────────────────────────────────────────────
  Future<void> _fallbackFetch() async {
    final notifications = await _repo.fetchNotifications(userId);
    final unread = notifications.where((n) => !n.isRead).length;
    emit(NotificationLoaded(notifications: notifications, unreadCount: unread));
  }

  // ── Mark one as read ──────────────────────────────────────────────────────
  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
    if (state is NotificationLoaded) {
      final s = state as NotificationLoaded;
      final updated = s.notifications
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList();
      final unread = updated.where((n) => !n.isRead).length;
      emit(s.copyWith(notifications: updated, unreadCount: unread));
    }
  }

  // ── Mark all as read ──────────────────────────────────────────────────────
  Future<void> markAllAsRead() async {
    await _repo.markAllAsRead(userId);
    if (state is NotificationLoaded) {
      final s = state as NotificationLoaded;
      final updated = s.notifications.map((n) => n.copyWith(isRead: true)).toList();
      emit(s.copyWith(notifications: updated, unreadCount: 0));
    }
  }

  // ── Delete one ────────────────────────────────────────────────────────────
  Future<void> deleteNotification(String id) async {
    await _repo.deleteNotification(id);
    if (state is NotificationLoaded) {
      final s = state as NotificationLoaded;
      final updated = s.notifications.where((n) => n.id != id).toList();
      final unread = updated.where((n) => !n.isRead).length;
      emit(s.copyWith(notifications: updated, unreadCount: unread));
    }
  }

  // ── Clear all ─────────────────────────────────────────────────────────────
  Future<void> clearAll() async {
    await _repo.clearAll(userId);
    emit(NotificationLoaded(notifications: [], unreadCount: 0));
  }

  // ── Helper: create from anywhere (e.g. after quiz) ────────────────────────
  Future<void> pushNotification({
    required String title,
    required String body,
    NotificationType type = NotificationType.general,
    Map<String, dynamic> metadata = const {},
  }) async {
    await _repo.createNotification(
      userId: userId,
      title: title,
      body: body,
      type: type,
      metadata: metadata,
    );
  }

  @override
  Future<void> close() {
    _streamSub?.cancel();
    return super.close();
  }
}