// auth_states.dart — ✅ أضفنا role للـ LoginSuccess و SignUpSuccess

abstract class AuthState {}

class AuthInitial extends AuthState {}

class LoginLoading extends AuthState {}

// ✅ role: 'student' | 'instructor' | 'admin'
class LoginSuccess extends AuthState {
  final String userId;
  final String role;
  LoginSuccess(this.userId, {this.role = 'student'});
}

class LoginFailure extends AuthState {
  final String message;
  LoginFailure(this.message);
}

class SignUpLoading extends AuthState {}

class SignUpSuccess extends AuthState {
  final String userId;
  SignUpSuccess(this.userId);
}

class SignUpFailure extends AuthState {
  final String message;
  SignUpFailure(this.message);
}