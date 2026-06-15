import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'image_picker_field.dart';

class ProductCrudDialog extends StatefulWidget {
  final int? initialCategoryId;
  final String? initialName;
  final String? initialDescription;
  final int? initialSortOrder;
  final String? initialImageUrl;
  final List<dynamic> categories;
  final void Function(int categoryId, String name, String? description,
      int sortOrder, String imageUrl) onSubmit;
  final void Function()? onHardDelete;
  final bool isEdit;

  const ProductCrudDialog({
    super.key,
    this.initialCategoryId,
    this.initialName,
    this.initialDescription,
    this.initialSortOrder,
    this.initialImageUrl,
    this.categories = const [],
    required this.onSubmit,
    this.onHardDelete,
    this.isEdit = false,
  });

  @override
  State<ProductCrudDialog> createState() => _ProductCrudDialogState();
}

class _ProductCrudDialogState extends State<ProductCrudDialog> {
  late TextEditingController categoryIdController;
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController sortOrderController;
  late TextEditingController imageUrlController;

  @override
  void initState() {
    super.initState();
    categoryIdController =
        TextEditingController(text: widget.initialCategoryId?.toString() ?? '');
    nameController = TextEditingController(text: widget.initialName ?? '');
    descriptionController =
        TextEditingController(text: widget.initialDescription ?? '');
    sortOrderController =
        TextEditingController(text: widget.initialSortOrder?.toString() ?? '');
    imageUrlController =
        TextEditingController(text: widget.initialImageUrl ?? '');
  }

  @override
  void dispose() {
    categoryIdController.dispose();
    nameController.dispose();
    descriptionController.dispose();
    sortOrderController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Редактировать продукт' : 'Создать продукт'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: widget.initialCategoryId,
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
              decoration: const InputDecoration(
                labelText: 'Категория',
              ),
              items: widget.categories.map((category) {
                return DropdownMenuItem<int>(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  categoryIdController.text = value?.toString() ?? '';
                });
              },
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Название',
              ),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание (опционально)',
              ),
            ),
            TextField(
              controller: sortOrderController,
              decoration: const InputDecoration(
                labelText: 'Порядок сортировки',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),

            ImagePickerField(
              imageUrl: imageUrlController.text.isEmpty
                  ? null
                  : imageUrlController.text,
              onChanged: (url) =>
                  setState(() => imageUrlController.text = url),
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
            final categoryId = int.tryParse(categoryIdController.text.trim());
            final name = nameController.text.trim();
            final description = descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim();
            final sortOrder = int.tryParse(sortOrderController.text.trim());
            final imageUrl = imageUrlController.text.trim().isEmpty
                ? null
                : imageUrlController.text.trim();
            if (categoryId == null || name.isEmpty || sortOrder == null) {
              return;
            }
            widget.onSubmit(
                categoryId, name, description, sortOrder, imageUrl ?? '');
            Navigator.of(context).pop();
          },
          child: Text(widget.isEdit ? 'Сохранить' : 'Создать'),
        ),
      ],
    );
  }
}
