import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '/core/repositories/users/client/restaraunt/orders/orders.dart';
import '/core/repositories/reviews/reviews.dart';
import '/core/widgets/payment_modal.dart';
import '/core/widgets/order_history_timeline.dart';
import '/core/services/app_toast.dart';
import '/core/services/return_url.dart';
import '../bloc/order_detail_bloc.dart';

@RoutePage()
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    super.key,
    @PathParam('order_number') required this.orderNumber,
  });

  final String orderNumber;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final OrderDetailBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = OrderDetailBloc(GetIt.I<AbstractOrdersRepository>())
      ..add(LoadOrderDetailByNumber(widget.orderNumber));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  Future<void> _payOnline(int orderId, int? amount) async {
    try {
      final url = await GetIt.I<AbstractOrdersRepository>().initPayment(
        orderId,
        returnUrl: paymentReturnUrl(),
      );
      if (!mounted) return;
      await showPaymentModal(context,
          confirmationUrl: url, amount: amount ?? 0, orderId: orderId);
    } catch (e) {
      if (mounted) {
        AppToast.fromError(context, e, prefix: 'Оплата недоступна');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = _formatDateTime;

    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: AppBar(title: const Text('Детали заказа')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: BlocBuilder<OrderDetailBloc, OrderDetailState>(
          builder: (context, state) {
            if (state is OrderDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is OrderDetailFailure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ошибка: ${state.exception}',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => _bloc
                          .add(LoadOrderDetailByNumber(widget.orderNumber)),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              );
            }

            if (state is! OrderDetailLoaded) {
              return const SizedBox.shrink();
            }

            final order = state.order;
            final isPaid =
                (order.payment?.status.toLowerCase() ?? '').contains('успеш');
            final paySystem =
                (order.payment?.paymentSystem ?? order.paymentMethod ?? '')
                    .toLowerCase();
            final isOnline = paySystem.contains('online') ||
                paySystem.contains('yookassa') ||
                paySystem.contains('card') ||
                paySystem.contains('sbp');

            final paid = order.payment?.amount ?? 0;
            final outstanding = (order.totalPrice ?? 0) - paid;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [

                if (isPaid && paid > 0 && outstanding > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Сумма заказа изменилась. Нужно доплатить $outstanding ₽',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer),
                        ),
                        const SizedBox(height: 8),
                        if (isOnline)
                          FilledButton.icon(
                            onPressed: () => _payOnline(order.id, outstanding),
                            icon: const Icon(Icons.price_change_outlined),
                            label: Text('Доплатить $outstanding ₽'),
                          )
                        else
                          Text(
                            'Доплата принимается наличными у оператора при получении',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer),
                          ),
                      ],
                    ),
                  ),
                ],

                if (!isPaid) ...[
                  Center(
                    child: FilledButton.icon(
                      onPressed: () => _payOnline(order.id, order.totalPrice),
                      icon: const Icon(Icons.payment),
                      label:
                          Text('Оплатить онлайн ${order.totalPrice ?? 0} ₽'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text('Или наличными у оператора при получении',
                        style: theme.textTheme.bodySmall),
                  ),
                  const SizedBox(height: 16),
                ],
                _InfoCard(
                  title: order.displayNumber,
                  children: [
                    _InfoRow('Статус', order.status),
                    _InfoRow('Сумма', '${order.totalPrice ?? 0} ₽'),
                    _InfoRow(
                      'Создан',
                      dateFormat(order.createdAt.toLocal()),
                    ),
                    if (order.customerName != null)
                      _InfoRow('Имя', order.customerName!),
                    if (order.customerPhone != null)
                      _InfoRow('Телефон', order.customerPhone!),
                    if (order.comment != null && order.comment!.isNotEmpty)
                      _InfoRow('Комментарий', order.comment!),
                    _InfoRow('Оплата', order.paymentLabel),
                    if (order.payment != null)
                      _InfoRow('Статус оплаты', order.payment!.status),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Состав заказа', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                ...order.items.map(
                  (item) => Card(
                    child: ListTile(
                      title: Text(
                        '${item.productVariant.product.name} — ${item.productVariant.name}',
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item.pricePerUnit} ₽ × ${item.quantity}'),
                          if (item.appliedModifiers.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            ...item.appliedModifiers.map(
                              (mod) => Text(
                                '${mod.name}${mod.quantity > 1 ? " ×${mod.quantity}" : ""}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: Text(
                        '${(item.pricePerUnit ?? 0) * item.quantity} ₽',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ),
                ),

                if (order.status.toLowerCase().contains('заверш')) ...[
                  const SizedBox(height: 16),
                  _ClientReviewSection(orderId: order.id),
                ],
                if (order.statusHistory.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('История заказа', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: OrderHistoryTimeline(
                        history: order.statusHistory,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

String _formatDateTime(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final h = date.hour.toString().padLeft(2, '0');
  final min = date.minute.toString().padLeft(2, '0');
  return '$d.$m.${date.year} $h:$min';
}

class _ClientReviewSection extends StatefulWidget {
  const _ClientReviewSection({required this.orderId});
  final int orderId;

  @override
  State<_ClientReviewSection> createState() => _ClientReviewSectionState();
}

class _ClientReviewSectionState extends State<_ClientReviewSection> {
  final _repo = GetIt.I<AbstractReviewsRepository>();
  final _textController = TextEditingController();
  ReviewDTO? _review;
  bool _loading = true;
  int _rating = 5;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final mine = await _repo.getMyReviews();
      final matches = mine.where((r) => r.orderId == widget.orderId);
      _review = matches.isEmpty ? null : matches.first;
    } catch (_) {

    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final r = await _repo.createReview(
        widget.orderId,
        _rating,
        _textController.text.trim().isEmpty ? null : _textController.text.trim(),
      );
      if (mounted) {
        setState(() => _review = r);
        AppToast.success(context, 'Спасибо за отзыв!');
      }
    } catch (e) {
      if (mounted) AppToast.fromError(context, e, prefix: 'Не удалось отправить отзыв');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(8), child: CircularProgressIndicator()));
    }

    Widget stars(int value, {void Function(int)? onTap}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            5,
            (i) => IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(i < value ? Icons.star : Icons.star_border,
                  color: Colors.amber.shade700),
              onPressed: onTap == null ? null : () => onTap(i + 1),
            ),
          ),
        );

    final r = _review;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ваш отзыв', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            if (r != null) ...[
              stars(r.rating),
              if (r.text != null && r.text!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(r.text!),
                ),
              if (r.response != null && r.response!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ответ заведения',
                          style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(r.response!,
                          style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer)),
                    ],
                  ),
                ),
            ] else ...[
              stars(_rating, onTap: (v) => setState(() => _rating = v)),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Поделитесь впечатлением (необязательно)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Отправить отзыв'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
