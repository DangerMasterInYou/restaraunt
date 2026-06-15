import 'package:flutter/material.dart';

import '/core/hive/models/menu/menu.dart' as hive;
import '/core/repositories/users/client/restaraunt/carts/dto/request.dart';
import '/features/users/client/favorites/favorites_screen.dart';
import '../models/menu_item.dart';

class AddToCartDialog extends StatefulWidget {
  final MenuItem item;
  final MenuItemVariant initialVariant;
  final void Function(int variantId, List<AppliedModifierCreateDTO> modifiers)
      onConfirm;

  const AddToCartDialog({
    super.key,
    required this.item,
    required this.initialVariant,
    required this.onConfirm,
  });

  @override
  State<AddToCartDialog> createState() => _AddToCartDialogState();
}

class _AddToCartDialogState extends State<AddToCartDialog> {
  late MenuItemVariant _variant;
  final Map<int, Set<int>> _selectedByGroup = {};

  @override
  void initState() {
    super.initState();
    _variant = widget.initialVariant;

    for (final group in _groups) {
      if (group.isRequired && group.modifiers.isNotEmpty) {
        _selectedByGroup[group.id] = {group.modifiers.first.id};
      }
    }
  }

  List<hive.ModifierGroup> get _groups =>
      widget.item.modifierGroups.where((g) => !g.isDeleted).toList();

  int get _total {
    var sum = _variant.price;
    for (final group in _groups) {
      final selected = _selectedByGroup[group.id] ?? const {};
      for (final mod in group.modifiers) {
        if (selected.contains(mod.id)) sum += mod.priceDelta;
      }
    }
    return sum;
  }

  void _toggle(hive.ModifierGroup group, hive.Modifier mod) {
    setState(() {
      final set = _selectedByGroup.putIfAbsent(group.id, () => <int>{});
      if (group.isMultiselect) {
        set.contains(mod.id) ? set.remove(mod.id) : set.add(mod.id);
      } else {
        if (set.contains(mod.id)) {
          if (!group.isRequired) set.remove(mod.id);
        } else {
          set
            ..clear()
            ..add(mod.id);
        }
      }
    });
  }

  List<int> get _selectedModifierIds {
    final ids = <int>[];
    _selectedByGroup.forEach((_, set) => ids.addAll(set));
    return ids;
  }

  bool get _requiredSatisfied {
    for (final group in _groups) {
      if (group.isRequired && (_selectedByGroup[group.id]?.isEmpty ?? true)) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasVariants = widget.item.variants.length > 1;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 10,
                          child: Image.network(
                            widget.item.fullImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Icon(Icons.restaurant_menu,
                                  size: 64,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.3)),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Material(
                            color: theme.colorScheme.surface
                                .withValues(alpha: 0.85),
                            shape: const CircleBorder(),
                            child: IconButton(
                              iconSize: 20,
                              tooltip: 'Закрыть',
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ),
                        ),

                        Positioned(
                          top: 8,
                          left: 8,
                          child: Material(
                            color: theme.colorScheme.surface
                                .withValues(alpha: 0.85),
                            shape: const CircleBorder(),
                            child: IconButton(
                              iconSize: 20,
                              tooltip: 'В избранное',
                              onPressed: () => showAddToFavoriteGroup(
                                context,
                                productVariantId: _variant.id,
                                modifierIds: _selectedModifierIds,
                                subtitle:
                                    '${widget.item.name} · ${_variant.name}',
                              ),
                              icon: const Icon(Icons.bookmark_add_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.item.name,
                              style: theme.textTheme.headlineMedium),
                          if (widget.item.description != null &&
                              widget.item.description!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              widget.item.description!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                          if (hasVariants) ...[
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.item.variants.map((v) {
                                final selected = v.id == _variant.id;
                                return ChoiceChip(
                                  label: Text('${v.name} · ${v.price} ₽'),
                                  selected: selected,
                                  onSelected: (_) =>
                                      setState(() => _variant = v),
                                );
                              }).toList(),
                            ),
                          ],
                          for (final group in _groups)
                            _buildGroup(theme, group),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Center(
                  child: FilledButton(
                    onPressed: _requiredSatisfied
                        ? () {
                            final modifiers = <AppliedModifierCreateDTO>[];
                            _selectedByGroup.forEach((_, ids) {
                              for (final id in ids) {
                                modifiers.add(
                                    AppliedModifierCreateDTO(modifierId: id));
                              }
                            });
                            widget.onConfirm(_variant.id, modifiers);
                            Navigator.of(context).pop();
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text('В корзину · $_total ₽'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroup(ThemeData theme, hive.ModifierGroup group) {
    final selected = _selectedByGroup[group.id] ?? const <int>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              Text(group.name, style: theme.textTheme.titleMedium),
              if (group.isRequired)
                Text(' *', style: TextStyle(color: theme.colorScheme.error)),
            ],
          ),
        ),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: group.modifiers.map((mod) {
            final isSelected = selected.contains(mod.id);
            final priceLabel =
                mod.priceDelta != 0 ? ' +${mod.priceDelta}₽' : '';
            return FilterChip(
              selected: isSelected,
              onSelected: (_) => _toggle(group, mod),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              labelPadding: const EdgeInsets.only(left: 2, right: 4),

              selectedColor: theme.colorScheme.primary,
              checkmarkColor: theme.colorScheme.onPrimary,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              avatar: mod.fullImageUrl != null
                  ? ClipOval(
                      child: Image.network(
                        mod.fullImageUrl!,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.fastfood, size: 18),
                      ),
                    )
                  : null,
              label: Text(
                '${mod.name}$priceLabel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
