import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '/core/hive/models/menu/menu.dart';
import '/core/repositories/restaraunt/menu/repository/abstract_menu.dart';
import '/core/services/app_toast.dart';
import '/core/utils/responsive.dart';

class OperatorCreateOrderDialog extends StatefulWidget {
  const OperatorCreateOrderDialog({super.key});

  @override
  State<OperatorCreateOrderDialog> createState() =>
      _OperatorCreateOrderDialogState();
}

class _OperatorCreateOrderDialogState extends State<OperatorCreateOrderDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _comment = TextEditingController();
  final String _payment = 'cash';

  final _phoneMask = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {'#': RegExp(r'[0-9]')},
  );

  late Future<List<Menu>> _menuFuture;
  List<Menu> _menu = [];

  final Map<int, int> _qty = {};

  final Map<int, Set<int>> _modifiers = {};

  int _modifiersPrice(Menu m) {
    final selected = _modifiers[m.id];
    if (selected == null || selected.isEmpty) return 0;
    var sum = 0;
    for (final g in m.modifierGroups) {
      for (final mod in g.modifiers) {
        if (selected.contains(mod.id)) sum += mod.priceDelta;
      }
    }
    return sum;
  }

  List<Modifier> _allModifiers(Menu m) =>
      [for (final g in m.modifierGroups) ...g.modifiers];

  List<Modifier> _selectedModifiers(Menu m) {
    final selected = _modifiers[m.id] ?? {};
    return _allModifiers(m).where((mod) => selected.contains(mod.id)).toList();
  }

  Future<void> _editModifiers(Menu m) async {
    final all = _allModifiers(m);
    if (all.isEmpty) {
      AppToast.info(context, 'У позиции нет модификаторов');
      return;
    }
    final current = {...(_modifiers[m.id] ?? <int>{})};
    var query = '';
    final result = await showDialog<Set<int>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {

          final filtered = all
              .where((mod) =>
                  mod.name.toLowerCase().contains(query.toLowerCase()))
              .toList();
          return AlertDialog(
            title: Text('Добавки: ${m.name}'),
            content: SizedBox(
              width: dialogBodyWidth(ctx, max: 380),
              height: dialogBodyHeight(ctx, max: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Поиск добавки',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => setLocal(() => query = v),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(child: Text('Ничего не найдено'))
                        : ListView(
                            children: filtered
                                .map((mod) => CheckboxListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(mod.name),
                                      subtitle: mod.priceDelta != 0
                                          ? Text('+${mod.priceDelta} ₽')
                                          : null,
                                      value: current.contains(mod.id),
                                      onChanged: (v) => setLocal(() {
                                        if (v == true) {
                                          current.add(mod.id);
                                        } else {
                                          current.remove(mod.id);
                                        }
                                      }),
                                    ))
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, current),
              child: const Text('Готово'),
            ),
          ],
          );
        },
      ),
    );
    if (result != null) {
      setState(() => _modifiers[m.id] = result);
    }
  }

  @override
  void initState() {
    super.initState();
    _menuFuture = GetIt.I<AbstractMenuRepository>().getMenuList();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _comment.dispose();
    super.dispose();
  }

  int get _total {
    var sum = 0;
    for (final m in _menu) {
      final q = _qty[m.id] ?? 0;

      if (q > 0) sum += (m.price + _modifiersPrice(m)) * q;
    }
    return sum;
  }

  String _label(Menu m) {
    final size = (m.value != null && m.unit != null) ? ' ${m.value} ${m.unit}' : '';
    return '${m.name}$size — ${m.price} ₽';
  }

  Future<void> _addItem() async {
    final available =
        _menu.where((m) => (_qty[m.id] ?? 0) == 0).toList();
    if (available.isEmpty) return;
    var query = '';
    final picked = await showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final filtered = available
              .where((m) => _label(m).toLowerCase().contains(query.toLowerCase()))
              .toList();
          return AlertDialog(
            title: const Text('Выберите позицию'),
            content: SizedBox(
              width: dialogBodyWidth(ctx, max: 420),
              height: dialogBodyHeight(ctx, max: 420),
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Поиск',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => setLocal(() => query = v),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: filtered
                          .map((m) => ListTile(
                                title: Text(_label(m)),
                                onTap: () => Navigator.pop(ctx, m.id),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (picked != null) setState(() => _qty[picked] = 1);
  }

  void _submit() {
    final items = _qty.entries
        .where((e) => e.value > 0)
        .map((e) => {
              'product_variant_id': e.key,
              'quantity': e.value,

              'modifier_ids': (_modifiers[e.key] ?? <int>{}).toList(),
            })
        .toList();
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      AppToast.error(context, 'Укажите имя и телефон клиента');
      return;
    }
    if (items.isEmpty) {
      AppToast.error(context, 'Добавьте хотя бы одну позицию');
      return;
    }
    Navigator.of(context).pop({
      'customer_name': _name.text.trim(),
      'customer_phone': _phone.text.trim(),
      'comment': _comment.text.trim().isEmpty ? null : _comment.text.trim(),
      'payment_method': _payment,
      'items': items,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Новый заказ'),
      content: SizedBox(
        width: dialogBodyWidth(context, max: 460),
        child: FutureBuilder<List<Menu>>(
          future: _menuFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                  height: 120, child: Center(child: CircularProgressIndicator()));
            }
            _menu = snap.data ?? [];
            final selected = _menu.where((m) => (_qty[m.id] ?? 0) > 0).toList();
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Имя клиента'),
                  ),
                  TextField(
                    controller: _phone,
                    decoration: const InputDecoration(
                      labelText: 'Телефон',
                      hintText: '+7 (___) ___-__-__',
                    ),
                    keyboardType: TextInputType.phone,

                    inputFormatters: [_phoneMask],
                  ),
                  TextField(
                    controller: _comment,
                    decoration:
                        const InputDecoration(labelText: 'Комментарий'),
                  ),
                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Оплата: наличные при получении',
                        style: theme.textTheme.bodyMedium),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Состав', style: theme.textTheme.titleMedium),
                      TextButton.icon(
                        onPressed: _addItem,
                        icon: const Icon(Icons.add),
                        label: const Text('Позиция'),
                      ),
                    ],
                  ),
                  ...selected.map((m) {
                    final mods = _selectedModifiers(m);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(_label(m))),
                              IconButton(
                                tooltip: 'Добавки',
                                icon: const Icon(Icons.tune),
                                onPressed: () => _editModifiers(m),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => setState(() {
                                  final q = (_qty[m.id] ?? 1) - 1;
                                  if (q <= 0) {
                                    _qty.remove(m.id);
                                    _modifiers.remove(m.id);
                                  } else {
                                    _qty[m.id] = q;
                                  }
                                }),
                              ),
                              Text('${_qty[m.id] ?? 0}'),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => setState(
                                    () => _qty[m.id] = (_qty[m.id] ?? 0) + 1),
                              ),
                            ],
                          ),
                          if (mods.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 4),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: -8,
                                children: mods
                                    .map((mod) => Chip(
                                          label: Text(
                                            mod.priceDelta != 0
                                                ? '${mod.name} +${mod.priceDelta}₽'
                                                : mod.name,
                                          ),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        ))
                                    .toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  Text('Итого: $_total ₽',
                      style: theme.textTheme.titleMedium),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Создать')),
      ],
    );
  }
}
