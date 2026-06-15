
import 'package:flutter/material.dart';
import '/core/repositories/users/client/restaraunt/carts/carts.dart';

class CartTileCard extends StatelessWidget {
  const CartTileCard({
    super.key,
    required this.cartItem,
    required this.onSubtract,
    required this.onAdd,
    required this.onDelete,
  });

  final CartItemResponseDTO cartItem;
  final VoidCallback onSubtract;
  final VoidCallback onAdd;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = cartItem.productVariant;
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      color: theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: () {

        },
        child: SizedBox(
          height: isSmallScreen ? 150 : 170,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              Expanded(
                flex: isSmallScreen ? 2 : 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      product.fullImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Center(
                            child: Icon(Icons.restaurant,
                                size: 50, color: theme.colorScheme.primary)),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(

                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2))
                          ],
                        ),
                        child: Text(
                          '${cartItem.subtotalPrice} ₽',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                flex: isSmallScreen ? 3 : 4,
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              () {

                                final title = cartItem.productName ?? product.name;
                                return product.sizeLabel != null
                                    ? '$title (${product.sizeLabel})'
                                    : title;
                              }(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 16 : 18,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.6),
                                size: 20),
                            onPressed: onDelete,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),

                      if (cartItem.appliedModifiers.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: cartItem.appliedModifiers
                                .map((mod) => Text(
                                      mod.quantity > 1
                                          ? '${mod.modifier.name} ×${mod.quantity}'
                                          : mod.modifier.name,
                                      style: TextStyle(
                                        color: theme
                                            .colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.7),
                                        fontSize: 12,
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      const Spacer(),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [_buildCountControls(theme, isSmallScreen)],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountControls(ThemeData theme, bool isSmallScreen) {
    final buttonSize = isSmallScreen ? 32.0 : 36.0;

    return Row(
      children: [
        _buildCountButton(
          icon: Icons.remove,
          onPressed: onSubtract,
          theme: theme,
          size: buttonSize,
        ),
        Container(
          width: buttonSize,
          height: buttonSize,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            border:
                Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.7)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              '${cartItem.quantity}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: isSmallScreen ? 14 : 16,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        _buildCountButton(
          icon: Icons.add,
          onPressed: onAdd,
          theme: theme,
          size: buttonSize,
        ),
      ],
    );
  }

  Widget _buildCountButton({
    required IconData icon,
    required VoidCallback onPressed,
    required ThemeData theme,
    required double size,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
        ),
        child: Icon(icon, size: size * 0.6),
      ),
    );
  }
}
