import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '/core/repositories/reviews/reviews.dart';
import '/core/repositories/users/client/restaraunt/orders/orders.dart';
import '/core/router/router.dart';
import '/core/services/app_toast.dart';
import '../bloc/orders_bloc.dart';

enum OrdersFilter { active, archived }

@RoutePage()
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final OrdersBloc _ordersBloc;
  OrdersFilter _filter = OrdersFilter.active;
  Timer? _pollTimer;

  Map<int, ReviewDTO> _reviewsByOrder = {};

  @override
  void initState() {
    super.initState();
    _ordersBloc = OrdersBloc(GetIt.I<AbstractOrdersRepository>())
      ..add(const LoadOrders());

    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _ordersBloc.add(const RefreshOrders());
    });
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final mine = await GetIt.I<AbstractReviewsRepository>().getMyReviews();
      if (mounted) {
        setState(() {
          _reviewsByOrder = {for (final r in mine) r.orderId: r};
        });
      }
    } catch (_) {

    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _ordersBloc.close();
    super.dispose();
  }

  List<Widget> _reviewBadge(ThemeData theme, OrderResponseDTO order) {
    if (!order.status.toLowerCase().contains('заверш')) return const [];
    final review = _reviewsByOrder[order.id];
    final String label;
    final Color color;
    final IconData icon;
    if (review == null) {
      label = 'Ждёт вашего отзыва';
      color = Colors.amber.shade700;
      icon = Icons.rate_review_outlined;
    } else if (review.response != null && review.response!.isNotEmpty) {
      label = 'Заведение ответило на отзыв';
      color = Colors.green.shade600;
      icon = Icons.mark_chat_read_outlined;
    } else {
      label = 'Отзыв отправлен';
      color = theme.colorScheme.primary;
      icon = Icons.check_circle_outline;
    }
    return [
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<OrderResponseDTO> _filtered(List<OrderResponseDTO> orders) {
    return orders.where((order) {
      return _filter == OrdersFilter.active ? order.isActive : order.isArchived;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = _formatDateTime;

    return BlocProvider.value(
      value: _ordersBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Мои заказы'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<OrdersFilter>(
                segments: const [
                  ButtonSegment(
                    value: OrdersFilter.active,
                    label: Text('Активные'),
                    icon: Icon(Icons.pending_actions),
                  ),
                  ButtonSegment(
                    value: OrdersFilter.archived,
                    label: Text('Архив'),
                    icon: Icon(Icons.archive_outlined),
                  ),
                ],
                selected: {_filter},
                onSelectionChanged: (selection) {
                  setState(() => _filter = selection.first);
                },
              ),
            ),
            Expanded(
              child: BlocConsumer<OrdersBloc, OrdersState>(
                listener: (context, state) {

                  if (state is OrdersLoaded && state.notice != null) {
                    AppToast.info(context, state.notice!);
                  }
                },
                builder: (context, state) {
                  if (state is OrdersLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is OrdersLoadingFailure) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Ошибка загрузки: ${state.exception}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () =>
                                _ordersBloc.add(const LoadOrders()),
                            child: const Text('Повторить'),
                          ),
                        ],
                      ),
                    );
                  }

                  final orders = switch (state) {
                    OrdersLoaded(:final ordersList) => ordersList,
                    _ => const <OrderResponseDTO>[],
                  };

                  final filtered = _filtered(orders);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        _filter == OrdersFilter.active
                            ? 'Нет активных заказов'
                            : 'Архив пуст',
                        style: theme.textTheme.titleMedium,
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final order = filtered[index];

                      Color? borderColor;
                      if (order.isActive) {
                        final paid = order.payment?.amount ?? 0;
                        final statusOk =
                            (order.payment?.status.toLowerCase() ?? '')
                                .contains('успеш');
                        final fullyPaid =
                            statusOk && paid >= (order.totalPrice ?? 0);
                        borderColor = fullyPaid
                            ? Colors.green
                            : Colors.amber.shade700;
                      }
                      return Card(
                        shape: borderColor != null
                            ? RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: borderColor, width: 2),
                              )
                            : null,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          title: Text(order.displayNumber),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Статус: ${order.status}'),
                              Text(
                                dateFormat(order.createdAt.toLocal()),
                                style: theme.textTheme.bodySmall,
                              ),

                              ..._reviewBadge(theme, order),
                            ],
                          ),
                          trailing: SizedBox(
                            width: 80,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${order.totalPrice ?? 0} ₽',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const Icon(Icons.chevron_right, size: 20),
                              ],
                            ),
                          ),
                          onTap: () {
                            context.router.push(
                              OrderDetailRoute(
                                orderNumber:
                                    order.orderNumber ?? order.id.toString(),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
