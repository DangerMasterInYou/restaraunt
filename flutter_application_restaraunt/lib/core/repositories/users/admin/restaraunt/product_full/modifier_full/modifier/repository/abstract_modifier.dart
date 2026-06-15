import '../dto/dto.dart';

abstract class AbstractModifierRepository {
  Future<List<ModifierResponse>> getModifierList();
  Future<ModifierResponse> getModifier(int modifierId);
  Future<ModifierResponse> postCreateModifier(
      int groupId, ModifierCreateDTO dto);
  Future<ModifierResponse> patchModifier(int modifierId, ModifierPatchDTO dto);
  Future<void> deleteHardModifier(int modifierId);
  Future<void> deleteSoftModifier(int modifierId);
  Future<void> postRestoreModifier(int modifierId);
}
