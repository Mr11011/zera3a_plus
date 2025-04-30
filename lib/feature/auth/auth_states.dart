import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthStates {}

class AuthInitState extends AuthStates {}

class AuthLoadingState extends AuthStates {}

class AuthLoadedState extends AuthStates {
  final User user;

  AuthLoadedState({required this.user});
}

class AuthEmailVerificationSent extends AuthStates {
  final User user;

  AuthEmailVerificationSent(this.user);
}

class AuthPendingOwnerState extends AuthStates {
  final User user;

  AuthPendingOwnerState(this.user);
}

class AuthError extends AuthStates {
  final String error;

  AuthError(this.error);
}

class ResetPasswordLoading extends AuthStates {}

class ResetPasswordError extends AuthStates {
  final String error;

  ResetPasswordError(this.error);
}

class ResetPasswordSuccess extends AuthStates {
  final String message;

  ResetPasswordSuccess(this.message);
}
