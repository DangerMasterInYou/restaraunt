import '../product_variant.dart';

abstract class AbstractProductVariantRepository {
  Future<List<VariantResponse>> getProductVariantList();
  Future<VariantResponse> getProductVariant(int productVariantId);
  Future<VariantResponse> postCreateProductVariant(
      ProductVariantCreateDTO dto, int productId);
  Future<VariantResponse> patchProductVariant(
      int productVariantId, ProductVariantPatchDTO dto);
  Future<void> deleteHardProductVariant(int productVariantId);
  Future<void> deleteSoftProductVariant(int productVariantId);
  Future<void> postRestoreProductVariant(int productVariantId);
}
