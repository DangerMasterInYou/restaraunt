import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '/core/repositories/auth/login/login.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc(this.loginRepository) : super(LoginInitial()) {
    on<SendVerificationCodeEvent>(_handleSendVerificationCode);
    on<VerifyCodeEvent>(_handleVerifyCode);
    on<ChangeEmailEvent>(_handleChangeEmail);
    on<TimerEndedEvent>(_handleTimerEnded);
  }

  final AbstractLoginRepository loginRepository;
  String _currentEmail = '';

  Future<void> _handleSendVerificationCode(
    SendVerificationCodeEvent event,
    Emitter<LoginState> emit,
  ) async {
    try {
      emit(LoginLoading());
      _currentEmail = event.email;
      final success = await loginRepository.sendVerificationCode(event.email);
      if (success) {
        emit(VerificationCodeSentSuccess(email: event.email));
      } else {
        emit(VerificationCodeSentFailure(
            exception: Exception('Не удалось отправить код')));
      }
    } catch (e, st) {
      emit(VerificationCodeSentFailure(exception: e));
      GetIt.I<Talker>().handle(e, st);
    } finally {
      event.completer?.complete();
    }
  }

  Future<void> _handleVerifyCode(
    VerifyCodeEvent event,
    Emitter<LoginState> emit,
  ) async {
    try {
      emit(LoginLoading());
      final token = await loginRepository.verifyCode(event.email, event.code);
      if (token != null) {
        emit(LoginSuccess(token: token, role: loginRepository.lastRole));
        try {

        } catch (e, st) {
          GetIt.I<Talker>().handle(
              e, st, 'Failed to initiate WebSocket connection after login');
        }
      } else {
        throw Exception('Не удалось верифицировать код');
      }
    } catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      if (e is AttemptsExceededException) {
        if (e.attemptsLeft == 0) {
          final blockUntil = DateTime.now().add(LoginRepository.blockDuration);
          emit(LoginBlocked(blockUntil: blockUntil));
        } else {
          emit(LoginFailure(
              email: event.email, exception: e, attemptsLeft: e.attemptsLeft));
        }
      } else {
        emit(LoginFailure(email: event.email, exception: e));
      }
    } finally {
      event.completer?.complete();
    }
  }

  void _handleChangeEmail(
    ChangeEmailEvent event,
    Emitter<LoginState> emit,
  ) {
    loginRepository.resetAttempts();
    emit(LoginInitial());
    _currentEmail = '';
  }

  void _handleTimerEnded(
    TimerEndedEvent event,
    Emitter<LoginState> emit,
  ) {
    if (_currentEmail.isNotEmpty) {
      emit(VerificationCodeSentSuccess(email: _currentEmail));
    } else {
      emit(LoginInitial());
    }
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    super.onError(error, stackTrace);
    GetIt.I<Talker>().handle(error, stackTrace);
  }
}
