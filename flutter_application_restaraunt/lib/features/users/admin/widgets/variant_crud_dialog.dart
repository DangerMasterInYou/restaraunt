import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'image_picker_field.dart';
import 'searchable_dropdown.dart';

class VariantCrudDialog extends StatefulWidget {
  final int? initialProductId;
  final String? initialName;
  final int? initialPrice;
  final String? initialSku;
  final bool? initialIsAvailable;
  final bool? initialIsCombo;
  final String? initialDescription;
  final String? initialImageUrl;
  final int? initialValue;
  final String? initialUnit;
  final List<dynamic> products;
  final void Function(
      {required int productId,
      required String name,
      required int price,
      required String sku,
      required bool isAvailable,
      required bool isCombo,
      String? description,
      String? imageUrl,
      int? value,
      String? unit}) onSubmit;
  final void Function()? onHardDelete;
  final bool isEdit;

  const VariantCrudDialog({
    super.key,
    this.initialProductId,
    this.initialName,
    this.initialPrice,
    this.initialSku,
    this.initialIsAvailable,
    this.initialIsCombo,
    this.initialDescription,
    this.initialImageUrl,
    this.initialValue,
    this.initialUnit,
    this.products = const [],
    required this.onSubmit,
    this.onHardDelete,
    this.isEdit = false,
  });

  @override
  State<VariantCrudDialog> createState() => _VariantCrudDialogState();
}

class _VariantCrudDialogState extends State<VariantCrudDialog> {
  late TextEditingController productIdController;
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController skuController;
  late TextEditingController descriptionController;
  late TextEditingController imageUrlController;
  late TextEditingController valueController;
  String? selectedUnit;
  bool isAvailable = false;
  bool isCombo = false;

  @override
  void initState() {
    super.initState();
    productIdController =
        TextEditingController(text: widget.initialProductId?.toString() ?? '');
    nameController = TextEditingController(text: widget.initialName ?? '');
    priceController =
        TextEditingController(text: widget.initialPrice?.toString() ?? '');
    skuController = TextEditingController(text: widget.initialSku ?? '');
    descriptionController =
        TextEditingController(text: widget.initialDescription ?? '');
    imageUrlController =
        TextEditingController(text: widget.initialImageUrl ?? '');
    valueController =
        TextEditingController(text: widget.initialValue?.toString() ?? '');
    selectedUnit = const ['гр', 'мл'].contains(widget.initialUnit)
        ? widget.initialUnit
        : null;
    isAvailable = widget.initialIsAvailable ?? false;
    isCombo = widget.initialIsCombo ?? false;
  }

  @override
  void dispose() {
    productIdController.dispose();
    nameController.dispose();
    priceController.dispose();
    skuController.dispose();
    descriptionController.dispose();
    imageUrlController.dispose();
    valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Редактировать вариант' : 'Создать вариант'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            SearchableDropdown<int>(
              label: 'Продукт',
              value: int.tryParse(productIdController.text),
              options: widget.products
                  // Продукты с комбо-вариантом скрываем при выборе, но текущий
                  // продукт варианта всегда оставляем видимым (иначе при
                  // редактировании комбо-варианта список «Продукт» пустеет).
                  .where((p) =>
                      p.id == int.tryParse(productIdController.text) ||
                      !p.variants.any((v) => v.isCombo == true))
                  .map<DropdownOption<int>>(
                      (p) => DropdownOption(p.id as int, p.name as String))
                  .toList(),
              onChanged: (v) =>
                  setState(() => productIdController.text = v.toString()),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Название',
              ),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Цена',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            TextField(
              controller: skuController,
              decoration: const InputDecoration(
                labelText: 'SKU',
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: isAvailable,
                  onChanged: (val) =>
                      setState(() => isAvailable = val ?? false),
                ),
                const Text('Доступен'),
                Checkbox(
                  value: isCombo,
                  onChanged: (val) => setState(() => isCombo = val ?? false),
                ),
                const Text('Комбо'),
              ],
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание (опционально)',
              ),
            ),

            ImagePickerField(
              imageUrl: imageUrlController.text.isEmpty
                  ? null
                  : imageUrlController.text,
              onChanged: (url) =>
                  setState(() => imageUrlController.text = url),
            ),
            TextField(
              controller: valueController,
              decoration: const InputDecoration(
                labelText: 'Значение (value, опционально)',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            DropdownButtonFormField<String>(
              initialValue: selectedUnit,
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
              decoration: const InputDecoration(
                labelText: 'Единица измерения (unit, опционально)',
              ),
              items: const [
                DropdownMenuItem(value: 'гр', child: Text('гр')),
                DropdownMenuItem(value: 'мл', child: Text('мл')),
              ],
              onChanged: (value) => setState(() => selectedUnit = value),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.isEdit && widget.onHardDelete != null)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: widget.onHardDelete,
            child: const Text('Удалить безвозвратно'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            final productId = int.tryParse(productIdController.text.trim());
            final name = nameController.text.trim();
            final price = int.tryParse(priceController.text.trim());
            final sku = skuController.text.trim();
            final description = descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim();
            final imageUrl = imageUrlController.text.trim().isEmpty
                ? null
                : imageUrlController.text.trim();
            final value = valueController.text.trim().isEmpty
                ? null
                : int.tryParse(valueController.text.trim());
            final unit = selectedUnit;
            if (productId == null ||
                name.isEmpty ||
                price == null ||
                sku.isEmpty) {
              return;
            }
            widget.onSubmit(
              productId: productId,
              name: name,
              price: price,
              sku: sku,
              isAvailable: isAvailable,
              isCombo: isCombo,
              description: description,
              imageUrl: imageUrl,
              value: value,
              unit: unit,
            );
            Navigator.of(context).pop();
          },
          child: Text(widget.isEdit ? 'Сохранить' : 'Создать'),
        ),
      ],
    );
  }
}
