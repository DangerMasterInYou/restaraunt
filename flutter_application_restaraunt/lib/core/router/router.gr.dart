// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'router.dart';

abstract class _$AppRouter extends RootStackRouter {
  // ignore: unused_element
  _$AppRouter({super.navigatorKey});

  @override
  final Map<String, PageFactory> pagesMap = {
    AdminPanelRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const AdminPanelScreen(),
      );
    },
    CartCommentRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const CartCommentScreen(),
      );
    },
    CartItemsRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const CartItemsScreen(),
      );
    },
    CartPaymentRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const CartPaymentScreen(),
      );
    },
    CartRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const CartScreen(),
      );
    },
    LoginRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const LoginScreen(),
      );
    },
    MenuRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const MenuScreen(),
      );
    },
    OperatorOrdersRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const OperatorOrdersScreen(),
      );
    },
    OrderDetailRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final args = routeData.argsAs<OrderDetailRouteArgs>(
          orElse: () => OrderDetailRouteArgs(
              orderNumber: pathParams.getString('order_number')));
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: OrderDetailScreen(
          key: args.key,
          orderNumber: args.orderNumber,
        ),
      );
    },
    OrdersRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const OrdersScreen(),
      );
    },
    ProductRoute.name: (routeData) {
      final args = routeData.argsAs<ProductRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: ProductScreen(
          key: args.key,
          id: args.id,
        ),
      );
    },
    ProfileRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const ProfileScreen(),
      );
    },
  };
}

/// generated route for
/// [AdminPanelScreen]
class AdminPanelRoute extends PageRouteInfo<void> {
  const AdminPanelRoute({List<PageRouteInfo>? children})
      : super(
          AdminPanelRoute.name,
          initialChildren: children,
        );

  static const String name = 'AdminPanelRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [CartCommentScreen]
class CartCommentRoute extends PageRouteInfo<void> {
  const CartCommentRoute({List<PageRouteInfo>? children})
      : super(
          CartCommentRoute.name,
          initialChildren: children,
        );

  static const String name = 'CartCommentRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [CartItemsScreen]
class CartItemsRoute extends PageRouteInfo<void> {
  const CartItemsRoute({List<PageRouteInfo>? children})
      : super(
          CartItemsRoute.name,
          initialChildren: children,
        );

  static const String name = 'CartItemsRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [CartPaymentScreen]
class CartPaymentRoute extends PageRouteInfo<void> {
  const CartPaymentRoute({List<PageRouteInfo>? children})
      : super(
          CartPaymentRoute.name,
          initialChildren: children,
        );

  static const String name = 'CartPaymentRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [CartScreen]
class CartRoute extends PageRouteInfo<void> {
  const CartRoute({List<PageRouteInfo>? children})
      : super(
          CartRoute.name,
          initialChildren: children,
        );

  static const String name = 'CartRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [LoginScreen]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
      : super(
          LoginRoute.name,
          initialChildren: children,
        );

  static const String name = 'LoginRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [MenuScreen]
class MenuRoute extends PageRouteInfo<void> {
  const MenuRoute({List<PageRouteInfo>? children})
      : super(
          MenuRoute.name,
          initialChildren: children,
        );

  static const String name = 'MenuRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [OperatorOrdersScreen]
class OperatorOrdersRoute extends PageRouteInfo<void> {
  const OperatorOrdersRoute({List<PageRouteInfo>? children})
      : super(
          OperatorOrdersRoute.name,
          initialChildren: children,
        );

  static const String name = 'OperatorOrdersRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [OrderDetailScreen]
class OrderDetailRoute extends PageRouteInfo<OrderDetailRouteArgs> {
  OrderDetailRoute({
    Key? key,
    required String orderNumber,
    List<PageRouteInfo>? children,
  }) : super(
          OrderDetailRoute.name,
          args: OrderDetailRouteArgs(
            key: key,
            orderNumber: orderNumber,
          ),
          rawPathParams: {'order_number': orderNumber},
          initialChildren: children,
        );

  static const String name = 'OrderDetailRoute';

  static const PageInfo<OrderDetailRouteArgs> page =
      PageInfo<OrderDetailRouteArgs>(name);
}

class OrderDetailRouteArgs {
  const OrderDetailRouteArgs({
    this.key,
    required this.orderNumber,
  });

  final Key? key;

  final String orderNumber;

  @override
  String toString() {
    return 'OrderDetailRouteArgs{key: $key, orderNumber: $orderNumber}';
  }
}

/// generated route for
/// [OrdersScreen]
class OrdersRoute extends PageRouteInfo<void> {
  const OrdersRoute({List<PageRouteInfo>? children})
      : super(
          OrdersRoute.name,
          initialChildren: children,
        );

  static const String name = 'OrdersRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [ProductScreen]
class ProductRoute extends PageRouteInfo<ProductRouteArgs> {
  ProductRoute({
    Key? key,
    required int id,
    List<PageRouteInfo>? children,
  }) : super(
          ProductRoute.name,
          args: ProductRouteArgs(
            key: key,
            id: id,
          ),
          initialChildren: children,
        );

  static const String name = 'ProductRoute';

  static const PageInfo<ProductRouteArgs> page =
      PageInfo<ProductRouteArgs>(name);
}

class ProductRouteArgs {
  const ProductRouteArgs({
    this.key,
    required this.id,
  });

  final Key? key;

  final int id;

  @override
  String toString() {
    return 'ProductRouteArgs{key: $key, id: $id}';
  }
}

/// generated route for
/// [ProfileScreen]
class ProfileRoute extends PageRouteInfo<void> {
  const ProfileRoute({List<PageRouteInfo>? children})
      : super(
          ProfileRoute.name,
          initialChildren: children,
        );

  static const String name = 'ProfileRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}
