abstract class AuthState {}

class AuthInitial extends AuthState {}

/// Login
class LoginLoading extends AuthState {}
class LoginSuccess extends AuthState {}
class LoginFailure extends AuthState {
  final String message;
  LoginFailure(this.message);
}

/// Register
class SignUpLoading extends AuthState {}
class SignUpSuccess extends AuthState {}
class SignUpFailure extends AuthState {
  final String message;
  SignUpFailure(this.message);
}