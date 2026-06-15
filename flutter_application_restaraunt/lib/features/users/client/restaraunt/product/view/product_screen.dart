import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '/core/hive/models/menu/menu.dart';
import '/core/repositories/users/client/restaraunt/carts/carts.dart';
import '../bloc/product_bloc.dart';
import '../../menu/models/menu_item.dart';

@RoutePage()
class ProductScreen extends StatefulWidget {
  final int id;
  const ProductScreen({super.key, required this.id});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late ProductBloc _bloc;

  MenuItemVariant? _selectedVariant;

  final Map<int, List<int>> _selectedModifiers = {};

  @override
  void initState() {
    super.initState();
    _bloc = ProductBloc()..add(LoadProduct(productId: widget.id));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  int _calculateTotalPrice(Menu product) {
    int price = _selectedVariant?.price ?? product.price;
    for (final entry in _selectedModifiers.entries) {
      final group = product.modifierGroups.firstWhere((g) => g.id == entry.key);
      for (final modId in entry.value) {
        final modifier = group.modifiers.firstWhere((m) => m.id == modId);
        price += modifier.priceDelta;
      }
    }
    return price;
  }

  bool _isGroupValid(ModifierGroup group) {
    final selected = _selectedModifiers[group.id] ?? [];
    if (group.isRequired && selected.isEmpty) return false;
    return true;
  }

  bool _canAddToCart(Menu product) {
    for (final group in product.modifierGroups) {
      if (!_isGroupValid(group)) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<ProductBloc, ProductState>(
        builder: (context, state) {
          if (state is ProductLoading) {
            return const Scaffold(
              backgroundColor: Color(0xFF1A191A),
              body:
                  Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          }
          if (state is ProductLoadingFailure) {
            return Scaffold(
              backgroundColor: const Color(0xFF1A191A),
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.router.pop(),
                ),
              ),
              body: const Center(
                child: Text('Ошибка загрузки продукта',
                    style: TextStyle(color: Colors.white70)),
              ),
            );
          }
          if (state is ProductLoaded) {
            final product = state.product;

            _selectedVariant ??= MenuItemVariant(
              id: product.id,
              name: product.value != null && product.unit != null
                  ? '${product.value} ${product.unit}'
                  : product.name,
              price: product.price,
              value: product.value,
              unit: product.unit,
              isDefault: true,
            );

            final total = _calculateTotalPrice(product);
            final theme = Theme.of(context);

            return Scaffold(
              backgroundColor: const Color(0xFF1A191A),
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.router.pop(),
                ),
                title: Text(
                  product.name,
                  style:
                      theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                centerTitle: true,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          product.fullImageUrl,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 220,
                            color: Colors.grey[850],
                            child: const Icon(Icons.no_photography,
                                color: Colors.white24, size: 60),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    ...product.modifierGroups
                        .map((group) => _buildModifierGroup(group, theme)),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Итого: $total ₽',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _canAddToCart(product)
                              ? () => _addToCart(product)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: const Text('Добавить в корзину'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildModifierGroup(ModifierGroup group, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.name + (group.isRequired ? ' *' : ''),
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          group.isMultiselect
              ? Wrap(
                  spacing: 8,
                  children: group.modifiers.map((mod) {
                    final selected =
                        (_selectedModifiers[group.id] ?? []).contains(mod.id);
                    return FilterChip(
                      label: Text(
                          '${mod.name} ${mod.priceDelta > 0 ? "+${mod.priceDelta}₽" : ""}'),
                      selected: selected,
                      onSelected: (isSel) {
                        setState(() {
                          _selectedModifiers[group.id] ??= [];
                          if (isSel) {
                            _selectedModifiers[group.id]!.add(mod.id);
                          } else {
                            _selectedModifiers[group.id]!.remove(mod.id);
                          }
                        });
                      },
                      selectedColor: Colors.white,
                      backgroundColor: Colors.grey[800],
                      labelStyle: TextStyle(
                          color: selected ? Colors.black : Colors.white),
                    );
                  }).toList(),
                )
              : Wrap(
                  spacing: 8,
                  children: group.modifiers.map((mod) {
                    final selected =
                        (_selectedModifiers[group.id] ?? []).contains(mod.id);
                    return ChoiceChip(
                      label: Text(
                          '${mod.name} ${mod.priceDelta > 0 ? "+${mod.priceDelta}₽" : ""}'),
                      selected: selected,
                      onSelected: (_) {
                        setState(() {
                          _selectedModifiers[group.id] = [mod.id];
                        });
                      },
                      selectedColor: Colors.white,
                      backgroundColor: Colors.grey[800],
                      labelStyle: TextStyle(
                          color: selected ? Colors.black : Colors.white),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Future<void> _addToCart(Menu product) async {
    final variantId = _selectedVariant!.id;
    final modifiers = _selectedModifiers.values
        .expand((list) => list)
        .map(
          (modifierId) => AppliedModifierCreateDTO(
            modifierId: modifierId,
            quantity: 1,
          ),
        )
        .toList();

    try {
      await GetIt.I<AbstractCartRepository>().addItemToCart(
        CartItemRequestDTO(
          productVariantId: variantId,
          quantity: 1,
          modifiers: modifiers,
        ),
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавлено в корзину')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось добавить товар в корзину')),
      );
    }
  }
}
