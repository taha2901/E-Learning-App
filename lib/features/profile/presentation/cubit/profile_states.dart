class ProfileStates {}

class ProfileInitial extends ProfileStates {}
class ProfileLoading extends ProfileStates {}
class ProfileLoaded extends ProfileStates {
  final Map<String, dynamic> userData;
  ProfileLoaded(this.userData);
}
class ProfileError extends ProfileStates {
  final String message;
  ProfileError(this.message);
}

