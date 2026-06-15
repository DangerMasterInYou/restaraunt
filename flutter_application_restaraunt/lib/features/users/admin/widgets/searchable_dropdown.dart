import 'package:flutter/material.dart';

class DropdownOption<T> {
  final T value;
  final String label;
  const DropdownOption(this.value, this.label);
}

class SearchableDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownOption<T>> options;
  final ValueChanged<T> onChanged;

  const SearchableDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  String get _currentLabel {
    for (final o in options) {
      if (o.value == value) return o.label;
    }
    return '';
  }

  Future<void> _openPicker(BuildContext context) async {
    final theme = Theme.of(context);
    var query = '';
    final selected = await showDialog<T>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final filtered = options
                .where((o) =>
                    o.label.toLowerCase().contains(query.toLowerCase()))
                .toList();
            return AlertDialog(
              title: Text(label, style: theme.textTheme.titleMedium),
              content: SizedBox(
                width: 420,
                height: 420,
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
                      onChanged: (v) => setState(() => query = v),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('Ничего не найдено'))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final o = filtered[i];
                                return ListTile(
                                  title: Text(o.label),
                                  selected: o.value == value,
                                  onTap: () => Navigator.of(ctx).pop(o.value),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Отмена'),
                ),
              ],
            );
          },
        );
      },
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openPicker(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12)),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          _currentLabel.isEmpty ? 'Выберите…' : _currentLabel,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
