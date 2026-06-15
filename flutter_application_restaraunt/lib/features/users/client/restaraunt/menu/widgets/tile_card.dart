import 'package:flutter/material.dart';
import '../models/menu_item.dart';

class MenuTileCard extends StatefulWidget {
  final MenuItem data;

  final void Function(MenuItemVariant variant) onTap;
  final bool isNarrow;

  const MenuTileCard({
    super.key,
    required this.data,
    required this.onTap,
    this.isNarrow = false,
  });

  @override
  State<MenuTileCard> createState() => _MenuTileCardState();
}

class _MenuTileCardState extends State<MenuTileCard> {
  late MenuItemVariant _selected;

  @override
  void initState() {
    super.initState();

    _selected = widget.data.variants.firstWhere(
      (v) => v.isDefault,
      orElse: () => widget.data.variants.reduce(
        (a, b) => a.price <= b.price ? a : b,
      ),
    );
  }

  bool get _hasVariants => widget.data.variants.length > 1;

  @override
  Widget build(BuildContext context) {
    return widget.isNarrow ? _buildNarrow(context) : _buildWide(context);
  }

  Widget _image(BuildContext context, double size) {
    final theme = Theme.of(context);
    return Image.network(
      widget.data.fullImageUrl,
      width: size == double.infinity ? double.infinity : size,
      height: size == double.infinity ? null : size,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : Container(
              color: theme.colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
      errorBuilder: (_, __, ___) => Container(
        color: theme.colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(Icons.restaurant_menu,
            size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
      ),
    );
  }

  Widget _variantSelector(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 30,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: widget.data.variants.map((v) {
          final selected = v.id == _selected.id;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(v.name, style: theme.textTheme.labelSmall),
              selected: selected,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              labelPadding: const EdgeInsets.symmetric(horizontal: 4),
              onSelected: (_) => setState(() => _selected = v),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _priceButton(BuildContext context) {
    final available = widget.data.isAvailable;
    return OutlinedButton(
      onPressed: available ? () => widget.onTap(_selected) : null,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      ),
      child: Text(available ? '${_selected.price} ₽' : 'Нет в наличии'),
    );
  }

  Widget _buildWide(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => widget.onTap(_selected),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(aspectRatio: 1, child: _image(context, double.infinity)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.data.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (_hasVariants) _variantSelector(context),
                    const SizedBox(height: 6),
                    Align(
                        alignment: Alignment.centerRight,
                        child: _priceButton(context)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNarrow(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => widget.onTap(_selected),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    SizedBox(width: 96, height: 96, child: _image(context, 96)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.data.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.data.description?.isNotEmpty == true
                          ? widget.data.description!
                          : widget.data.category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (_hasVariants) ...[
                      _variantSelector(context),
                      const SizedBox(height: 6),
                    ],
                    _priceButton(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
