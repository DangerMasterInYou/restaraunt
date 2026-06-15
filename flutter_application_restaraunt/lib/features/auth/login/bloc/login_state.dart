part of 'login_bloc.dart';

abstract class LoginState extends Equatable {}

class LoginInitial extends LoginState {
  @override
  List<Object?> get props => [];
}

class LoginLoading extends LoginState {
  @override
  List<Object?> get props => [];
}

class VerificationCodeSentSuccess extends LoginState {
  final String email;
  VerificationCodeSentSuccess({required this.email});
  @override
  List<Object?> get props => [email];
}

class VerificationCodeSentFailure extends LoginState {
  VerificationCodeSentFailure({
    this.exception,
  });

  final Object? exception;

  @override
  List<Object?> get props => [exception];
}

class LoginSuccess extends LoginState {
  LoginSuccess({
    required this.token,
    this.role,
  });

  final Token token;

  final String? role;

  @override
  List<Object?> get props => [token, role];
}

class LoginFailure extends LoginState {
  final String email;
  final Object? exception;
  final int attemptsLeft;
  LoginFailure({
    required this.email,
    this.exception,
    this.attemptsLeft = 5,
  });

  @override
  List<Object?> get props => [email, exception, attemptsLeft];
}

class LoginBlocked extends LoginState {
  final DateTime blockUntil;
  LoginBlocked({required this.blockUntil});

  @override
  List<Object?> get props => [blockUntil];
}

class LoginLoaded extends LoginState {
  LoginLoaded({
    required this.token,
  });

  final Token token;

  @override
  List<Object?> get props => [token];
}