import '../modifier_group.dart';

abstract class AbstractModifierGroupRepository {
  Future<List<ModifierGroupResponse>> getModifierGroupList();
  Future<ModifierGroupResponse> getModifierGroup(int modifierGroupId);
  Future<ModifierGroupResponse> postCreateModifierGroup(ModifierGroupCreateDTO dto);
  Future<ModifierGroupResponse> patchModifierGroup(int modifierGroupId, ModifierGroupPatchDTO dto);
  Future<void> deleteHardModifierGroup(int modifierGroupId);
  Future<void> deleteSoftModifierGroup(int modifierGroupId);
  Future<void> postRestoreModifierGroup(int modifierGroupId);
}
