part of 'login_bloc.dart';

abstract class LoginEvent extends Equatable {}

class SubmitLogin extends LoginEvent {
  SubmitLogin({
    required this.email,
    required this.password,
    this.completer,
  });

  final String email;
  final String password;
  final Completer? completer;

  @override
  List<Object?> get props => [email, password, completer];
}

class LoadLogin extends LoginEvent {
  LoadLogin({
    this.completer,
  });

  final Completer? completer;

  @override
  List<Object?> get props => [completer];
}

class SendVerificationCodeEvent extends LoginEvent {
  SendVerificationCodeEvent({
    required this.email,
    this.completer,
  });

  final String email;
  final Completer? completer;

  @override
  List<Object?> get props => [email, completer];
}

class VerifyCodeEvent extends LoginEvent {
  VerifyCodeEvent({
    required this.email,
    required this.code,
    this.completer,
  });

  final String email;
  final String code;
  final Completer? completer;

  @override
  List<Object?> get props => [email, code, completer];
}

class ChangeEmailEvent extends LoginEvent {
  @override
  List<Object?> get props => [];
}

class TimerEndedEvent extends LoginEvent {
  @override
  List<Object?> get props => [];
}