import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '/core/repositories/users/client/restaraunt/carts/carts.dart';
import '/core/widgets/payment_modal.dart';
import '/core/services/app_toast.dart';
import '/core/services/return_url.dart';
import '/core/repositories/users/client/restaraunt/orders/orders.dart';
import '/core/repositories/users/client/profile/profile.dart';
import '/core/router/router.dart';
import '../bloc/cart_bloc.dart';
import '../widgets/widgets.dart';

part 'cart_items_screen.dart';
part 'cart_comment_screen.dart';
part 'cart_payment_screen.dart';

@RoutePage()
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {

  late final CartBloc _cartBloc;

  @override
  void initState() {
    super.initState();

    _cartBloc = CartBloc(
      GetIt.I<AbstractCartRepository>(),
      GetIt.I<AbstractOrdersRepository>(),
    );
  }

  @override
  void dispose() {
    _cartBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cartBloc,
      child: AutoTabsRouter.tabBar(

        routes: const [
          CartItemsRoute(),
          CartCommentRoute(),
          CartPaymentRoute(),
        ],
        builder: (context, child, controller) {
          final tabsRouter = AutoTabsRouter.of(context);

          CartStep currentStep;
          switch (tabsRouter.activeIndex) {
            case 0:
              currentStep = CartStep.items;
              break;
            case 1:
              currentStep = CartStep.address;
              break;
            case 2:
              currentStep = CartStep.payment;
              break;
            default:
              currentStep = CartStep.items;
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Оформление заказа'),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {

                  if (tabsRouter.activeIndex > 0) {
                    tabsRouter.setActiveIndex(tabsRouter.activeIndex - 1);
                  } else {

                    context.router.pop();
                  }
                },
              ),
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  children: [

                    CartProgressIndicator(currentStep: currentStep),
                    Expanded(
                      child: child,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}