import '../menu.dart';

abstract class AbstractMenuRepository {
  Future<List<Menu>> getMenuList();
  Future<Menu> getMenu(int menuId);
}
