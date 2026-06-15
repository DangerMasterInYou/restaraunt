abstract class AbstractModifierGroupAssociationRepository {
  Future<void> linkGroupToVariant(int variantId, int groupId);
  Future<void> unlinkGroupFromVariant(int variantId, int groupId);

  Future<void> linkGroupToProduct(int productId, int groupId);
  Future<void> unlinkGroupFromProduct(int productId, int groupId);
}
