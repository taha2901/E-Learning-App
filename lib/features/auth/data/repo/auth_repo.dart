import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepo {
  final SupabaseClient supabase = Supabase.instance.client;

  /// LOGIN
  Future<Either<String, void>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return right(null);
    } on AuthException catch (e) {
      return left(e.message);
    } catch (e) {
      return left("Something went wrong");
    }
  }

  /// REGISTER
  Future<Either<String, void>> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await supabase.auth.signUp(
        email: email,
        password: password,
      );

      return right(null);
    } on AuthException catch (e) {
      return left(e.message);
    } catch (e) {
      return left("Something went wrong");
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    await supabase.auth.signOut();
  }

  /// CURRENT USER
  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }
}