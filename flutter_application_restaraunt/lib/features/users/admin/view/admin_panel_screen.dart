import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_restaraunt/api_config.dart';
import 'package:flutter_application_restaraunt/features/users/admin/bloc/admin_entities_bloc.dart';
import '/features/theme/bloc/theme_bloc.dart';
import '/core/services/app_toast.dart';
import '/core/widgets/reviews_dialog.dart';
import '/core/repositories/users/admin/restaraunt/product_full/product_variant/dto/response.dart';
import '/core/router/router.dart';
import '../widgets/widgets.dart';

@RoutePage()
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  String expandedEntity = 'category';
  int? expandedItemId;

  String _productSearch = '';
  final TextEditingController _productSearchController = TextEditingController();

  @override
  void dispose() {
    _productSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AdminEntitiesBloc()..add(LoadAllEntities()),
      child: BlocConsumer<AdminEntitiesBloc, AdminEntitiesState>(
        listener: (context, state) {

          final msg = state is AdminEntityOperationError
              ? state.message
              : (state is AdminEntitiesError ? state.message : null);
          if (msg != null &&
              (msg.contains('403') ||
                  msg.toLowerCase().contains('forbidden'))) {
            context.router.replace(const LoginRoute());
            return;
          }
          if (state is AdminEntityOperationError) {
            AppToast.fromError(context, state.message);
          }
          if (state is AdminEntityOperationSuccess) {
            AppToast.success(context, 'Операция выполнена успешно');
          }
        },
        builder: (context, state) {
          final theme = Theme.of(context);
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Административная панель',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontSize: 20,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    theme.brightness == Brightness.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: theme.colorScheme.onSurface,
                  ),
                  tooltip: 'Сменить тему',
                  onPressed: () =>
                      context.read<ThemeBloc>().add(ToggleThemeEvent()),
                ),
                IconButton(
                  icon: Icon(Icons.people, color: theme.colorScheme.onSurface),
                  tooltip: 'Пользователи',
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const UsersAdminDialog(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.receipt_long,
                      color: theme.colorScheme.onSurface),
                  tooltip: 'Заказы',
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const OrdersAdminDialog(),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.local_offer,
                    color: theme.colorScheme.onSurface,
                  ),
                  tooltip: 'Акции',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const PromotionsAdminDialog(),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.star_outline,
                      color: theme.colorScheme.onSurface),
                  tooltip: 'Отзывы',
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const ReviewsDialog(canManage: true),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.logout,
                    color: theme.colorScheme.onSurface,
                  ),
                  tooltip: 'Выйти',
                  onPressed: () {
                    context.router.replace(const LoginRoute());
                  },
                ),
              ],
              backgroundColor: theme.colorScheme.surface,
            ),
            backgroundColor: theme.scaffoldBackgroundColor,
            body: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                return Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _entityIndex(expandedEntity),
                      onDestinationSelected: (index) {
                        setState(() {
                          expandedEntity = _entities[index];
                          expandedItemId = null;
                        });
                      },
                      labelType: NavigationRailLabelType.all,
                      destinations: _entities
                          .map((e) => NavigationRailDestination(
                                icon: const Icon(Icons.folder),
                                label: Text(_entityLabel(e)),
                              ))
                          .toList(),
                    ),
                    Expanded(
                      child: _buildEntityList(context, state, expandedEntity,
                          expandedItemId, isWide),
                    ),
                  ],
                );
              },
            ),
            floatingActionButton: _buildFab(context, expandedEntity, state),
          );
        },
      ),
    );
  }

  static const _entities = [
    'category',
    'product',
    'combo',
    'modifier',
    'modifierGroup',
  ];

  int _entityIndex(String? entity) =>
      entity == null ? 0 : _entities.indexOf(entity);

  String _entityLabel(String entity) {
    switch (entity) {
      case 'category':
        return 'Категории';
      case 'product':
        return 'Продукты';
      case 'combo':
        return 'Комбо';
      case 'variant':
        return 'Варианты';
      case 'modifier':
        return 'Модификаторы';
      case 'modifierGroup':
        return 'Группы модификаторов';
      default:
        return entity;
    }
  }

  Widget _buildFab(
      BuildContext context, String entity, AdminEntitiesState state) {
    switch (entity) {
      case 'category':
        return FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => CategoryCrudDialog(
                onSubmit: (name, sortOrder) {
                  context.read<AdminEntitiesBloc>().add(
                        CreateCategory(name: name, sortOrder: sortOrder),
                      );
                },
              ),
            );
          },
          tooltip: 'Добавить категорию',
          child: const Icon(Icons.add),
        );
      case 'product':
        final categories = state is AdminEntitiesLoaded ? state.categories : [];
        return FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => ProductCrudDialog(
                categories: categories,
                onSubmit: (categoryId, name, description, sortOrder, imageUrl) {
                  context.read<AdminEntitiesBloc>().add(
                        CreateProduct(
                          categoryId: categoryId,
                          name: name,
                          description: description,
                          imageUrl: imageUrl,
                          sortOrder: sortOrder,
                        ),
                      );
                },
              ),
            );
          },
          tooltip: 'Добавить продукт',
          child: const Icon(Icons.add),
        );
      case 'variant':
        final products = state is AdminEntitiesLoaded ? state.products : [];
        return FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => VariantCrudDialog(
                initialProductId:
                    products.isNotEmpty ? products.first.id : null,
                products: products,
                onSubmit: (
                    {required int productId,
                    required String name,
                    required int price,
                    required String sku,
                    required bool isAvailable,
                    required bool isCombo,
                    String? description,
                    String? imageUrl,
                    int? value,
                    String? unit}) {
                  context.read<AdminEntitiesBloc>().add(
                        CreateVariant(
                          productId: productId,
                          name: name,
                          price: price,
                          sku: sku,
                          isAvailable: isAvailable,
                          isCombo: isCombo,
                          imageUrl: imageUrl,
                          value: value,
                          unit: unit,
                        ),
                      );
                },
              ),
            );
          },
          tooltip: 'Добавить вариант',
          child: const Icon(Icons.add),
        );
      case 'modifier':
        final groups = state is AdminEntitiesLoaded
            ? state.modifierGroups
                .map((g) => {'id': g.id, 'name': g.name})
                .toList()
            : <Map<String, dynamic>>[];
        return FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => ModifierCrudDialog(
                groups: groups,
                onSubmit: (name, priceDelta, groupId, imageUrl) {
                  context.read<AdminEntitiesBloc>().add(
                        CreateModifier(
                            groupId: groupId,
                            name: name,
                            price: priceDelta,
                            imageUrl: imageUrl),
                      );
                },
              ),
            );
          },
          tooltip: 'Добавить модификатор',
          child: const Icon(Icons.add),
        );
      case 'modifierGroup':
        return FloatingActionButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => ModifierGroupCrudDialog(
                onSubmit: (name, isRequired, isMultiselect) {
                  context.read<AdminEntitiesBloc>().add(
                        CreateModifierGroup(
                          name: name,
                          isRequired: isRequired,
                          isMultiselect: isMultiselect,
                        ),
                      );
                },
              ),
            );
          },
          tooltip: 'Добавить группу модификаторов',
          child: const Icon(Icons.add),
        );
      case 'combo':

        return FloatingActionButton.extended(
          onPressed: () {
            final bloc = context.read<AdminEntitiesBloc>();
            showDialog(
              context: context,
              builder: (ctx) => ComboEditDialog(
                onSubmit: (name, price, imageUrl) {
                  bloc.add(CreateCombo(
                    name: name,
                    price: price,
                    imageUrl: imageUrl,
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Комбо создано. Откройте его и задайте «Состав комбо».'),
                    ),
                  );
                },
              ),
            );
          },
          tooltip: 'Добавить комбо',
          icon: const Icon(Icons.add),
          label: const Text('Комбо'),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEntityList(BuildContext context, AdminEntitiesState state,
      String entity, int? expandedId, bool isWide) {
    if (state is AdminEntitiesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is AdminEntitiesError) {
      return Center(child: Text('Ошибка: ${state.message}'));
    }
    if (state is! AdminEntitiesLoaded) {
      return const SizedBox.shrink();
    }
    final items = _getItemsForEntity(state, entity);

    final searchable =
        entity == 'product' || entity == 'combo' || entity == 'modifier';

    if (items.isEmpty) {
      final empty = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                _productSearch.isNotEmpty && searchable
                    ? 'Ничего не найдено.'
                    : 'Нет данных для этой сущности.',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            if (!(searchable && _productSearch.isNotEmpty))
              Text('Нажмите + чтобы создать.',
                  style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
      return searchable
          ? Column(children: [_buildProductSearchField(), Expanded(child: empty)])
          : empty;
    }

    final reorderable = entity == 'category' ||
        (entity == 'product' && _productSearch.isEmpty);

    Widget cardFor(int idx, {Widget? dragHandle}) {
      final item = items[idx];
      final isExpanded = expandedId == idx;
      final content = InkWell(
        onTap: () => setState(() => expandedItemId = isExpanded ? null : idx),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isExpanded
              ? _buildFullItem(context, entity, item, isWide, state)
              : _buildMiniItem(context, entity, item, isWide),
        ),
      );
      return Card(
        key: ValueKey('${entity}_${item.id}'),
        color: isExpanded
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : null,
        child: dragHandle == null
            ? content
            : Row(
                children: [
                  dragHandle,
                  Expanded(child: content),
                ],
              ),
      );
    }

    final Widget list;
    if (reorderable) {
      list = ReorderableListView.builder(
        padding: const EdgeInsets.all(24),
        buildDefaultDragHandles: false,
        itemCount: items.length,
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) newIndex -= 1;
          final ids = [for (final e in items) e.id as int];
          final moved = ids.removeAt(oldIndex);
          ids.insert(newIndex, moved);
          final bloc = context.read<AdminEntitiesBloc>();
          if (entity == 'category') {
            bloc.add(ReorderCategories(ids));
          } else {
            bloc.add(ReorderProducts(ids));
          }
          setState(() => expandedItemId = null);
        },
        itemBuilder: (context, idx) => cardFor(
          idx,
          dragHandle: ReorderableDragStartListener(
            index: idx,
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.drag_handle),
            ),
          ),
        ),
      );
    } else {
      list = ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: items.length,
        itemBuilder: (context, idx) => cardFor(idx),
      );
    }

    if (searchable) {
      return Column(
        children: [_buildProductSearchField(), Expanded(child: list)],
      );
    }
    return list;
  }

  Widget _buildProductSearchField() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: TextField(
        controller: _productSearchController,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Поиск по названию…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _productSearch.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _productSearchController.clear();
                    setState(() => _productSearch = '');
                  },
                )
              : null,
          filled: true,
          fillColor: theme.colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (v) => setState(() => _productSearch = v),
      ),
    );
  }

  Iterable _applyProductSearch(Iterable products) {
    final q = _productSearch.trim().toLowerCase();
    if (q.isEmpty) return products;
    return products
        .where((p) => (p.name as String).toLowerCase().contains(q));
  }

  bool _isComboProduct(dynamic product) =>
      product.variants.any((v) => v.isCombo == true);

  Widget _modifierThumb(dynamic item, double size) {
    final url = item.imageUrl as String?;
    if (url == null || url.isEmpty) {
      return Icon(Icons.tune, size: size);
    }
    final full = url.startsWith('http') ? url : '${ApiConfig.apiSiteUrl}$url';
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(full,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.tune, size: size)),
    );
  }

  List _sortedByCategory(Iterable products) {
    final list = products.toList();
    list.sort((a, b) {
      final c = a.category.sortOrder.compareTo(b.category.sortOrder);
      if (c != 0) return c;
      final s = a.sortOrder.compareTo(b.sortOrder);
      return s != 0 ? s : (a.id as int).compareTo(b.id as int);
    });
    return list;
  }

  List _getItemsForEntity(AdminEntitiesLoaded state, String entity) {
    switch (entity) {
      case 'category':
        return [...state.categories]
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      case 'product':

        return _sortedByCategory(
            _applyProductSearch(state.products.where((p) => !_isComboProduct(p))));
      case 'combo':

        return _sortedByCategory(
            _applyProductSearch(state.products.where((p) => _isComboProduct(p))));
      case 'variant':
        return state.variants;
      case 'modifier':

        return _applyProductSearch(state.modifiers).toList();
      case 'modifierGroup':
        return state.modifierGroups;
      default:
        return [];
    }
  }

  Widget _variantImagePlaceholder(bool isWide) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: isWide ? 180 : 120,
      height: isWide ? 180 : 120,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.image,
          color: scheme.onSurface.withValues(alpha: 0.4), size: 48),
    );
  }

  Widget _comboImagePlaceholder(ThemeData theme, bool isWide) {
    return Container(
      width: isWide ? 140 : 100,
      height: isWide ? 140 : 100,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Icon(Icons.image,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4), size: 40),
    );
  }

  Widget _buildComboFull(BuildContext context, dynamic item, bool isWide,
      AdminEntitiesState state, AdminEntitiesBloc bloc) {
    final theme = Theme.of(context);

    final List variants = item.variants as List;
    dynamic comboVariant;
    for (final v in variants) {
      if (v.isCombo == true) {
        comboVariant = v;
        break;
      }
    }
    comboVariant ??= variants.isNotEmpty ? variants.first : null;
    final price = comboVariant?.price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),

              child: item.imageUrl != null
                  ? Image.network(item.fullImageUrl,
                      width: isWide ? 140 : 100,
                      height: isWide ? 140 : 100,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _comboImagePlaceholder(theme, isWide))
                  : _comboImagePlaceholder(theme, isWide),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: theme.textTheme.headlineMedium),
                  Text('ID: ${item.id}', style: theme.textTheme.bodySmall),
                  Text('Цена: ${price ?? '—'} ₽',
                      style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => ComboEditDialog(
                    isEdit: true,
                    initialName: item.name,
                    initialPrice: price,
                    initialImageUrl: item.imageUrl,
                    onSubmit: (name, newPrice, img) {
                      bloc.add(UpdateProduct(
                        id: item.id,
                        categoryId: item.category.id,
                        name: name,
                        imageUrl: img,
                      ));
                      if (comboVariant != null) {
                        bloc.add(UpdateVariant(
                          id: comboVariant.id,
                          name: comboVariant.name,
                          price: newPrice,
                          sku: comboVariant.sku,
                          isAvailable: comboVariant.isAvailable,
                          isCombo: true,
                          imageUrl: img ?? comboVariant.imageUrl,
                          value: comboVariant.value?.round(),
                          unit: comboVariant.unit,
                        ));
                      }
                    },
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Редактировать'),
            ),
            if (comboVariant != null && state is AdminEntitiesLoaded)
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => ComboItemsDialog(
                      comboVariantId: comboVariant.id,
                      comboVariantName: item.name,
                      allVariants:
                          List<VariantResponse>.from(state.variants),
                      productNames: {
                        for (final p in state.products) p.id: p.name,
                      },
                      onChanged: () => bloc.add(LoadAllEntities()),
                    ),
                  );
                },
                icon: const Icon(Icons.fastfood),
                label: const Text('Состав комбо'),
              ),
            ElevatedButton.icon(
              onPressed: () => bloc.add(DeleteProduct(id: item.id, hard: true)),
              icon: const Icon(Icons.delete),
              label: const Text('Удалить'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMiniItem(
      BuildContext context, String entity, dynamic item, bool isWide) {

    if (entity == 'combo') entity = 'product';
    switch (entity) {
      case 'category':

        final scheme = Theme.of(context).colorScheme;
        return Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.category_outlined,
                  color: scheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(item.name,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ],
        );
      case 'product':
        return Row(
          children: [
            if (item.imageUrl != null)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.fullImageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  ),
                ),
              ),
            if (item.imageUrl == null)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.image, color: Colors.white38),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(item.name,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ],
        );
      case 'variant':
        return Row(
          children: [
            if (item.imageUrl != null)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.fullImageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  ),
                ),
              ),
            if (item.imageUrl == null)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.image, color: Colors.white38),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(item.name,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ],
        );
      case 'modifier':
        return Row(
          children: [
            _modifierThumb(item, 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(item.name,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ],
        );
      case 'modifierGroup':
        return Row(
          children: [
            const Icon(Icons.group_work),
            const SizedBox(width: 16),
            Expanded(
              child: Text(item.name,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
          ],
        );
      case 'cart':
        return Row(
          children: [
            const Icon(Icons.shopping_cart),
            const SizedBox(width: 16),
            Expanded(
              child:
                  Text('Cart', style: Theme.of(context).textTheme.titleMedium),
            ),
          ],
        );
      case 'orders':
        return Row(
          children: [
            const Icon(Icons.receipt_long),
            const SizedBox(width: 16),
            Expanded(
              child:
                  Text('Order', style: Theme.of(context).textTheme.titleMedium),
            ),
          ],
        );
      case 'users':
        return Row(
          children: [
            const Icon(Icons.people),
            const SizedBox(width: 16),
            Expanded(
              child:
                  Text('User', style: Theme.of(context).textTheme.titleMedium),
            ),
          ],
        );
      default:
        return Text(item.toString());
    }
  }

  Widget _buildFullItem(BuildContext context, String entity, dynamic item,
      bool isWide, AdminEntitiesState state) {
    final bloc = context.read<AdminEntitiesBloc>();

    if (entity == 'combo') {
      return _buildComboFull(context, item, isWide, state, bloc);
    }
    switch (entity) {
      case 'category':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: isWide ? 180 : 120,
                  height: isWide ? 180 : 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.image, color: Colors.white38, size: 48),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: Theme.of(context).textTheme.headlineSmall),
                      Text('ID: ${item.id}',
                          style: Theme.of(context).textTheme.bodySmall),
                      if (item.sortOrder != null)
                        Text('Sort: ${item.sortOrder}',
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => CategoryCrudDialog(
                        initialName: item.name,
                        initialSortOrder: item.sortOrder,
                        onSubmit: (name, sortOrder) {
                          bloc.add(UpdateCategory(
                              id: item.id, name: name, sortOrder: sortOrder));
                        },
                        isEdit: true,
                        onHardDelete: () {
                          bloc.add(DeleteCategory(id: item.id, hard: true));
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Редактировать'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    bloc.add(DeleteCategory(id: item.id, hard: false));
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Удалить'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                const SizedBox(width: 12),
                if (item.isDeleted == true)
                  ElevatedButton.icon(
                    onPressed: () {
                      bloc.add(RestoreCategory(id: item.id));
                    },
                    icon: const Icon(Icons.restore),
                    label: const Text('Восстановить'),
                  ),
              ],
            ),
            if (state is AdminEntitiesLoaded)
              ...state.products
                  .where((p) =>
                      p.category.id == item.id && !_isComboProduct(p))
                  .map((product) => Padding(
                        padding: const EdgeInsets.only(left: 24.0, top: 16),
                        child: _buildFullItem(
                            context, 'product', product, isWide, state),
                      )),
          ],
        );
      case 'product':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.imageUrl != null)
                  Container(
                    width: isWide ? 180 : 120,
                    height: isWide ? 180 : 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        item.fullImageUrl,
                        width: isWide ? 180 : 120,
                        height: isWide ? 180 : 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.image, size: 48);
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      ),
                    ),
                  ),
                if (item.imageUrl == null)
                  Container(
                    width: isWide ? 180 : 120,
                    height: isWide ? 180 : 120,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.restaurant_menu,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                      size: 48,
                    ),
                  ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: Theme.of(context).textTheme.headlineSmall),
                      Text('ID: ${item.id}',
                          style: Theme.of(context).textTheme.bodySmall),
                      if (item.description != null)
                        Text('Desc: ${item.description}',
                            style: Theme.of(context).textTheme.bodySmall),
                      if (item.sortOrder != null)
                        Text('Sort: ${item.sortOrder}',
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    final categories =
                        state is AdminEntitiesLoaded ? state.categories : [];
                    showDialog(
                      context: context,
                      builder: (ctx) => ProductCrudDialog(
                        initialCategoryId: item.category.id,
                        initialName: item.name,
                        initialDescription: item.description,
                        initialSortOrder: item.sortOrder,
                        initialImageUrl: item.imageUrl,
                        categories: categories,
                        onSubmit: (categoryId, name, description, sortOrder,
                            imageUrl) {
                          bloc.add(UpdateProduct(
                            id: item.id,
                            categoryId: categoryId,
                            name: name,
                            description: description,
                            sortOrder: sortOrder,
                            imageUrl: imageUrl,
                          ));
                        },
                        isEdit: true,
                        onHardDelete: () {
                          bloc.add(DeleteProduct(id: item.id, hard: true));
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Редактировать'),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      bloc.add(DeleteProduct(id: item.id, hard: false)),
                  icon: const Icon(Icons.delete),
                  label: const Text('Удалить'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                if (item.isDeleted == true)
                  ElevatedButton.icon(
                    onPressed: () => bloc.add(RestoreProduct(id: item.id)),
                    icon: const Icon(Icons.restore),
                    label: const Text('Восстановить'),
                  ),

                ElevatedButton.icon(
                  onPressed: () {
                    final products =
                        state is AdminEntitiesLoaded ? state.products : [];
                    showDialog(
                      context: context,
                      builder: (ctx) => VariantCrudDialog(
                        initialProductId: item.id,
                        products: products,
                        onSubmit: (
                            {required int productId,
                            required String name,
                            required int price,
                            required String sku,
                            required bool isAvailable,
                            required bool isCombo,
                            String? description,
                            String? imageUrl,
                            int? value,
                            String? unit}) {
                          bloc.add(CreateVariant(
                            productId: productId,
                            name: name,
                            price: price,
                            sku: sku,
                            isAvailable: isAvailable,
                            isCombo: isCombo,
                            imageUrl: imageUrl,
                            value: value,
                            unit: unit,
                          ));
                        },
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить вариант'),
                ),

                if (state is AdminEntitiesLoaded)
                  ElevatedButton.icon(
                    onPressed: () {
                      final groups = state.modifierGroups;
                      final nameToId = <String, int>{
                        for (final g in groups) g.name.toString(): g.id,
                      };
                      final allGroups = nameToId.keys.toList();
                      final selectedNames = <String>{};
                      for (final v in item.variants) {
                        for (final g in v.modifierGroups) {
                          selectedNames.add(g.name.toString());
                        }
                      }
                      showDialog(
                        context: context,
                        builder: (ctx) => AssociationDialog(
                          allGroups: allGroups,
                          selectedGroups: selectedNames.toList(),
                          onSubmit: (selected) {
                            final toLink = <int>[];
                            final toUnlink = <int>[];
                            for (final name in allGroups) {
                              final id = nameToId[name];
                              if (id == null) continue;
                              if (selected.contains(name)) {
                                toLink.add(id);
                              } else {
                                toUnlink.add(id);
                              }
                            }
                            bloc.add(UpdateProductModifierGroups(
                              productId: item.id,
                              groupIdsToLink: toLink,
                              groupIdsToUnlink: toUnlink,
                            ));
                          },
                        ),
                      );
                    },
                    icon: const Icon(Icons.link),
                    label: const Text('Группы модификаторов'),
                  ),
              ],
            ),
            if (item.variants.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Варианты', style: Theme.of(context).textTheme.titleMedium),
              ...item.variants.map(
                (variant) => Padding(
                  padding: const EdgeInsets.only(left: 16, top: 8),
                  child: _buildFullItem(
                    context,
                    'variant',
                    variant,
                    isWide,
                    state,
                  ),
                ),
              ),
            ],
          ],
        );

      case 'variant':
        return Wrap(
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: 24,
            runSpacing: 12,
            children: [
              Row(
                children: [
                  if (item.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(item.fullImageUrl,
                          width: isWide ? 180 : 120,
                          height: isWide ? 180 : 120,
                          fit: BoxFit.cover,

                          errorBuilder: (_, __, ___) =>
                              _variantImagePlaceholder(isWide)),
                    ),
                  if (item.imageUrl == null) _variantImagePlaceholder(isWide),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: Theme.of(context).textTheme.headlineSmall),
                      Text('ID: ${item.id}',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text('Цена: ${item.price} ₽',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text('SKU: ${item.sku}',
                          style: Theme.of(context).textTheme.bodySmall),
                      if (item.isCombo)
                        const Text('Комбо-набор',
                            style: TextStyle(color: Colors.orange)),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      final products =
                          state is AdminEntitiesLoaded ? state.products : [];
                      showDialog(
                        context: context,
                        builder: (ctx) => VariantCrudDialog(
                          initialProductId: item.productId,
                          initialName: item.name,
                          initialPrice: item.price,
                          initialSku: item.sku,
                          initialIsAvailable: item.isAvailable,
                          initialIsCombo: item.isCombo,
                          initialImageUrl: item.imageUrl,
                          initialValue: item.value?.round(),
                          initialUnit: item.unit,
                          products: products,
                          onSubmit: (
                              {required int productId,
                              required String name,
                              required int price,
                              required String sku,
                              required bool isAvailable,
                              required bool isCombo,
                              String? description,
                              String? imageUrl,
                              int? value,
                              String? unit}) {
                            bloc.add(UpdateVariant(
                              id: item.id,
                              name: name,
                              price: price,
                              imageUrl: imageUrl,
                              sku: sku,
                              isAvailable: isAvailable,
                              isCombo: isCombo,
                              value: value,
                              unit: unit,
                            ));
                          },
                          isEdit: true,
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text(
                        'Редактировать'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      bloc.add(DeleteVariant(id: item.id, hard: false));
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Удалить'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                  const SizedBox(width: 12),
                  if (item.isDeleted == true)
                    ElevatedButton.icon(
                      onPressed: () {
                        bloc.add(RestoreVariant(id: item.id));
                      },
                      icon: const Icon(Icons.restore),
                      label: const Text('Восстановить'),
                    ),
                ],
              ),

              if (item.isCombo == true && state is AdminEntitiesLoaded)
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => ComboItemsDialog(
                        comboVariantId: item.id,
                        comboVariantName: item.name,
                        allVariants: List<VariantResponse>.from(state.variants),
                        productNames: {
                          for (final p in state.products) p.id: p.name,
                        },
                        onChanged: () => bloc.add(LoadAllEntities()),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fastfood),
                  label: const Text('Состав комбо'),
                ),
            ],
        );
      case 'modifier':
        return Wrap(
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: 24,
            runSpacing: 12,
            children: [
              Row(
                children: [
                  _modifierThumb(item, 48),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: Theme.of(context).textTheme.headlineSmall),
                      Text('ID: ${item.id}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => ModifierCrudDialog(
                          groups: state is AdminEntitiesLoaded
                              ? state.modifierGroups
                                  .map((g) => {'id': g.id, 'name': g.name})
                                  .toList()
                              : <Map<String, dynamic>>[],
                          initialName: item.name,
                          initialPriceDelta: item.priceDelta,
                          initialImageUrl: item.imageUrl,
                          initialGroupId: item.groupId,
                          onSubmit: (name, priceDelta, groupId, imageUrl) {
                            bloc.add(UpdateModifier(
                                id: item.id,
                                name: name,
                                price: priceDelta,
                                groupId: groupId,
                                imageUrl: imageUrl));
                          },
                          isEdit: true,
                          onHardDelete: () {
                            bloc.add(DeleteModifier(id: item.id, hard: true));
                          },
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Редактировать'),
                  ),
                  const SizedBox(width: 12),
                  if (item.isDeleted != true)
                    ElevatedButton.icon(
                      onPressed: () =>
                          bloc.add(DeleteModifier(id: item.id, hard: false)),
                      icon: const Icon(Icons.delete),
                      label: const Text('Удалить'),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  if (item.isDeleted == true) ...[
                    ElevatedButton.icon(
                      onPressed: () => bloc.add(RestoreModifier(id: item.id)),
                      icon: const Icon(Icons.restore),
                      label: const Text('Восстановить'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () =>
                          bloc.add(DeleteModifier(id: item.id, hard: true)),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Удалить безвозвратно'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade900),
                    ),
                  ],
                ],
              ),
            ],
        );
      case 'modifierGroup':
        return Wrap(
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: 24,
            runSpacing: 12,
            children: [
              Row(
                children: [
                  const Icon(Icons.group_work, size: 48),
                  const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: Theme.of(context).textTheme.headlineSmall),
                      Text('ID: ${item.id}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => ModifierGroupCrudDialog(
                          initialName: item.name,
                          initialIsRequired: item.isRequired,
                          initialIsMultiselect: item.isMultiselect,
                          onSubmit: (name, isRequired, isMultiselect) {
                            bloc.add(UpdateModifierGroup(
                              id: item.id,
                              name: name,
                              isRequired: isRequired,
                              isMultiselect: isMultiselect,
                            ));
                          },
                          isEdit: true,
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Редактировать'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      bloc.add(DeleteModifierGroup(id: item.id, hard: false));
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Удалить'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                  const SizedBox(width: 12),
                  if (item.isDeleted == true)
                    ElevatedButton.icon(
                      onPressed: () {
                        bloc.add(RestoreModifierGroup(id: item.id));
                      },
                      icon: const Icon(Icons.restore),
                      label: const Text('Восстановить'),
                    ),
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => ModifierCrudDialog(
                          groups: state is AdminEntitiesLoaded
                              ? state.modifierGroups
                                  .map((g) => {'id': g.id, 'name': g.name})
                                  .toList()
                              : <Map<String, dynamic>>[],
                          initialGroupId: item.id,
                          onSubmit: (name, priceDelta, groupId, imageUrl) {
                            bloc.add(CreateModifier(
                              groupId: groupId,
                              name: name,
                              price: priceDelta,
                              imageUrl: imageUrl,
                            ));
                          },
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Добавить модификатор'),
                  ),
                ],
              ),
              if (item.modifiers.isNotEmpty) ...[
                const SizedBox(width: 24),
                SizedBox(
                  width: 320,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Модификаторы',
                          style: Theme.of(context).textTheme.titleMedium),
                      ...item.modifiers.map(
                        (modifier) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(modifier.name),
                          subtitle: Text('+${modifier.priceDelta} ₽'),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                tooltip: 'Редактировать',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => ModifierCrudDialog(
                                      groups: state is AdminEntitiesLoaded
                                          ? state.modifierGroups
                                              .map((g) =>
                                                  {'id': g.id, 'name': g.name})
                                              .toList()
                                          : <Map<String, dynamic>>[],
                                      initialName: modifier.name,
                                      initialPriceDelta: modifier.priceDelta,
                                      initialImageUrl: modifier.imageUrl,
                                      initialGroupId: item.id,
                                      isEdit: true,
                                      onSubmit: (name, priceDelta, groupId, imageUrl) {
                                        bloc.add(UpdateModifier(
                                          id: modifier.id,
                                          name: name,
                                          price: priceDelta,
                                          groupId: groupId,
                                          imageUrl: imageUrl,
                                        ));
                                      },
                                      onHardDelete: () {
                                        bloc.add(DeleteModifier(
                                            id: modifier.id, hard: true));
                                      },
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.error),
                                tooltip: 'Удалить',
                                onPressed: () => bloc.add(
                                    DeleteModifier(id: modifier.id, hard: true)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
        );
      default:
        return Text(item.toString());
    }
  }
}
