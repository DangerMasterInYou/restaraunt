import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_application_restaraunt/core/router/router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import '/core/hive/models/menu/menu.dart';
import '/core/services/app_toast.dart';
import '/core/repositories/users/client/restaraunt/carts/carts.dart';
import '../widgets/app_bar.dart';
import '../widgets/add_to_cart_dialog.dart';
import '../widgets/tile_card.dart';
import '../bloc/menu_bloc.dart';
import 'package:flutter_application_restaraunt/core/repositories/restaraunt/menu/repository/abstract_menu.dart';
import '../models/menu_item.dart';

@RoutePage()
class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  late final MenuBloc _menuBloc;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _menuBloc = MenuBloc(
      GetIt.I<AbstractMenuRepository>(),
      GetIt.I<AbstractCartRepository>(),
    )..add(LoadMenu());
  }

  @override
  void dispose() {
    _menuBloc.close();
    super.dispose();
  }

  String? _cleanDescription(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return raw.split('\n').first.trim();
  }

  List<MenuItem> _groupMenuItems(List<Menu> menuList) {

    final sizeRegex = RegExp(
      r'\s+(?:\d+(?:\.\d+)?\s*(?:гр|г|мл|л|кг|шт)|Стандарт|Большая|Средняя|Маленькая)\s*$',
    );

    final Map<String, List<Menu>> grouped = {};

    for (final item in menuList) {

      final String key;
      if (item.productId != null) {
        key = 'pid:${item.productId}';
      } else {
        final baseName = item.name.replaceFirst(sizeRegex, '').trim();
        key = '$baseName|${item.imageUrl ?? ''}';
      }
      grouped.putIfAbsent(key, () => []).add(item);
    }

    return grouped.values.map((items) {

      if (items.length == 1) {
        final m = items.first;
        return MenuItem(
          name: m.name,
          description: _cleanDescription(m.description),
          imageUrl: m.imageUrl,
          category: m.category,
          sku: m.sku,
          isAvailable: m.isAvailable,
          modifierGroups: m.modifierGroups,
          variants: [
            MenuItemVariant(
              id: m.id,
              name: m.value != null && m.unit != null
                  ? '${m.value} ${m.unit}'
                  : m.name,
              price: m.price,
              value: m.value,
              unit: m.unit,
              isDefault: true,
            )
          ],
        );
      }

      final variants = <MenuItemVariant>[];

      final first = items.first;
      final baseName = first.name.replaceFirst(sizeRegex, '').trim();

      for (final m in items) {

        String variantName;
        if (m.value != null && m.unit != null) {
          variantName = '${m.value} ${m.unit}';
        } else {

          variantName = m.name.replaceFirst(baseName, '').trim();
          if (variantName.isEmpty) {

            variantName = m.name.split(' ').last;
          }
        }

        variants.add(
          MenuItemVariant(
            id: m.id,
            name: variantName,
            price: m.price,
            value: m.value,
            unit: m.unit,
            isDefault: m.name.contains('Стандарт'),
          ),
        );
      }

      return MenuItem(
        name: baseName,
        description:
            _cleanDescription(first.description),
        imageUrl: first.imageUrl,
        category: first.category,
        sku: first.sku,
        isAvailable: first.isAvailable,
        modifierGroups: first.modifierGroups,
        variants: variants,
      );
    }).toList();
  }

  List<MenuItem> _getFilteredItems(List<MenuItem> items) {
    if (_selectedCategory == null) return items;
    return items.where((item) => item.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 800;
    final theme = Theme.of(context);

    return BlocProvider(
      create: (context) => _menuBloc,
      child: Scaffold(

        floatingActionButton: BlocBuilder<MenuBloc, MenuState>(
          builder: (context, state) {
            final count = state is MenuLoaded ? state.cartCount : 0;
            return Badge(
              isLabelVisible: count > 0,
              label: Text('$count'),
              offset: const Offset(-4, 4),
              child: FloatingActionButton(
                onPressed: () => context.router.push(const CartRoute()),
                tooltip: 'Корзина',
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                child: const Icon(Icons.shopping_cart),
              ),
            );
          },
        ),

        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20)),
              child: BlocConsumer<MenuBloc, MenuState>(
          listener: (context, state) {
            if (state is MenuLoadingFailure) {
              AppToast.error(context, 'Ошибка загрузки');
            }
          },
          builder: (context, state) {
            if (state is MenuLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is MenuLoadingFailure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Ошибка загрузки', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _menuBloc.add(LoadMenu()),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              );
            }

            if (state is MenuLoaded) {

              final menuItems = _groupMenuItems(state.menuList);

              final categories = <String>[];
              for (final m in menuItems) {
                if (!categories.contains(m.category)) {
                  categories.add(m.category);
                }
              }

              final filteredItems = _getFilteredItems(menuItems);

              final crossAxisCount = _calculateCrossAxisCount(screenWidth);
              final isNarrow = crossAxisCount == 1;

              final slivers = <Widget>[
                _buildAppBar(isWideScreen, theme),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  sliver: SliverToBoxAdapter(
                    child: _buildCategoryButtons(categories, theme),
                  ),
                ),
              ];

              if (_selectedCategory != null) {
                slivers.add(SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: isNarrow
                      ? _buildMenuList(filteredItems, isNarrow: true)
                      : _buildMenuGrid(filteredItems, crossAxisCount,
                          isNarrow: false),
                ));
              } else {

                for (final cat in categories) {
                  final catItems =
                      menuItems.where((m) => m.category == cat).toList();
                  slivers.add(SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
                      child: Text(cat, style: theme.textTheme.headlineMedium),
                    ),
                  ));
                  slivers.add(SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: isNarrow
                        ? _buildMenuList(catItems, isNarrow: true)
                        : _buildMenuGrid(catItems, crossAxisCount,
                            isNarrow: false),
                  ));
                }
                slivers.add(const SliverToBoxAdapter(
                    child: SizedBox(height: 24)));
              }

              slivers.add(SliverFillRemaining(
                hasScrollBody: false,
                fillOverscroll: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [_buildLocationFooter(theme)],
                ),
              ));

              return CustomScrollView(slivers: slivers);
            }

            return const Center(child: CircularProgressIndicator());
          },
              ),
            ),
          ),
        ),
      ),
    );
  }

  SliverList _buildMenuList(List<MenuItem> items, {required bool isNarrow}) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MenuTileCard(
              data: item,
              isNarrow: isNarrow,
              onTap: (variant) => _openProductModal(item, variant),
            ),
          );
        },
        childCount: items.length,
      ),
    );
  }

  SliverGrid _buildMenuGrid(List<MenuItem> items, int crossAxisCount,
      {required bool isNarrow}) {
    return SliverGrid(

      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 230,

        childAspectRatio: 0.56,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = items[index];
          return MenuTileCard(
            data: item,
            isNarrow: isNarrow,
            onTap: (variant) => _openProductModal(item, variant),
          );
        },
        childCount: items.length,
      ),
    );
  }

  int _calculateCrossAxisCount(double screenWidth) {
    if (screenWidth > 1200) return 4;
    if (screenWidth > 900) return 3;
    if (screenWidth > 600) return 2;
    return 1;
  }

  SliverAppBar _buildAppBar(bool isWideScreen, ThemeData theme) {
    return SliverAppBar(
      leading: isWideScreen
          ? Padding(
              padding: const EdgeInsets.only(left: 15),
              child: _buildLogo(60),
            )
          : SizedBox(
              width: 80,
              child: Padding(
                padding: const EdgeInsets.only(left: 15),
                child: _buildLogo(40),
              ),
            ),
      centerTitle: true,
      title: Text(
        'doner-kebab',
        style: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
      actions: isWideScreen
          ? (buildWideAppBar(context) as AppBar).actions
          : (buildNarrowAppBar(context) as AppBar).actions,
      floating: true,
      pinned: true,
      snap: false,
      expandedHeight: isWideScreen ? 0 : null,
    );
  }

  Widget _buildLogo(double size) {
    return Center(
      child: Container(
        height: size,
        width: size,
        padding: const EdgeInsets.all(4),
        margin: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: ClipOval(
          child: SvgPicture.asset(
            'assets/svg/logo.svg',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButtons(List<String> categories, ThemeData theme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildCategoryButton(null, 'Все категории', theme),
          ...categories.map(
              (category) => _buildCategoryButton(category, category, theme)),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String? category, String text, ThemeData theme) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: () => setState(() => _selectedCategory = category),
        style: ElevatedButton.styleFrom(

          backgroundColor: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          foregroundColor: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? Colors.transparent
                  : theme.colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _buildLocationFooter(ThemeData theme) {

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.location_on,
                  color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Мы находимся здесь',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Ханты-Мансийск, ул. Калинина, 22',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProductModal(MenuItem item, [MenuItemVariant? variant]) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AddToCartDialog(
          item: item,
          initialVariant: variant ?? item.variants.first,
          onConfirm: (variantId, modifiers) {
            _menuBloc.add(
              AddItemCartMenu(
                cartItemRequest: CartItemRequestDTO(
                  productVariantId: variantId,
                  quantity: 1,
                  modifiers: modifiers,
                ),
              ),
            );
            AppToast.success(context, '${item.name} добавлен в корзину');
          },
        );
      },
    );
  }
}
