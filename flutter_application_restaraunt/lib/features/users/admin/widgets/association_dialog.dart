import 'package:flutter/material.dart';

class AssociationDialog extends StatefulWidget {
  final List<String> allGroups;
  final List<String> selectedGroups;
  final void Function(List<String> selected) onSubmit;

  const AssociationDialog({
    super.key,
    required this.allGroups,
    required this.selectedGroups,
    required this.onSubmit,
  });

  @override
  State<AssociationDialog> createState() => _AssociationDialogState();
}

class _AssociationDialogState extends State<AssociationDialog> {
  late final Set<String> tempSelected;

  @override
  void initState() {
    super.initState();
    tempSelected = Set<String>.from(widget.selectedGroups);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(
        'Привязка групп модификаторов',
        style: theme.textTheme.titleMedium,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.allGroups.map((group) {
            return CheckboxListTile(
              value: tempSelected.contains(group),
              title: Text(group, style: theme.textTheme.bodyMedium),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    tempSelected.add(group);
                  } else {
                    tempSelected.remove(group);
                  }
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSubmit(tempSelected.toList());
            Navigator.of(context).pop();
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
