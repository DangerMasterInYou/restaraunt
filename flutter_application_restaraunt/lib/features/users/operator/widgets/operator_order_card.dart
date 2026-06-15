import 'package:flutter/material.dart';

import '/core/repositories/users/client/restaraunt/orders/dto/dto.dart';

class OperatorOrderCard extends StatelessWidget {
  const OperatorOrderCard({
    super.key,
    required this.order,
    this.onEdit,
    this.onRefund,
    this.onBirthdayToggle,
    this.birthdayPromoActive = false,
    this.onMarkPaid,
  });

  final OrderResponseDTO order;
  final VoidCallback? onEdit;

  final VoidCallback? onMarkPaid;

  final VoidCallback? onRefund;

  final VoidCallback? onBirthdayToggle;

  final bool birthdayPromoActive;

  String get _itemsSummary => order.items
      .map((i) =>
          '${i.productVariant.product.name} (${i.productVariant.name}) ×${i.quantity}')
      .join(', ');

  bool get _isPaid {
    final s = order.payment?.status.toLowerCase() ?? '';
    return s.contains('успеш') || s.contains('paid') || s.contains('success');
  }

  bool get _isOnlineMethod {
    final s =
        (order.payment?.paymentSystem ?? order.paymentMethod ?? '').toLowerCase();
    return s.contains('online') ||
        s.contains('yookassa') ||
        s.contains('card') ||
        s.contains('sbp');
  }

  bool get _paidOnline => _isPaid && _isOnlineMethod;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final paidColor = Colors.green.shade600;
    final paid = order.payment?.amount ?? 0;
    final fullyPaid = _isPaid && paid >= (order.totalPrice ?? 0);
    Color borderColor = theme.dividerColor;
    double borderWidth = 1;
    if (order.isActive) {
      borderColor = fullyPaid ? Colors.green.shade600 : Colors.amber.shade700;
      borderWidth = 2;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: borderWidth),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Заказ ${order.displayNumber}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.status,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 16,
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${order.customerName ?? '—'} · ${order.customerPhone ?? ''}',
                        style: theme.textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _isPaid
                            ? paidColor.withValues(alpha: 0.15)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _isPaid ? 'Оплачен' : order.paymentLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _isPaid
                              ? paidColor
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Состав:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _itemsSummary,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Итого: ${order.totalPrice ?? 0} ₽',
                        style: theme.textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [

                        if (order.isActive &&
                            !fullyPaid &&
                            onMarkPaid != null &&
                            !_paidOnline)
                          FilledButton.icon(
                            onPressed: onMarkPaid,
                            icon: const Icon(Icons.payments_outlined, size: 18),
                            label: const Text('Оплачено'),
                          ),
                        if (_isPaid && onRefund != null)
                          OutlinedButton(
                            onPressed: onRefund,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: theme.colorScheme.error,
                            ),
                            child: const Text('Возврат'),
                          ),

                        if (!_isPaid &&
                            birthdayPromoActive &&
                            onBirthdayToggle != null)
                          OutlinedButton.icon(
                            onPressed: onBirthdayToggle,
                            icon: const Icon(Icons.cake_outlined, size: 18),
                            label: const Text('Скидка ДР'),
                          ),
                        if (onEdit != null)
                          ElevatedButton(
                            onPressed: onEdit,
                            child: const Text('Изменить'),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
