
part of 'cart_screen.dart';

@RoutePage()
class CartItemsScreen extends StatefulWidget {
  const CartItemsScreen({super.key});

  @override
  State<CartItemsScreen> createState() => _CartItemsScreenState();
}

class _CartItemsScreenState extends State<CartItemsScreen> {
  @override
  void initState() {
    super.initState();

    context.read<CartBloc>().add(const LoadCart());
  }

  @override
  Widget build(BuildContext context) {

    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        if (state is CartLoading || state is CartInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is CartLoadingFailure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Ошибка загрузки: ${state.exception}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      context.read<CartBloc>().add(const LoadCart()),
                  child: const Text('Попробовать снова'),
                ),
              ],
            ),
          );
        }
        if (state is CartLoaded) {
          final cartResponse = state.cartResponse;
          if (cartResponse.items.isEmpty) {
            return _buildEmptyCart(context);
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartResponse.items.length,
                  itemBuilder: (context, index) {
                    final cartItem = cartResponse.items[index];
                    return CartTileCard(
                      cartItem: cartItem,
                      onAdd: () {
                        context.read<CartBloc>().add(UpdateItemQuantity(
                              cartItemId: cartItem.id,
                              newQuantity: cartItem.quantity + 1,
                            ));
                      },
                      onSubtract: () {
                        if (cartItem.quantity > 1) {
                          context.read<CartBloc>().add(UpdateItemQuantity(
                                cartItemId: cartItem.id,
                                newQuantity: cartItem.quantity - 1,
                              ));
                        } else {
                          context
                              .read<CartBloc>()
                              .add(RemoveItemFromCart(cartItem.id));
                        }
                      },
                      onDelete: () {
                        context
                            .read<CartBloc>()
                            .add(RemoveItemFromCart(cartItem.id));
                      },
                    );
                  },
                ),
              ),
              _buildBottomBar(context, cartResponse.totalPrice ?? 0),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined,
              size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text('Ваша корзина пуста', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.router.pop(),
            child: const Text('Вернуться в меню'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, int totalPrice) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Итого:', style: Theme.of(context).textTheme.titleMedium),
              Text('$totalPrice ₽',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {

                AutoTabsRouter.of(context).setActiveIndex(1);
              },
              child: const Text('Продолжить'),
            ),
          ),
        ],
      ),
    );
  }
}
