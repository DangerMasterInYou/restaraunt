import 'package:flutter/material.dart';
import 'image_picker_field.dart';

class ModifierCrudDialog extends StatefulWidget {
  final String? initialName;
  final int? initialPriceDelta;
  final int? initialGroupId;
  final String? initialImageUrl;
  final List<Map<String, dynamic>> groups;
  final void Function(
      String name, int priceDelta, int groupId, String? imageUrl) onSubmit;
  final void Function()? onHardDelete;
  final bool isEdit;

  const ModifierCrudDialog({
    super.key,
    this.initialName,
    this.initialPriceDelta,
    this.initialGroupId,
    this.initialImageUrl,
    required this.groups,
    required this.onSubmit,
    this.onHardDelete,
    this.isEdit = false,
  });

  @override
  State<ModifierCrudDialog> createState() => _ModifierCrudDialogState();
}

class _ModifierCrudDialogState extends State<ModifierCrudDialog> {
  late TextEditingController nameController;
  late TextEditingController priceDeltaController;
  int? selectedGroupId;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName ?? '');
    priceDeltaController =
        TextEditingController(text: widget.initialPriceDelta?.toString() ?? '');
    selectedGroupId = widget.initialGroupId ??
        (widget.groups.isNotEmpty ? widget.groups.first['id'] as int : null);
    imageUrl = widget.initialImageUrl;
  }

  @override
  void dispose() {
    nameController.dispose();
    priceDeltaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.isEdit ? 'Редактировать модификатор' : 'Создать модификатор'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: selectedGroupId,
              isExpanded: true,
              borderRadius: BorderRadius.circular(12),
              items: widget.groups
                  .map((g) => DropdownMenuItem<int>(
                        value: g['id'] as int,
                        child: Text(g['name'] as String,
                            overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => selectedGroupId = val),
              decoration: const InputDecoration(
                labelText: 'Группа модификаторов',
              ),
              validator: (value) {
                if (value == null) {
                  return 'Пожалуйста, выберите группу';
                }
                return null;
              },
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Название',
              ),
            ),
            TextField(
              controller: priceDeltaController,
              decoration: const InputDecoration(
                labelText: 'Изменение цены',
              ),
              keyboardType: TextInputType.number,
            ),
            ImagePickerField(
              imageUrl: imageUrl,
              onChanged: (url) => setState(() => imageUrl = url),
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
            final name = nameController.text.trim();
            final priceDelta = int.tryParse(priceDeltaController.text.trim());
            if (name.isEmpty || priceDelta == null || selectedGroupId == null) return;
            widget.onSubmit(name, priceDelta, selectedGroupId!, imageUrl);
            Navigator.of(context).pop();
          },
          child: Text(widget.isEdit ? 'Сохранить' : 'Создать'),
        ),
      ],
    );
  }
}
