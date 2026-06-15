import 'package:flutter/material.dart';

import '/core/repositories/users/client/restaraunt/orders/dto/dto.dart';
import '/core/utils/responsive.dart';
import '/core/widgets/order_history_timeline.dart';

class OrderDetailDialog extends StatelessWidget {
  const OrderDetailDialog({super.key, required this.order});

  final OrderResponseDTO order;

  static Future<void> show(BuildContext context, OrderResponseDTO order) {
    return showDialog<void>(
      context: context,
      builder: (_) => OrderDetailDialog(order: order),
    );
  }

  String _fmt(DateTime d) {
    final l = d.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(l.day)}.${two(l.month)}.${l.year} ${two(l.hour)}:${two(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('Заказ ${order.displayNumber}',
          style: theme.textTheme.titleMedium),
      content: SizedBox(
        width: dialogBodyWidth(context, max: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('Статус', order.status, theme),
              _row('Создан', _fmt(order.createdAt), theme),
              _row('Клиент',
                  '${order.customerName ?? '—'} · ${order.customerPhone ?? ''}',
                  theme),
              if (order.comment != null && order.comment!.trim().isNotEmpty)
                _row('Комментарий', order.comment!, theme),
              _row('Оплата',
                  '${order.paymentLabel} · ${order.payment?.status ?? '—'}',
                  theme),
              const Divider(),
              Text('Состав', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              ...order.items.map((it) {
                final mods = it.appliedModifiers
                    .map((m) => m.name)
                    .where((n) => n.isNotEmpty)
                    .join(', ');
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${it.productVariant.product.name} '
                        '(${it.productVariant.name}) ×${it.quantity}'
                        '${it.pricePerUnit != null ? ' — ${it.pricePerUnit! * it.quantity} ₽' : ''}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (mods.isNotEmpty)
                        Text('+ $mods',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6))),
                    ],
                  ),
                );
              }),
              const Divider(),
              Text('Итого: ${order.totalPrice ?? 0} ₽',
                  style: theme.textTheme.titleMedium),
              if (order.statusHistory.isNotEmpty) ...[
                const Divider(),
                Text('История', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                OrderHistoryTimeline(history: order.statusHistory),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }

  Widget _row(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface
                        .withValues(alpha: 0.6))),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

}
