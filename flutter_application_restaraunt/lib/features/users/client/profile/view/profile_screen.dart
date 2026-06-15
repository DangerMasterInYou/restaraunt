
import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '/core/router/router.dart';
import '/core/services/app_toast.dart';
import '/core/repositories/users/client/profile/profile.dart';
import '/core/repositories/services/jwt_tokens/abstract_jwt_tokens_repository.dart';
import '../bloc/profile_bloc.dart';
import '../widgets/widgets.dart';

@RoutePage()
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileBloc _profileBloc =
      ProfileBloc(GetIt.I<AbstractProfileRepository>());

  @override
  void initState() {
    super.initState();
    _profileBloc.add(LoadProfile());
  }

  @override
  void dispose() {
    _profileBloc.close();
    super.dispose();
  }

  Future<void> _onRefresh() {
    final completer = Completer<void>();
    _profileBloc.add(LoadProfile(completer: completer));
    return completer.future;
  }

  Future<void> _logout(BuildContext context, {bool force = false}) async {
    bool? confirmed = force;

    if (!force) {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Выход из аккаунта'),
            content: const Text('Вы уверены, что хотите выйти?'),
            actions: <Widget>[
              TextButton(
                child:
                    const Text('Отмена'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
              TextButton(
                child:
                    const Text('Выйти'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
            ],
          );
        },
      );
    }

    if (confirmed == true) {
      await GetIt.I<AbstractJWTTokensRepository>().clearTokens();

      if (mounted) {
        context.router.replaceAll([const LoginRoute()]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        iconTheme: theme.iconTheme,
        titleTextStyle: theme.textTheme.titleLarge,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Меню',
          onPressed: () {
            context.router.push(const MenuRoute());
          },
        ),
        title: const Text('Профиль', style: TextStyle(fontSize: 24)),
        centerTitle: true,
        actions: [
          BlocBuilder<ProfileBloc, ProfileState>(
            bloc: _profileBloc,
            builder: (context, state) {
              final role = state is ProfileLoaded ? state.profile.role : null;
              final isAdmin = role == 'admin';
              final isOperator = role == 'operator' || isAdmin;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isOperator)
                    IconButton(
                      icon: const Icon(Icons.point_of_sale),
                      tooltip: 'Кабинет оператора',
                      onPressed: () =>
                          context.router.push(const OperatorOrdersRoute()),
                    ),
                  if (isAdmin)
                    IconButton(
                      icon: const Icon(Icons.admin_panel_settings),
                      tooltip: 'Админ-панель',
                      onPressed: () =>
                          context.router.push(const AdminPanelRoute()),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () => _logout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocProvider.value(
        value: _profileBloc,
        child: BlocListener<ProfileBloc, ProfileState>(
          listener: (context, state) {

            if (state is ProfileLoaded &&
                _profileBloc.state is ProfileLoading) {
              AppToast.success(context, 'Профиль успешно обновлён!');
            }

            else if (state is ProfileUpdateFailure) {
              AppToast.fromError(context, state.exception,
                  prefix: 'Не удалось обновить профиль');
              _profileBloc.emit(ProfileLoaded(profile: state.lastProfile));
            }

            else if (state is ProfileDeleteSuccess) {
              AppToast.success(context, 'Профиль успешно удалён.');
              _logout(context, force: true);
            }

            else if (state is ProfileDeleteFailure) {
              AppToast.fromError(context, state.exception,
                  prefix: 'Не удалось удалить профиль');
              _profileBloc.emit(ProfileLoaded(profile: state.lastProfile));
            }
          },
          child: BlocBuilder<ProfileBloc, ProfileState>(
            builder: (context, state) {
              if (state is ProfileInitial ||
                  state is ProfileLoading ||
                  state is ProfileDeleteInProgress) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is ProfileLoaded) {
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: theme.colorScheme.onSurface,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: ProfileContent(
                    profile: state.profile,
                    profileBloc: _profileBloc,
                  ),
                );
              }

              if (state is ProfileLoadingFailure) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,

                          size: 80,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Не удалось загрузить профиль',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Пожалуйста, проверьте ваше интернет-соединение и попробуйте снова.',
                          style:
                              TextStyle(
                                fontSize: 16,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.8),
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Попробовать снова'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          onPressed: () => _profileBloc.add(LoadProfile()),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is ProfileUpdateFailure ||
                  state is ProfileDeleteFailure) {
                final profile = (state is ProfileUpdateFailure)
                    ? state.lastProfile
                    : (state as ProfileDeleteFailure).lastProfile;
                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: Builder(
                    builder: (context) => ProfileContent(
                      profile: profile,
                      profileBloc: _profileBloc,
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
