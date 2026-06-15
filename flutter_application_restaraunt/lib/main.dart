import 'dart:async';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_application_restaraunt/api_config.dart';
import 'core/platform/url_strategy.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:talker_flutter/talker_flutter.dart';
import 'package:talker_dio_logger/talker_dio_logger.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';

import 'core/core.dart';
import 'core/repositories/users/operator/orders/operator_orders_repository.dart';
import 'core/repositories/promotions/promotion.dart';
import 'core/repositories/reviews/reviews.dart';
import 'core/repositories/favorites/favorites.dart';
import 'core/services/order_notifications_service.dart';
import 'core/repositories/users/admin/admin_management.dart';
import 'app.dart';

void main() async {

  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
    const defineUrl = String.fromEnvironment('API_SITE_URL');
    var apiSiteUrl = defineUrl.isNotEmpty
        ? defineUrl
        : (dotenv.env['API_SITE_URL'] ?? 'http://127.0.0.1:8000');

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      apiSiteUrl = apiSiteUrl
          .replaceFirst('127.0.0.1', '10.0.2.2')
          .replaceFirst('//localhost', '//10.0.2.2');
    }
    ApiConfig.apiSiteUrl = apiSiteUrl;

    if (!kIsWeb) {
      SystemChannels.textInput.invokeMethod('TextInput.setImeHidden', true);
    } else {

      configureUrlStrategy();
    }

    final talker = TalkerFlutter.init();
    GetIt.I.registerSingleton(talker);
    GetIt.I<Talker>().debug('Talker started...');

    unawaited(NotificationService.instance.init());

    Hive.registerAdapter(TokenAdapter());
    Hive.registerAdapter(MenuAdapter());
    Hive.registerAdapter(ModifierGroupAdapter());
    Hive.registerAdapter(ModifierAdapter());

    await Hive.initFlutter();

    final tokenBox = await Hive.openBox<Token>(HiveHeaders.tokensNameBox);
    final menuBox = await Hive.openBox<Menu>(HiveHeaders.menuNameBox);
    await Hive.openBox<ModifierGroup>(HiveHeaders.modifierGroupNameBox);
    await Hive.openBox<Modifier>(HiveHeaders.modifierNameBox);

    final ordersBox = await Hive.openBox<String>(HiveHeaders.orderNameBox);

    final dio = Dio();

    dio.options.connectTimeout = const Duration(seconds: 15);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.sendTimeout = const Duration(seconds: 30);

    dio.interceptors
        .add(InterceptorsWrapper(onError: (DioException e, handler) {
      GetIt.I<Talker>().error('Dio Error: ${e.message}', e, e.stackTrace);

      if (e.response?.statusCode == 401 &&
          e.requestOptions.extra['skipAuthRedirect'] != true) {
        GetIt.I<AbstractJWTTokensRepository>().clearTokens();

        if (GetIt.I.isRegistered<OrderNotificationsService>()) {
          GetIt.I<OrderNotificationsService>().stop();
        }
        final current = appRouter.current.name;
        if (current != LoginRoute.name) {
          appRouter.replaceAll([const LoginRoute()]);
        }
      }
      return handler.next(e);
    }));

    dio.interceptors.add(
      TalkerDioLogger(
        talker: talker,
        settings: const TalkerDioLoggerSettings(
            printResponseData: false, printResponseTime: true),
      ),
    );

    Bloc.observer = TalkerBlocObserver(
      talker: talker,
      settings: const TalkerBlocLoggerSettings(
        printStateFullData: false,
        printEventFullData: false,
      ),
    );

    GetIt.I.registerLazySingleton<AbstractMenuRepository>(
      () => MenuRepository(
        dio: dio,
        menuBox: menuBox,
        apiSiteUrl: apiSiteUrl,
      ),
    );

    GetIt.I.registerLazySingleton<CategoriesRepository>(
      () => CategoriesRepository(dio: dio, apiSiteUrl: apiSiteUrl),
    );
    GetIt.I.registerLazySingleton<ProductRepository>(
      () => ProductRepository(dio: dio, apiSiteUrl: apiSiteUrl),
    );
    GetIt.I.registerLazySingleton<ProductVariantRepository>(
      () => ProductVariantRepository(dio: dio, apiSiteUrl: apiSiteUrl),
    );
    GetIt.I.registerLazySingleton<ModifierRepository>(
      () => ModifierRepository(dio: dio, apiSiteUrl: apiSiteUrl),
    );
    GetIt.I.registerLazySingleton<ModifierGroupRepository>(
      () => ModifierGroupRepository(dio: dio, apiSiteUrl: apiSiteUrl),
    );
    GetIt.I.registerLazySingleton<ModifierGroupAssociationRepository>(
      () =>
          ModifierGroupAssociationRepository(dio: dio, apiSiteUrl: apiSiteUrl),
    );
    GetIt.I.registerLazySingleton<AbstractComboItemsRepository>(
      () => ComboItemsRepository(dio: dio, apiSiteUrl: apiSiteUrl),
    );

    GetIt.I.registerSingleton<AbstractLoginRepository>(
      LoginRepository(
        dio: dio,
        tokenBox: tokenBox,
        apiSiteUrl: apiSiteUrl,
      ),
    );

    GetIt.I.registerSingleton<AbstractJWTTokensRepository>(
      JWTTokensRepository(
        dio: dio,
        tokenBox: tokenBox,
        apiSiteUrl: apiSiteUrl,
      ),
    );

    GetIt.I.registerSingleton<AbstractProfileRepository>(
      ProfileRepository(
        dio: dio,
        apiSiteUrl: apiSiteUrl,
      ),
    );

    GetIt.I.registerLazySingleton<AbstractCartRepository>(
      () => CartRepository(dio: dio, apiSiteUrl: apiSiteUrl),
    );

    GetIt.I.registerLazySingleton<AbstractOrdersRepository>(
      () => OrdersRepository(
        dio: dio,
        apiSiteUrl: apiSiteUrl,
        ordersCacheBox: ordersBox,
      ),
    );

    GetIt.I.registerLazySingleton<AbstractOperatorOrdersRepository>(
      () => OperatorOrdersRepository(dio: dio, apiSiteUrl: apiSiteUrl),
    );

    GetIt.I.registerLazySingleton<AbstractPromotionsRepository>(
      () => PromotionsRepository(dio: dio, apiSiteUrl: apiSiteUrl),
    );

    GetIt.I.registerLazySingleton<AbstractReviewsRepository>(
      () => ReviewsRepository(dio: dio, apiSiteUrl: apiSiteUrl),
    );

    GetIt.I.registerLazySingleton<AbstractFavoritesRepository>(
      () => FavoritesRepository(dio: dio, apiSiteUrl: apiSiteUrl),
    );

    GetIt.I.registerLazySingleton<OrderNotificationsService>(
      () => OrderNotificationsService(
        GetIt.I<AbstractOrdersRepository>(),
        GetIt.I<AbstractJWTTokensRepository>(),
      ),
    );

    GetIt.I.registerLazySingleton<AbstractAdminUsersRepository>(
      () => AdminUsersRepository(dio: dio, apiSiteUrl: apiSiteUrl),
    );
    GetIt.I.registerLazySingleton<AbstractAdminOrdersRepository>(
      () => AdminOrdersRepository(dio: dio, apiSiteUrl: apiSiteUrl),
    );

    FlutterError.onError =
        (details) => GetIt.I<Talker>().handle(details.exception, details.stack);

    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
        );

        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);

        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
          ),
        );
      } catch (e, st) {
        GetIt.I<Talker>().handle(e, st);
      }
    }

    pendingPaidOrderId =
        int.tryParse(Uri.base.queryParameters['paid_order'] ?? '');

    try {
      runApp(const FlutterApplicationRestaraunt());
    } catch (e, st) {
      GetIt.I<Talker>().handle(e, st);
      print('Error in runApp: $e\n$st');
    }
  }, (e, st) {
    GetIt.I<Talker>().handle(e, st);
    print('Uncaught Error: $e');
  });
}
