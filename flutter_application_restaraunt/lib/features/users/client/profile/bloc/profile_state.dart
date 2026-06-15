
part of 'profile_bloc.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  @override
  List<Object?> get props => [];
}

class ProfileLoading extends ProfileState {
  @override
  List<Object?> get props => [];
}

class ProfileLoaded extends ProfileState {

  const ProfileLoaded({
    required this.profile,
  });

  final ProfileResponse profile;

  @override
  List<Object?> get props => [profile];
}

class ProfileLoadingFailure extends ProfileState {
  const ProfileLoadingFailure({
    this.exception,
  });

  final Object? exception;

  @override
  List<Object?> get props => [exception];
}

class ProfileUpdateFailure extends ProfileState {
  const ProfileUpdateFailure({
    required this.exception,
    required this.lastProfile,
  });

  final Object? exception;
  final ProfileResponse lastProfile;

  @override
  List<Object?> get props => [exception, lastProfile];
}

class ProfileDeleteInProgress extends ProfileState {
  @override
  List<Object?> get props => [];
}

class ProfileDeleteSuccess extends ProfileState {
  @override
  List<Object?> get props => [];
}

class ProfileDeleteFailure extends ProfileState {
  const ProfileDeleteFailure({required this.exception, required this.lastProfile});

  final Object exception;
  final ProfileResponse lastProfile;

  @override
  List<Object?> get props => [exception, lastProfile];
}