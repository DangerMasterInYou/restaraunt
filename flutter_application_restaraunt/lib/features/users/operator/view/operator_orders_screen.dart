import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_application_restaraunt/core/repositories/users/client/restaraunt/orders/dto/response.dart';
import 'package:flutter_application_restaraunt/core/router/router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '/core/repositories/users/operator/orders/operator_orders_repository.dart';
import '/core/widgets/order_detail_dialog.dart';
import '/core/widgets/reviews_dialog.dart';
import '/core/utils/responsive.dart';
import '/features/theme/bloc/theme_bloc.dart';
import '/core/services/app_toast.dart';
import '/core/services/notification_service.dart';
import '/core/repositories/promotions/promotion.dart';
import '../bloc/operator_order_bloc.dart';
import '../widgets/operator_order_card.dart';
import '../widgets/operator_create_order_dialog.dart';

const _operatorStatuses = <String>[
  'Ожидает подтверждения',
  'Готовится',
  'Готов к выдаче',
  'Завершен',
  'Отменен',
];

const _activeFilterStatuses = <String>[
  'Ожидает подтверждения',
  'Готовится',
  'Готов к выдаче',
];

@RoutePage()
class OperatorOrdersScreen extends StatelessWidget {
  const OperatorOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OperatorOrderBloc(
        GetIt.I<AbstractOperatorOrdersRepository>(),
      )..add(StreamActiveOrders()),
      child: const _OperatorOrdersBody(),
    );
  }
}

class _OperatorOrdersBody extends StatefulWidget {
  const _OperatorOrdersBody();

  @override
  State<_OperatorOrdersBody> createState() => _OperatorOrdersBodyState();
}

class _OperatorOrdersBodyState extends State<_OperatorOrdersBody> {
  String? _statusFilter;
  String _search = '';

  bool _birthdayPromoActive = false;

  Set<int>? _knownOrderIds;

  @override
  void initState() {
    super.initState();
    _loadBirthdayPromo();
  }

  void _notifyNewOrders(List<OrderResponseDTO> orders) {
    final ids = orders.map((o) => o.id).toSet();
    if (_knownOrderIds == null) {
      _knownOrderIds = ids;
      return;
    }
    final fresh = orders.where((o) => !_knownOrderIds!.contains(o.id)).toList();
    _knownOrderIds = ids;
    for (final o in fresh) {
      NotificationService.instance.show(
        'Новый заказ ${o.displayNumber}',
        '${o.customerName ?? 'Клиент'} · ${o.totalPrice ?? 0} ₽',
        id: o.id,
      );
    }
  }

  Future<void> _loadBirthdayPromo() async {
    try {
      final promos = await GetIt.I<AbstractPromotionsRepository>().getActive();
      final active = promos.any((p) => p.isBirthday && p.isActive);
      if (mounted) setState(() => _birthdayPromoActive = active);
    } catch (_) {

    }
  }

  Future<void> _markCashPaid(
      BuildContext context, OrderResponseDTO order) async {
    final bloc = context.read<OperatorOrderBloc>();
    try {
      await GetIt.I<AbstractOperatorOrdersRepository>().markCashPaid(order.id);
      if (context.mounted) {
        AppToast.success(context, 'Заказ отмечен оплаченным');
        bloc.add(StreamActiveOrders());
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.fromError(context, e, prefix: 'Не удалось отметить оплату');
      }
    }
  }

  Future<void> _toggleBirthdayDiscount(
      BuildContext context, OrderResponseDTO order) async {
    final bloc = context.read<OperatorOrderBloc>();
    final enabled = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Скидка в день рождения'),
        content: const Text(
            'Применить или убрать скидку в день рождения для этого заказа?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Убрать'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Применить'),
          ),
        ],
      ),
    );
    if (enabled == null) return;
    try {
      await GetIt.I<AbstractOperatorOrdersRepository>()
          .setBirthdayDiscount(order.id, enabled);
      if (context.mounted) {
        AppToast.success(
            context,
            enabled
                ? 'Скидка в день рождения применена'
                : 'Скидка в день рождения убрана');
        bloc.add(StreamActiveOrders());
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.fromError(context, e, prefix: 'Не удалось изменить скидку');
      }
    }
  }

  bool _matchesSearch(OrderResponseDTO o) {
    if (_search.trim().isEmpty) return true;
    final q = _search.toLowerCase().trim();
    if (o.id.toString().contains(q)) return true;
    if (o.displayNumber.toLowerCase().contains(q)) return true;
    if ((o.totalPrice ?? 0).toString().contains(q)) return true;
    for (final item in o.items) {
      final name =
          '${item.productVariant.product.name} ${item.productVariant.name}'
              .toLowerCase();
      if (name.contains(q)) return true;
    }
    return false;
  }

  bool _isFullyPaid(OrderResponseDTO o) {
    final s = o.payment?.status.toLowerCase() ?? '';
    final paid =
        s.contains('успеш') || s.contains('success') || s.contains('paid');
    return paid && (o.payment?.amount ?? 0) >= (o.totalPrice ?? 0);
  }

  int _alreadyRefunded(OrderResponseDTO order) {
    var total = 0;
    final re = RegExp(r'возврат\s+(\d+)');
    for (final h in order.statusHistory) {
      final note = (h.note ?? '').toLowerCase();
      if (note.contains('возврат')) {
        final m = re.firstMatch(note);
        if (m != null) total += int.tryParse(m.group(1)!) ?? 0;
      }
    }
    return total;
  }

  Future<void> _refundOrder(
      BuildContext context, OrderResponseDTO order) async {
    final bloc = context.read<OperatorOrderBloc>();

    final newTotal = order.totalPrice ?? 0;
    final paid = order.payment?.amount ?? newTotal;
    final alreadyRefunded = _alreadyRefunded(order);
    final remaining = paid - alreadyRefunded;
    if (remaining <= 0) {
      AppToast.info(context, 'Заказ уже полностью возвращён');
      return;
    }

    final int difference =
        (paid - newTotal - alreadyRefunded).clamp(0, remaining).toInt();
    final amountController = TextEditingController();
    final amount = await showDialog<int?>(
      context: context,
      builder: (ctx) {
        var partial = false;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text('Возврат средств'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Заказ ${order.displayNumber}.'),
                Text('Оплачено: $paid ₽ · новая сумма: $newTotal ₽.'),
                Text('Доступно к возврату: $remaining ₽.'),
                if (difference > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.price_change_outlined),
                      label: Text('Вернуть разницу ($difference ₽)'),
                      onPressed: () => Navigator.pop(ctx, difference),
                    ),
                  ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: partial,
                  title: const Text('Частичный возврат'),
                  onChanged: (v) => setLocal(() => partial = v ?? false),
                ),
                if (partial)
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Сумма возврата, ₽ (макс. $remaining)',
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Theme.of(ctx).colorScheme.onError,
                ),
                onPressed: () {
                  if (!partial) {
                    Navigator.pop(ctx, remaining);
                    return;
                  }
                  final v = int.tryParse(amountController.text);
                  if (v == null || v <= 0 || v > remaining) {
                    AppToast.error(
                        ctx, 'Сумма должна быть от 1 до $remaining ₽');
                    return;
                  }
                  Navigator.pop(ctx, v);
                },
                child: const Text('Вернуть'),
              ),
            ],
          ),
        );
      },
    );
    if (amount == null) return;
    try {
      await GetIt.I<AbstractOperatorOrdersRepository>().refundOrder(
        order.id,
        amount: amount == remaining ? null : amount,
      );
      if (context.mounted) {
        AppToast.success(context, 'Возврат выполнен');
        bloc.add(StreamActiveOrders());
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.fromError(context, e, prefix: 'Не удалось вернуть средства');
      }
    }
  }

  Future<void> _showArchive(BuildContext context) async {
    final future =
        GetIt.I<AbstractOperatorOrdersRepository>().getArchivedOrders();
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        var search = '';
        DateTime? dateFilter;
        String statusFilter = 'all';
        bool sameDay(DateTime a, DateTime b) =>
            a.year == b.year && a.month == b.month && a.day == b.day;
        return StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: const Text('Архив заказов'),
            content: SizedBox(
              width: dialogBodyWidth(ctx, max: 540),
              height: dialogBodyHeight(ctx, max: 500),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Поиск: №, сумма, состав',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => setLocal(() => search = v.toLowerCase()),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Дата: '),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(dateFilter == null
                              ? 'Любая'
                              : '${dateFilter!.day.toString().padLeft(2, '0')}.${dateFilter!.month.toString().padLeft(2, '0')}.${dateFilter!.year}'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: dateFilter ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setLocal(() => dateFilter = picked);
                            }
                          },
                        ),
                      ),
                      if (dateFilter != null)
                        IconButton(
                          tooltip: 'Сбросить дату',
                          icon: const Icon(Icons.clear),
                          onPressed: () => setLocal(() => dateFilter = null),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Text('Статус: '),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SegmentedButton<String>(
                          showSelectedIcon: false,
                          segments: const [
                            ButtonSegment(value: 'all', label: Text('Все')),
                            ButtonSegment(
                                value: 'Завершен', label: Text('Завершён')),
                            ButtonSegment(
                                value: 'Отменен', label: Text('Отменён')),
                          ],
                          selected: {statusFilter},
                          onSelectionChanged: (s) =>
                              setLocal(() => statusFilter = s.first),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: FutureBuilder<List<OrderResponseDTO>>(
                      future: future,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snap.hasError) {
                          return Center(child: Text('Ошибка: ${snap.error}'));
                        }
                        final orders = [...(snap.data ?? <OrderResponseDTO>[])]
                          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                        final filtered = orders.where((o) {
                          if (statusFilter != 'all' &&
                              !o.status
                                  .toLowerCase()
                                  .contains(statusFilter.toLowerCase())) {
                            return false;
                          }
                          if (dateFilter != null &&
                              !sameDay(o.createdAt.toLocal(), dateFilter!)) {
                            return false;
                          }
                          if (search.isEmpty) return true;
                          if (o.displayNumber.toLowerCase().contains(search)) {
                            return true;
                          }
                          if ((o.totalPrice ?? 0).toString().contains(search)) {
                            return true;
                          }
                          return o.items.any((it) =>
                              '${it.productVariant.product.name} ${it.productVariant.name}'
                                  .toLowerCase()
                                  .contains(search));
                        }).toList();
                        if (filtered.isEmpty) {
                          return const Center(child: Text('Ничего не найдено'));
                        }
                        return ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final o = filtered[i];
                            return Card(
                              child: ListTile(
                                onTap: () =>
                                    OrderDetailDialog.show(context, o),
                                title: Text('${o.displayNumber} · ${o.status}'),
                                subtitle: Text(
                                  '${_fmtDate(o.createdAt)} · ${o.totalPrice ?? 0} ₽\n'
                                  '${o.items.map((it) => '${it.productVariant.product.name}×${it.quantity}').join(', ')}',
                                  style: theme.textTheme.bodySmall,
                                ),
                                isThreeLine: true,
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
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Закрыть'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Активные заказы'),
        actions: [
          IconButton(
            tooltip: 'Сменить тему',
            icon: Icon(theme.brightness == Brightness.dark
                ? Icons.light_mode
                : Icons.dark_mode),
            onPressed: () =>
                context.read<ThemeBloc>().add(ToggleThemeEvent()),
          ),
          IconButton(
            tooltip: 'Отзывы',
            icon: const Icon(Icons.star_outline),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const ReviewsDialog(),
            ),
          ),
          IconButton(
            tooltip: 'Архив',
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => _showArchive(context),
          ),
          IconButton(
            tooltip: 'Выйти',
            icon: const Icon(Icons.logout),
            onPressed: () => context.router.replace(const LoginRoute()),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final bloc = context.read<OperatorOrderBloc>();
          final payload = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (_) => const OperatorCreateOrderDialog(),
          );
          if (payload == null) return;
          try {
            await GetIt.I<AbstractOperatorOrdersRepository>()
                .createOrder(payload);
            if (context.mounted) {
              AppToast.success(context, 'Заказ создан');
              bloc.add(StreamActiveOrders());
            }
          } catch (e) {
            if (context.mounted) {
              AppToast.fromError(context, e, prefix: 'Не удалось создать заказ');
            }
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Создать заказ'),
      ),

      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: BlocConsumer<OperatorOrderBloc, OperatorOrderState>(
        listener: (context, state) {

          if (state is OperatorOrderError && _isForbidden(state.error)) {
            context.router.replace(const LoginRoute());
          }

          if (state is OperatorOrdersLoaded) {
            _notifyNewOrders(state.activeOrders);
          }
        },
        builder: (context, state) {
          if (state is OperatorOrdersLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is OperatorOrderError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.error,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (state is OperatorOrdersLoaded) {
            final filtered = state.activeOrders
                .where((o) =>
                    (_statusFilter == null || o.status == _statusFilter) &&
                    _matchesSearch(o))
                .toList()

              ..sort((a, b) {
                final pa = _isFullyPaid(a) ? 1 : 0;
                final pb = _isFullyPaid(b) ? 1 : 0;
                if (pa != pb) return pa - pb;
                return b.createdAt.compareTo(a.createdAt);
              });
            return Column(
              children: [
                _buildSearchField(theme),
                _buildFilterBar(theme, state.activeOrders),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('Нет заказов'))
                      : RefreshIndicator(
                          onRefresh: () async {
                            context
                                .read<OperatorOrderBloc>()
                                .add(StreamActiveOrders());
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final order = filtered[index];
                              return OperatorOrderCard(
                                order: order,
                                birthdayPromoActive: _birthdayPromoActive,
                                onEdit: () => _openOrderEditor(context, order),
                                onRefund: () => _refundOrder(context, order),
                                onBirthdayToggle: () =>
                                    _toggleBirthdayDiscount(context, order),
                                onMarkPaid: () => _markCashPaid(context, order),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
            ),
          ),
        ),
      ),
    );
  }

  bool _isForbidden(String error) =>
      error.contains('403') || error.toLowerCase().contains('forbidden');

  Widget _buildSearchField(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: TextField(
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: const Icon(Icons.search),
          hintText: 'Поиск: № заказа, сумма, состав',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (v) => setState(() => _search = v),
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme, List<OrderResponseDTO> orders) {
    int countFor(String status) =>
        orders.where((o) => o.status == status).length;

    Widget chip(String status) {
      final selected = _statusFilter == status;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(
          label: Text('$status (${countFor(status)})'),
          selected: selected,
          onSelected: (_) => setState(
              () => _statusFilter = selected ? null : status),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: _activeFilterStatuses.map(chip).toList(),
      ),
    );
  }

  void _openOrderEditor(BuildContext context, OrderResponseDTO order) {
    final theme = Theme.of(context);

    final bloc = context.read<OperatorOrderBloc>();

    final qtyByItemId = {
      for (final item in order.items) item.id: item.quantity,
    };
    final removedItemIds = <int>{};

    final removedModifiers = <int, Set<int>>{};

    String selectedStatus = _operatorStatuses.contains(order.status)
        ? order.status
        : _operatorStatuses.first;
    bool isSaving = false;
    String? errorMessage;

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Заказ ${order.displayNumber}'),
              content: SizedBox(
                width: dialogBodyWidth(context, max: 440),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      _ClientInfo(order: order),
                      const Divider(height: 24),
                      Text('Статус', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        value: selectedStatus,
                        isExpanded: true,
                        items: _operatorStatuses
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => selectedStatus = v);
                        },
                      ),
                      const SizedBox(height: 16),
                      Text('Состав', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...order.items
                          .where((item) => !removedItemIds.contains(item.id))
                          .map(
                            (item) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${item.productVariant.product.name} — ${item.productVariant.name}',
                                          style: theme.textTheme.bodyMedium,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),

                                        if (item.appliedModifiers.isNotEmpty)
                                          Wrap(
                                            spacing: 4,
                                            children: item.appliedModifiers
                                                .where((m) => !((removedModifiers[
                                                            item.id] ??
                                                        const <int>{})
                                                    .contains(m.modifierId)))
                                                .map((m) => InputChip(
                                                      label: Text(m.name,
                                                          style: theme.textTheme
                                                              .labelSmall),
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                      materialTapTargetSize:
                                                          MaterialTapTargetSize
                                                              .shrinkWrap,
                                                      onDeleted: () => setState(
                                                          () => (removedModifiers[
                                                                  item.id] ??=
                                                              <int>{})
                                                            ..add(m.modifierId)),
                                                    ))
                                                .toList(),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.remove_circle_outline),
                                    onPressed: () {
                                      final current = qtyByItemId[item.id] ??
                                          item.quantity;
                                      if (current <= 1) {
                                        setState(
                                            () => removedItemIds.add(item.id));
                                        return;
                                      }
                                      setState(() =>
                                          qtyByItemId[item.id] = current - 1);
                                    },
                                  ),
                                  SizedBox(
                                    width: 36,
                                    child: Center(
                                      child: Text(
                                        '${qtyByItemId[item.id] ?? item.quantity}',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon:
                                        const Icon(Icons.add_circle_outline),
                                    onPressed: () {
                                      final current = qtyByItemId[item.id] ??
                                          item.quantity;
                                      setState(() =>
                                          qtyByItemId[item.id] = current + 1);
                                    },
                                  ),
                                  IconButton(
                                    tooltip: 'Удалить позицию',
                                    icon: Icon(Icons.delete_outline,
                                        color: theme.colorScheme.error),
                                    onPressed: () => setState(
                                        () => removedItemIds.add(item.id)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      if (removedItemIds.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => setState(removedItemIds.clear),
                          icon: const Icon(Icons.undo),
                          label: Text(
                            'Вернуть удалённые (${removedItemIds.length})',
                          ),
                        ),
                      ],

                      if (order.statusHistory.isNotEmpty) ...[
                        const Divider(height: 24),
                        Text('История заказа',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ...order.statusHistory.map(
                          (h) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.history,
                                    size: 16,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${_fmtDate(h.createdAt)} — ${h.note ?? h.status}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          errorMessage!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final itemsPayload = order.items
                              .where(
                                  (item) => !removedItemIds.contains(item.id))
                              .map((item) {
                            final payload = <String, dynamic>{
                              'product_variant_id': item.productVariant.id,
                              'quantity':
                                  qtyByItemId[item.id] ?? item.quantity,
                            };

                            final removed =
                                removedModifiers[item.id] ?? const <int>{};
                            final modIds = item.appliedModifiers
                                .where((m) => !removed.contains(m.modifierId))
                                .map((m) => m.modifierId)
                                .toList();
                            if (modIds.isNotEmpty) {
                              payload['modifier_ids'] = modIds;
                            }
                            return payload;
                          }).toList();

                          if (itemsPayload.isEmpty) {
                            setState(() {
                              errorMessage =
                                  'Заказ не может быть пустым. Удалите весь заказ через статус «Отменен».';
                            });
                            return;
                          }

                          setState(() {
                            isSaving = true;
                            errorMessage = null;
                          });

                          final completer = Completer<void>();
                          bloc.add(
                            SaveOperatorOrderChanges(
                              orderId: order.id,
                              items: itemsPayload,
                              status: selectedStatus,
                              completer: completer,
                            ),
                          );

                          try {
                            await completer.future;
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            setState(() {
                              isSaving = false;
                              errorMessage = e.toString();
                            });
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

String _fmtDate(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
}

class _ClientInfo extends StatelessWidget {
  const _ClientInfo({required this.order});
  final OrderResponseDTO order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Клиент', style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(order.customerName ?? '—', style: theme.textTheme.bodyLarge),
        Text(order.customerPhone ?? '—', style: theme.textTheme.bodyMedium),
        if (order.comment != null && order.comment!.isNotEmpty)
          Text('Комментарий: ${order.comment}',
              style: theme.textTheme.bodyMedium),
        Text('Оплата: ${order.paymentLabel}',
            style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
