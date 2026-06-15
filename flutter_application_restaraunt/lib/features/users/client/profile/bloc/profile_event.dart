
part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();
}

class LoadProfile extends ProfileEvent {
  const LoadProfile({
    this.completer,
  });

  final Completer? completer;

  @override
  List<Object?> get props => [completer];
}

class UpdateProfile extends ProfileEvent {
  const UpdateProfile({
    required this.patchDto,
  });

  final ProfilePatchDTO patchDto;

  @override
  List<Object?> get props => [patchDto];
}

class DeleteProfile extends ProfileEvent {
  const DeleteProfile();

  @override
  List<Object?> get props => [];
}