import 'package:flutter/material.dart';

import '/core/utils/responsive.dart';
import 'package:get_it/get_it.dart';

import '/core/repositories/promotions/promotion.dart';
import '/core/repositories/users/admin/restaraunt/product_full/product_full.dart';
import 'searchable_dropdown.dart';

class PromotionsAdminDialog extends StatefulWidget {
  const PromotionsAdminDialog({super.key});

  @override
  State<PromotionsAdminDialog> createState() => _PromotionsAdminDialogState();
}

class _PromotionsAdminDialogState extends State<PromotionsAdminDialog> {
  final _repo = GetIt.I<AbstractPromotionsRepository>();
  late Future<List<PromotionDTO>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _repo.getAll();
  }

  Future<void> _openForm([PromotionDTO? existing]) async {
    final result = await showDialog<PromotionDTO>(
      context: context,
      builder: (_) => _PromotionForm(initial: existing),
    );
    if (result == null) return;
    try {
      if (existing?.id != null) {
        await _repo.update(existing!.id!, result);
      } else {
        await _repo.create(result);
      }
      setState(_reload);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _delete(PromotionDTO promo) async {
    if (promo.id == null) return;
    try {
      await _repo.delete(promo.id!);
      setState(_reload);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Акции', style: theme.textTheme.titleMedium),
          IconButton(
            tooltip: 'Добавить акцию',
            icon: const Icon(Icons.add),
            onPressed: () => _openForm(),
          ),
        ],
      ),
      content: SizedBox(
        width: dialogBodyWidth(context, max: 460),
        height: dialogBodyHeight(context, max: 420),
        child: FutureBuilder<List<PromotionDTO>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Ошибка: ${snapshot.error}'));
            }
            final promos = snapshot.data ?? const [];
            if (promos.isEmpty) {
              return const Center(child: Text('Акций пока нет'));
            }
            return ListView.builder(
              itemCount: promos.length,
              itemBuilder: (context, i) {
                final p = promos[i];
                return Card(
                  child: ListTile(
                    title: Text(p.title),
                    subtitle: Text(
                      '${p.discountLabel ?? p.promoType} · '
                      '${_targetLabel(p)}${p.isActive ? '' : ' · выкл'}',
                      style: theme.textTheme.bodySmall,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _openForm(p),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete,
                              color: theme.colorScheme.error),
                          onPressed: () => _delete(p),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
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

  String _targetLabel(PromotionDTO p) {
    switch (p.targetType) {
      case 'category':
        return 'категория #${p.targetId}';
      case 'product':
        return 'продукт #${p.targetId}';
      default:
        return 'всё меню';
    }
  }
}

class _PromotionForm extends StatefulWidget {
  const _PromotionForm({this.initial});
  final PromotionDTO? initial;

  @override
  State<_PromotionForm> createState() => _PromotionFormState();
}

class _PromotionFormState extends State<_PromotionForm> {
  late TextEditingController _title;
  late TextEditingController _description;
  late TextEditingController _label;
  late TextEditingController _value;
  late TextEditingController _minAmount;
  String _promoType = 'percent';
  String _targetType = 'all';
  int? _targetId;
  List<CategoryResponse> _categories = [];
  List<ProductResponse> _products = [];
  String? _startDate;
  String? _endDate;
  String? _startTime;
  String? _endTime;
  final Set<int> _days = {};
  bool _isActive = true;
  bool _isBirthday = false;

  static const _dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _title = TextEditingController(text: p?.title ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _label = TextEditingController(text: p?.discountLabel ?? '');
    _value = TextEditingController(text: p?.discountValue?.toString() ?? '');
    _minAmount =
        TextEditingController(text: p?.minOrderAmount?.toString() ?? '');
    _targetId = p?.targetId;
    _promoType = p?.promoType ?? 'percent';
    _targetType = p?.targetType ?? 'all';
    _loadTargets();
    _startDate = p?.startDate;
    _endDate = p?.endDate;
    _startTime = p?.startTime;
    _endTime = p?.endTime;
    _isActive = p?.isActive ?? true;
    _isBirthday = p?.isBirthday ?? false;
    if (p?.daysOfWeek != null) {
      for (final d in p!.daysOfWeek!.split(',')) {
        final n = int.tryParse(d);
        if (n != null) _days.add(n);
      }
    }
  }

  Future<void> _loadTargets() async {
    try {
      final cats = await GetIt.I<CategoriesRepository>().getCategoryList();
      final prods = await GetIt.I<ProductRepository>().getProductList();
      if (mounted) {
        setState(() {
          _categories = cats;
          _products = prods;
        });
      }
    } catch (_) {

    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _label.dispose();
    _value.dispose();
    _minAmount.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    final s =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() => isStart ? _startDate = s : _endDate = s);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked == null) return;
    final s =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() => isStart ? _startTime = s : _endTime = s);
  }

  TextStyle? _fieldStyle(ThemeData theme) =>
      theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.normal);

  void _submit() {
    if (_title.text.trim().isEmpty) return;
    final dto = PromotionDTO(
      id: widget.initial?.id,
      title: _title.text.trim(),
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      discountLabel: _label.text.trim().isEmpty ? null : _label.text.trim(),
      promoType: _promoType,
      discountValue: int.tryParse(_value.text.trim()),
      targetType: _targetType,
      targetId: _targetType == 'all' ? null : _targetId,
      minOrderAmount: int.tryParse(_minAmount.text.trim()),
      startDate: _startDate,
      endDate: _endDate,
      startTime: _startTime,
      endTime: _endTime,
      daysOfWeek: _days.isEmpty
          ? null
          : (_days.toList()..sort()).join(','),
      isActive: _isActive,
      isBirthday: _isBirthday,
    );
    Navigator.of(context).pop(dto);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.initial == null ? 'Новая акция' : 'Редактирование акции',
          style: theme.textTheme.titleMedium),
      content: SizedBox(
        width: dialogBodyWidth(context, max: 460),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _title,
                style: _fieldStyle(theme),
                decoration: const InputDecoration(labelText: 'Название'),
              ),
              TextField(
                controller: _description,
                style: _fieldStyle(theme),
                decoration: const InputDecoration(labelText: 'Описание'),
                maxLines: 2,
              ),
              TextField(
                controller: _label,
                style: _fieldStyle(theme),
                decoration: const InputDecoration(
                    labelText: 'Подпись скидки (2+2=5, -10%)'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _promoType,
                      borderRadius: BorderRadius.circular(12),
                      style: _fieldStyle(theme),
                      decoration:
                          const InputDecoration(labelText: 'Тип скидки'),
                      items: const [
                        DropdownMenuItem(
                            value: 'percent', child: Text('Проценты')),
                        DropdownMenuItem(
                            value: 'fixed', child: Text('Сумма ₽')),
                      ],
                      onChanged: (v) =>
                          setState(() => _promoType = v ?? 'percent'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _value,
                      keyboardType: TextInputType.number,
                      style: _fieldStyle(theme),
                      decoration:
                          const InputDecoration(labelText: 'Значение'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              TextField(
                controller: _minAmount,
                keyboardType: TextInputType.number,
                style: _fieldStyle(theme),
                decoration: const InputDecoration(
                  labelText: 'Мин. сумма заказа, ₽ (необязательно)',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _targetType,
                      borderRadius: BorderRadius.circular(12),
                      style: _fieldStyle(theme),
                      decoration: const InputDecoration(labelText: 'Цель'),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Всё меню')),
                        DropdownMenuItem(
                            value: 'category', child: Text('Категория')),
                        DropdownMenuItem(
                            value: 'product', child: Text('Продукт')),
                      ],
                      onChanged: (v) => setState(() {
                        _targetType = v ?? 'all';
                        _targetId = null;
                      }),
                    ),
                  ),
                  if (_targetType == 'category') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: SearchableDropdown<int>(
                        label: 'Категория',
                        value: _targetId,
                        options: _categories
                            .map((c) => DropdownOption(c.id, c.name))
                            .toList(),
                        onChanged: (v) => setState(() => _targetId = v),
                      ),
                    ),
                  ],
                  if (_targetType == 'product') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: SearchableDropdown<int>(
                        label: 'Продукт',
                        value: _targetId,
                        options: _products
                            .map((p) => DropdownOption(p.id, p.name))
                            .toList(),
                        onChanged: (v) => setState(() => _targetId = v),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text('Условия', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(true),
                      child: Text('С: ${_startDate ?? '—'}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickDate(false),
                      child: Text('По: ${_endDate ?? '—'}'),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(true),
                      child: Text('Время с: ${_startTime ?? '—'}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(false),
                      child: Text('по: ${_endTime ?? '—'}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: List.generate(7, (i) {
                  final selected = _days.contains(i);
                  return FilterChip(
                    label: Text(_dayNames[i]),
                    selected: selected,
                    onSelected: (v) => setState(
                        () => v ? _days.add(i) : _days.remove(i)),
                  );
                }),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Активна'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Только в день рождения'),
                subtitle: const Text(
                    'Скидка применится лишь если у клиента указан ДР и сегодня он'),
                value: _isBirthday,
                onChanged: (v) => setState(() => _isBirthday = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
