import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repo/auth_repo.dart';
import 'auth_states.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo repo;

  AuthCubit(this.repo) : super(AuthInitial());

  /// LOGIN
  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(LoginLoading());

    final result = await repo.signIn(
      email: email,
      password: password,
    );

    result.fold(
      (error) => emit(LoginFailure(error)),
      (_) => emit(LoginSuccess()),
    );
  }

  /// REGISTER
  Future<void> register({
    required String email,
    required String password,
  }) async {
    emit(SignUpLoading());

    final result = await repo.signUp(
      email: email,
      password: password,
    );

    result.fold(
      (error) => emit(SignUpFailure(error)),
      (_) => emit(SignUpSuccess()),
    );
  }

  /// LOGOUT
  Future<void> logout() async {
    await repo.logout();
    emit(AuthInitial());
  }
}