import '../profile.dart';

abstract class AbstractProfileRepository {
  Future<ProfileResponse> getProfile();
  Future<void> patchProfile(ProfilePatchDTO patchDto);
  Future<void> deleteProfile();
}
