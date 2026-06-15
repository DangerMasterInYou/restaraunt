import 'package:flutter/material.dart';

import '/core/utils/responsive.dart';
import 'package:get_it/get_it.dart';

import '/core/repositories/users/admin/admin_management.dart';
import '/core/repositories/users/client/restaraunt/orders/dto/dto.dart';
import '/core/widgets/order_detail_dialog.dart';

class OrdersAdminDialog extends StatefulWidget {
  const OrdersAdminDialog({super.key});

  @override
  State<OrdersAdminDialog> createState() => _OrdersAdminDialogState();
}

class _OrdersAdminDialogState extends State<OrdersAdminDialog> {
  final _repo = GetIt.I<AbstractAdminOrdersRepository>();
  late Future<List<OrderResponseDTO>> _future;
  String _search = '';
  String? _statusFilter;
  DateTime? _dateFilter;

  static const _statuses = [
    'Ожидает подтверждения',
    'Готовится',
    'Готов к выдаче',
    'Завершен',
    'Отменен',
  ];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _repo.getAllOrders();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
      setState(_reload);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  bool _match(OrderResponseDTO o) {
    if (_statusFilter != null && o.status != _statusFilter) return false;
    if (_dateFilter != null && !_sameDay(o.createdAt.toLocal(), _dateFilter!)) {
      return false;
    }
    if (_search.isEmpty) return true;
    final q = _search;
    if (o.id.toString().contains(q)) return true;
    if (o.displayNumber.toLowerCase().contains(q)) return true;
    if ((o.totalPrice ?? 0).toString().contains(q)) return true;
    return o.items.any((i) =>
        '${i.productVariant.product.name} ${i.productVariant.name}'
            .toLowerCase()
            .contains(q));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text('Заказы', style: theme.textTheme.titleMedium),
      content: SizedBox(
        width: dialogBodyWidth(context, max: 560),
        height: dialogBodyHeight(context, max: 480),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                hintText: 'Поиск: № заказа, сумма, состав',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                const Text('Статус: '),
                Expanded(
                  child: DropdownButton<String?>(
                    value: _statusFilter,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(12),
                    hint: const Text('Все'),
                    items: [
                      const DropdownMenuItem<String?>(
                          value: null, child: Text('Все')),
                      ..._statuses.map((s) =>
                          DropdownMenuItem<String?>(value: s, child: Text(s))),
                    ],
                    onChanged: (v) => setState(() => _statusFilter = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                const Text('Дата: '),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_dateFilter == null
                        ? 'Любая'
                        : '${_dateFilter!.day.toString().padLeft(2, '0')}.${_dateFilter!.month.toString().padLeft(2, '0')}.${_dateFilter!.year}'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dateFilter ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _dateFilter = picked);
                      }
                    },
                  ),
                ),
                if (_dateFilter != null)
                  IconButton(
                    tooltip: 'Сбросить дату',
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _dateFilter = null),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<OrderResponseDTO>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Ошибка: ${snap.error}'));
                  }
                  final orders =
                      (snap.data ?? []).where(_match).toList();
                  if (orders.isEmpty) {
                    return const Center(child: Text('Нет заказов'));
                  }
                  return ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, i) {
                      final o = orders[i];
                      return Card(
                        child: InkWell(

                          onTap: () => OrderDetailDialog.show(context, o),
                          child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Заказ ${o.displayNumber} · ${o.totalPrice ?? 0} ₽',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Удалить',
                                    icon: Icon(Icons.delete,
                                        color: theme.colorScheme.error),
                                    onPressed: () =>
                                        _guard(() => _repo.deleteOrder(o.id)),
                                  ),
                                ],
                              ),
                              Text(
                                '${o.customerName ?? '—'} · ${o.customerPhone ?? ''}',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                o.items
                                    .map((it) =>
                                        '${it.productVariant.product.name} (${it.productVariant.name})×${it.quantity}')
                                    .join(', '),
                                style: theme.textTheme.bodySmall,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Text('Статус: '),
                                  DropdownButton<String>(
                                    value: _statuses.contains(o.status)
                                        ? o.status
                                        : _statuses.first,
                                    borderRadius: BorderRadius.circular(12),
                                    items: _statuses
                                        .map((s) => DropdownMenuItem(
                                            value: s, child: Text(s)))
                                        .toList(),
                                    onChanged: (s) {
                                      if (s != null && s != o.status) {
                                        _guard(
                                            () => _repo.setStatus(o.id, s));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}
