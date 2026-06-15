import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ThemeEvent {}

class ThemeStarted extends ThemeEvent {}

class ToggleThemeEvent extends ThemeEvent {}

abstract class ThemeState {
  const ThemeState(this.mode);
  final ThemeMode mode;
}

class ThemeInitial extends ThemeState {
  const ThemeInitial() : super(ThemeMode.system);
}

class ThemeChanged extends ThemeState {
  const ThemeChanged(super.mode);
}

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeInitial()) {
    on<ThemeStarted>(_onStarted);
    on<ToggleThemeEvent>(_onToggle);
  }

  static const _prefKey = 'app_theme_mode';

  Future<void> _onStarted(ThemeStarted event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    final mode = switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    emit(ThemeChanged(mode));
  }

  Future<void> _onToggle(ToggleThemeEvent event, Emitter<ThemeState> emit) async {
    final next = state.mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      next == ThemeMode.dark ? 'dark' : 'light',
    );
    emit(ThemeChanged(next));
  }
}
