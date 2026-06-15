import 'package:flutter/material.dart';
import 'package:flutter_application_restaraunt/core/router/router.dart';
import 'package:flutter_application_restaraunt/core/theme/theme.dart';
import 'package:flutter_application_restaraunt/features/theme/bloc/theme_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';

import '/core/repositories/users/client/restaraunt/orders/orders.dart';
import '/core/services/order_notifications_service.dart';
import '/core/services/pending_payment.dart';

final appRouter = AppRouter();

int? pendingPaidOrderId;

class FlutterApplicationRestaraunt extends StatefulWidget {
  const FlutterApplicationRestaraunt({super.key});

  @override
  State<FlutterApplicationRestaraunt> createState() =>
      _FlutterApplicationRestarauntState();
}

class _FlutterApplicationRestarauntState
    extends State<FlutterApplicationRestaraunt>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handlePaymentReturn();
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) GetIt.I<OrderNotificationsService>().start();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final id = pendingOnlinePaymentOrderId;
      if (id != null) _confirmPendingPayment(id);
    }
  }

  Future<void> _confirmPendingPayment(int orderId) async {
    try {
      final order =
          await GetIt.I<AbstractOrdersRepository>().confirmPayment(orderId);
      final paid =
          (order.payment?.status.toLowerCase() ?? '').contains('успеш');
      if (paid) pendingOnlinePaymentOrderId = null;
    } catch (_) {}
  }

  Future<void> _handlePaymentReturn() async {
    final orderId = pendingPaidOrderId;
    if (orderId == null) return;
    pendingPaidOrderId = null;
    final repo = GetIt.I<AbstractOrdersRepository>();
    String? orderNumber;
    try {
      await repo.confirmPayment(orderId);

      final order = await repo.getOrder(orderId);
      orderNumber = order.orderNumber;
    } catch (_) {

    }
    if (orderNumber != null) {
      await appRouter.replaceAll([
        const MenuRoute(),
        OrderDetailRoute(orderNumber: orderNumber),
      ]);
    } else {
      await appRouter.replaceAll([const MenuRoute(), const OrdersRoute()]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ThemeBloc()..add(ThemeStarted()),
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeState.mode,
            routerConfig: appRouter.config(),

            builder: (context, child) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return DecoratedBox(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppGradients.darkSurface
                      : AppGradients.lightSurface,
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ru', 'RU'),
              Locale('en', 'US'),
            ],
          );
        },
      ),
    );
  }
}
