import 'dart:async' as dart_async;
import 'dart:io';

import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps any raw error → typed [AppException].
class NetworkExceptionHandler {
  NetworkExceptionHandler._();

  static AppException handle(Object error) {
    // ── No Internet ────────────────────────────────────────────────
    if (error is SocketException || _isNoInternetMessage(error)) {
      return const NoInternetException();
    }

    // ── Timeout ────────────────────────────────────────────────────
    if (error is dart_async.TimeoutException || _isTimeoutMessage(error)) {
      return const TimeoutException();
    }

    // ── Supabase PostgREST ─────────────────────────────────────────
    if (error is PostgrestException) {
      return _fromPostgrest(error);
    }

    // ── Supabase Auth ──────────────────────────────────────────────
    // نستخدم الـ runtimeType بدل is عشان نتجنب الـ naming conflict
    if (error.runtimeType.toString() == 'AuthException' ||
        error is AuthException) {
      final msg = (error as dynamic).message as String? ?? 'Auth error';
      return AppAuthException(msg);
    }

    // ── Supabase Storage ───────────────────────────────────────────
    if (error is StorageException) {
      return ServerException(message: error.message);
    }

    // ── Already typed ──────────────────────────────────────────────
    if (error is AppException) return error;

    // ── Fallback ───────────────────────────────────────────────────
    return UnknownException(error.toString());
  }

  static AppException _fromPostgrest(PostgrestException e) {
    final code = int.tryParse(e.code ?? '');
    if (code != null) {
      if (code >= 500) {
        return ServerException(message: e.message ?? 'Server error', statusCode: code);
      }
      if (code == 401 || code == 403) {
        return AppAuthException(e.message ?? 'Unauthorized');
      }
      if (code == 404) {
        return const ServerException(message: 'Resource not found', statusCode: 404);
      }
    }
    return ServerException(message: e.message ?? 'Database error');
  }

  static bool _isNoInternetMessage(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('no internet') ||
        msg.contains('network is unreachable') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection refused') ||
        msg.contains('network_changed');
  }

  static bool _isTimeoutMessage(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('timeout') || msg.contains('timed out');
  }
}