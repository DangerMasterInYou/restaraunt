import '../category.dart';

abstract class AbstractCategoriesRepository {
  Future<List<CategoryResponse>> getCategoryList();
  Future<CategoryResponse> getCategory(int categoryId);
  Future<CategoryResponse> postCreateCategory(CategoryCreateDTO dto);
  Future<CategoryResponse> patchCategory(int categoryId, CategoryPatchDTO dto);
  Future<void> deleteHardCategory(int categoryId);
  Future<void> deleteSoftCategory(int categoryId);
  Future<void> postRestoreCategory(int categoryId);
  Future<void> reorderCategories(List<int> ids);
}
