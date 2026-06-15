import 'package:flutter/material.dart';

import '/core/utils/responsive.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import 'searchable_dropdown.dart';

import '/core/repositories/users/admin/restaraunt/product_full/combo_bundle/dto/combo_item_response.dart';
import '/core/repositories/users/admin/restaraunt/product_full/combo_bundle/repository/combo_items.dart';
import '/core/repositories/users/admin/restaraunt/product_full/product_variant/dto/response.dart';

class ComboItemsDialog extends StatefulWidget {
  const ComboItemsDialog({
    super.key,
    required this.comboVariantId,
    required this.comboVariantName,
    required this.allVariants,
    required this.onChanged,
    this.productNames = const {},
  });

  final int comboVariantId;
  final String comboVariantName;
  final List<VariantResponse> allVariants;
  final VoidCallback onChanged;

  final Map<int, String> productNames;

  String variantLabel(VariantResponse v) {
    final product = productNames[v.productId];
    final base = product != null ? '$product — ${v.name}' : v.name;
    return '$base (${v.price} ₽)';
  }

  @override
  State<ComboItemsDialog> createState() => _ComboItemsDialogState();
}

class _ComboItemsDialogState extends State<ComboItemsDialog> {
  final _repo = GetIt.I<AbstractComboItemsRepository>();
  List<ComboItemResponse> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repo.getComboItems(widget.comboVariantId);
      if (mounted) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _addItem() async {
    final available = widget.allVariants
        .where((v) =>
            v.id != widget.comboVariantId &&
            !_items.any((i) => i.includedVariant.id == v.id))
        .toList();
    if (available.isEmpty) return;

    int? selectedId = available.first.id;
    final quantityController = TextEditingController(text: '1');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Добавить в комбо'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SearchableDropdown<int>(
                label: 'Товар',
                value: selectedId,
                options: available
                    .map((v) => DropdownOption(v.id, widget.variantLabel(v)))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedId = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Количество'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selectedId == null) return;

    final quantity = int.tryParse(quantityController.text.trim()) ?? 1;
    await _repo.addComboItem(
      widget.comboVariantId,
      ComboItemCreateDTO(includedVariantId: selectedId!, quantity: quantity),
    );
    widget.onChanged();
    await _load();
  }

  String _composedTitle(ComboItemVariantDTO iv) {
    for (final v in widget.allVariants) {
      if (v.id == iv.id) {
        final product = widget.productNames[v.productId];
        if (product != null) return '$product — ${iv.name}';
        break;
      }
    }
    return iv.name;
  }

  Future<void> _removeItem(int includedVariantId) async {
    await _repo.removeComboItem(widget.comboVariantId, includedVariantId);
    widget.onChanged();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Состав комбо: ${widget.comboVariantName}'),
      content: SizedBox(
        width: dialogBodyWidth(context, max: 400),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Text('Ошибка: $_error')
                : _items.isEmpty
                    ? const Text('Комбо пока пусто')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return ListTile(

                            title: Text(_composedTitle(item.includedVariant)),
                            subtitle: Text('${item.includedVariant.price} ₽'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('×${item.quantity}'),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 20),
                                  onPressed: () => _removeItem(
                                    item.includedVariant.id,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
      actions: [
        TextButton(
          onPressed: _addItem,
          child: const Text('Добавить позицию'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}
