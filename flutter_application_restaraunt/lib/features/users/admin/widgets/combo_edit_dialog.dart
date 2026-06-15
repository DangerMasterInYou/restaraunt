import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'image_picker_field.dart';

class ComboEditDialog extends StatefulWidget {
  final String initialName;
  final int? initialPrice;
  final String? initialImageUrl;
  final bool isEdit;
  final void Function(String name, int price, String? imageUrl) onSubmit;

  const ComboEditDialog({
    super.key,
    this.initialName = '',
    this.initialPrice,
    this.initialImageUrl,
    this.isEdit = false,
    required this.onSubmit,
  });

  @override
  State<ComboEditDialog> createState() => _ComboEditDialogState();
}

class _ComboEditDialogState extends State<ComboEditDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initialName);
  late final TextEditingController _price =
      TextEditingController(text: widget.initialPrice?.toString() ?? '');
  late String? _imageUrl = widget.initialImageUrl;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEdit ? 'Редактировать комбо' : 'Новое комбо'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Название комбо'),
            ),
            TextField(
              controller: _price,
              decoration: const InputDecoration(labelText: 'Цена, ₽'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            ImagePickerField(
              imageUrl: _imageUrl,
              onChanged: (url) => setState(() => _imageUrl = url),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _name.text.trim();
            final price = int.tryParse(_price.text.trim());
            if (name.isEmpty || price == null) return;
            widget.onSubmit(name, price, _imageUrl);
            Navigator.of(context).pop();
          },
          child: Text(widget.isEdit ? 'Сохранить' : 'Создать'),
        ),
      ],
    );
  }
}
