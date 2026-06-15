import 'package:dio/dio.dart';

import '../menu.dart';

import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MenuRepository implements AbstractMenuRepository {
  MenuRepository({
    required this.dio,
    required this.menuBox,
    required this.apiSiteUrl,
  });

  final Dio dio;
  final Box<Menu> menuBox;
  final String apiSiteUrl;

  @override
  Future<List<Menu>> getMenuList() async {
    var menuList = <Menu>[];
    try {
      menuList = await _fetchMenuListFromApi();
      final menuMap = {for (var e in menuList) e.id: e};
      await menuBox.putAll(menuMap);
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      menuList = menuBox.values.toList();
    }
    return menuList;
  }

  Future<List<Menu>> _fetchMenuListFromApi() async {
    try {
      final response = await dio.get(
        '$apiSiteUrl/menu/products',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Ошибка при загрузке данных: ${response.statusCode}',
        );
      }
      final data = response.data;
      if (data is! List) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Неожиданный формат ответа',
        );
      }
      final menuList = data.map((item) {
        if (item is! Map<String, dynamic>) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: 'Неверный формат данных продукта',
          );
        }
        try {
          final menu = Menu.fromJson(item);
          return menu;
        } catch (e) {
          rethrow;
        }
      }).toList();
      return List<Menu>.from(menuList);
    } on DioException catch (e) {
      GetIt.instance<Talker>().handle(e, e.stackTrace);
      rethrow;
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      throw Exception('Ошибка при получении списка продукт: $e');
    }
  }

  @override
  Future<Menu> getMenu(int menuId) async {
    try {
      final menu = await _fetchMenuFromApi(menuId);
      await menuBox.put(menu.id, menu);
      return menu;
    } catch (e, st) {
      GetIt.instance<Talker>().handle(e, st);
      for (var key in menuBox.keys) {
        final menu = menuBox.get(key);
        if (menu != null && menu.id == menuId) {
          return menu;
        }
      }
      throw Exception('Ошибка при получении продукта: $e');
    }
  }

  Future<Menu> _fetchMenuFromApi(int menuId) async {
    try {
      final response = await dio.get(
        '$apiSiteUrl/menu/product/$menuId',
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Ошибка при загрузке данных: ${response.statusCode}',
        );
      }
      final menuData = response.data;
      if (menuData is! Map<String, dynamic>) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Неожиданный формат ответа для продукта $menuId',
        );
      }
      final menu = Menu.fromJson(menuData);
      return menu;
    } catch (e) {
      throw Exception('Ошибка при получении продукта: $e');
    }
  }
}
