import '../product.dart';

abstract class AbstractProductRepository {
  Future<List<ProductResponse>> getProductList();
  Future<ProductResponse> getProduct(int productId);
  Future<ProductResponse> postCreateProduct(ProductCreateDTO dto);
  Future<ProductResponse> patchProduct(int productId, ProductPatchDTO dto);
  Future<void> deleteHardProduct(int productId);
  Future<void> deleteSoftProduct(int productId);
  Future<void> postRestoreProduct(int productId);
  Future<void> uploadProductImage(int productId, String filePath);
  Future<void> reorderProducts(List<int> ids);
}
