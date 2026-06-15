
part of 'cart_screen.dart';

@RoutePage()
class CartPaymentScreen extends StatefulWidget {
  const CartPaymentScreen({super.key});

  @override
  State<CartPaymentScreen> createState() => _CartPaymentScreenState();
}

class _CartPaymentScreenState extends State<CartPaymentScreen> {
  String _selectedPaymentMethod = 'cash';
  Timer? _loadingTimer;
  bool _showRetryButton = false;
  bool _wasPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _startLoadingTimer();
  }

  void _startLoadingTimer() {
    _loadingTimer?.cancel();
    setState(() {
      _showRetryButton = false;
    });
    _loadingTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showRetryButton = true;
        });
      }
    });
  }

  void _cancelTimer() {
    _loadingTimer?.cancel();
    if (mounted) {
      setState(() {
        _showRetryButton = false;
      });
    }
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  void _retryLoad() {
    _startLoadingTimer();
    context.read<CartBloc>().add(const LoadCart());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CartBloc, CartState>(
      listenWhen: (previous, current) => previous != current,
      listener: (context, state) {

        if (state is CartLoaded) {
          _cancelTimer();
          _wasPlacingOrder = false;
        }
        if (state is CartPlacingOrder) {
          _wasPlacingOrder = true;
        }
        if (state is CartLoadingFailure && _wasPlacingOrder) {
          _wasPlacingOrder = false;

          AppToast.fromError(context, state.exception,
              prefix: 'Не удалось оформить заказ');

          context.read<CartBloc>().add(const LoadCart());
        }
        if (state is CartOrderPlaced) {
          _wasPlacingOrder = false;
          if (!context.mounted) return;
          _onOrderPlaced(context, state.order);
        }
      },
      builder: (context, state) {

        if (state is CartPlacingOrder) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is! CartLoaded && !_showRetryButton) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_showRetryButton && state is! CartLoaded) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Не удалось загрузить данные заказа.'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Попробовать снова'),
                  onPressed: _retryLoad,
                ),
              ],
            ),
          );
        }

        final cartResponse = (state as CartLoaded).cartResponse;
        final customerName = state.customerName;
        final customerPhone = state.customerPhone;

        final bool canPlaceOrder = customerName != null &&
            customerName.trim().isNotEmpty &&
            customerPhone != null &&
            customerPhone.trim().isNotEmpty &&
            cartResponse.items.isNotEmpty;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Способ оплаты',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 24),
              _buildPaymentMethodSelector(),
              const SizedBox(height: 24),
              _buildOrderSummary(context, cartResponse),
              const SizedBox(height: 24),
              if (!canPlaceOrder)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Заполните контактные данные на предыдущем шаге',
                    style: TextStyle(color: Colors.orange[300]),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: canPlaceOrder
                      ? () {

                          context.read<CartBloc>().add(
                                PlaceOrder(
                                  paymentMethod: _selectedPaymentMethod,

                                  returnUrl: paymentReturnUrl(),
                                ),
                              );
                        }
                      : null,
                  child: const Text('Оформить заказ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onOrderPlaced(
      BuildContext context, OrderResponseDTO order) async {
    final router = context.router;
    if (order.confirmationUrl != null && order.confirmationUrl!.isNotEmpty) {

      await showPaymentModal(
        context,
        confirmationUrl: order.confirmationUrl!,
        amount: order.totalPrice ?? 0,
        orderId: order.id,
      );
    } else {
      AppToast.success(context, 'Заказ ${order.displayNumber} оформлен');
    }
    router.popUntilRoot();
    router.replace(const MenuRoute());
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('Оплата при получении'),
          value: 'cash',
          groupValue: _selectedPaymentMethod,
          onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
        ),
        RadioListTile<String>(
          title: const Text('Онлайн оплата'),
          value: 'online',
          groupValue: _selectedPaymentMethod,
          onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
        ),
      ],
    );
  }

  Widget _buildOrderSummary(BuildContext context, CartResponseDTO cart) {
    final theme = Theme.of(context);
    final total = cart.totalPrice ?? 0;
    final discount = cart.discount ?? 0;
    final subtotal = cart.subtotalPrice ?? (total + discount);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Информация о заказе', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Стоимость товаров:'),
                Text('$subtotal ₽'),
              ],
            ),

            if (discount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    cart.appliedPromotions.isNotEmpty
                        ? 'Скидка (${cart.appliedPromotions.join(', ')}):'
                        : 'Скидка:',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                  Text('−$discount ₽',
                      style: TextStyle(color: theme.colorScheme.primary)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Итого:',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('$total ₽',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
