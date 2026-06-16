import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '/core/repositories/favorites/favorites.dart';
import '/core/services/app_toast.dart';

Future<String?> _promptName(
  BuildContext context, {
  required String title,
  String initial = '',
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 100,
        decoration: const InputDecoration(
          hintText: 'Например: Праздник',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('Сохранить'),
        ),
      ],
    ),
  );
}

Future<void> showAddToFavoriteGroup(
  BuildContext context, {
  required int productVariantId,
  required List<int> modifierIds,
  String? subtitle,
}) async {
  final repo = GetIt.I<AbstractFavoritesRepository>();
  List<FavoriteGroupDTO> groups;
  try {
    groups = await repo.listGroups();
  } catch (e) {
    if (context.mounted) AppToast.fromError(context, e);
    return;
  }
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Добавить в избранное',
                  style: Theme.of(ctx).textTheme.titleLarge),
              if (subtitle != null && subtitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child:
                      Text(subtitle, style: Theme.of(ctx).textTheme.bodySmall),
                ),
              const SizedBox(height: 12),
              Flexible(
                child: groups.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('У вас пока нет групп. Создайте первую.'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: groups.length,
                        itemBuilder: (_, i) {
                          final g = groups[i];
                          return ListTile(
                            leading: const Icon(Icons.folder_outlined),
                            title:
                                Text(g.name, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${g.items.length} поз.'),
                            onTap: () async {
                              try {
                                await repo.addItem(
                                  g.id,
                                  productVariantId: productVariantId,
                                  modifierIds: modifierIds,
                                );
                                if (ctx.mounted) Navigator.pop(ctx);
                                if (context.mounted) {
                                  AppToast.success(
                                      context, 'Добавлено в «${g.name}»');
                                }
                              } catch (e) {
                                if (ctx.mounted) AppToast.fromError(ctx, e);
                              }
                            },
                          );
                        },
                      ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.create_new_folder_outlined),
                title: const Text('Создать новую группу'),
                onTap: () async {
                  final name =
                      await _promptName(ctx, title: 'Новая группа избранного');
                  if (name == null || name.isEmpty) return;
                  try {
                    final group = await repo.createGroup(name);
                    await repo.addItem(
                      group.id,
                      productVariantId: productVariantId,
                      modifierIds: modifierIds,
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (context.mounted) {
                      AppToast.success(context, 'Добавлено в «${group.name}»');
                    }
                  } catch (e) {
                    if (ctx.mounted) AppToast.fromError(ctx, e);
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FavoritesScreen()),
    );
  }

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _repo = GetIt.I<AbstractFavoritesRepository>();
  late Future<List<FavoriteGroupDTO>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _repo.listGroups();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  Future<void> _createGroup() async {
    final name = await _promptName(context, title: 'Новая группа избранного');
    if (name == null || name.isEmpty) return;
    try {
      await _repo.createGroup(name);
      if (mounted) setState(_reload);
    } catch (e) {
      if (mounted) AppToast.fromError(context, e);
    }
  }

  Future<void> _rename(FavoriteGroupDTO g) async {
    final name =
        await _promptName(context, title: 'Переименовать', initial: g.name);
    if (name == null || name.isEmpty || name == g.name) return;
    try {
      await _repo.renameGroup(g.id, name);
      if (mounted) setState(_reload);
    } catch (e) {
      if (mounted) AppToast.fromError(context, e);
    }
  }

  Future<void> _delete(FavoriteGroupDTO g) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Удалить «${g.name}»?'),
        content: const Text('Группа и её содержимое будут удалены.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.deleteGroup(g.id);
      if (mounted) setState(_reload);
    } catch (e) {
      if (mounted) AppToast.fromError(context, e);
    }
  }

  Future<void> _addGroupToCart(FavoriteGroupDTO g) async {
    if (g.items.isEmpty) {
      AppToast.info(context, 'Группа пуста');
      return;
    }
    try {
      final added = await _repo.addGroupToCart(g.id);
      if (mounted) {
        AppToast.success(context, 'Добавлено в корзину: $added поз.');
      }
    } catch (e) {
      if (mounted) AppToast.fromError(context, e);
    }
  }

  Future<void> _removeItem(FavoriteItemDTO item) async {
    try {
      await _repo.removeItem(item.id);
      if (mounted) setState(_reload);
    } catch (e) {
      if (mounted) AppToast.fromError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createGroup,
        icon: const Icon(Icons.add),
        label: const Text('Группа'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<FavoriteGroupDTO>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Ошибка: ${snap.error}',
                      textAlign: TextAlign.center),
                ),
              ]);
            }
            final groups = snap.data ?? [];
            if (groups.isEmpty) {
              return ListView(children: [
                const SizedBox(height: 100),
                Icon(Icons.bookmark_border,
                    size: 72,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Center(
                  child: Text('Пока нет избранных групп',
                      style: theme.textTheme.titleMedium),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Создайте группу и добавляйте в неё блюда из меню',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
              ]);
            }
            // По умолчанию группы свёрнуты; раскрываем только первую группу,
            // у которой есть позиции.
            final firstNonEmpty =
                groups.indexWhere((g) => g.items.isNotEmpty);
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              itemCount: groups.length,
              itemBuilder: (context, i) =>
                  _groupCard(theme, groups[i], expanded: i == firstNonEmpty),
            );
          },
        ),
      ),
    );
  }

  Widget _groupCard(ThemeData theme, FavoriteGroupDTO g,
      {bool expanded = false}) {
    final cs = theme.colorScheme;
    final total = g.items.fold<int>(0, (s, it) => s + it.price * it.quantity);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey('fav_group_${g.id}'),
          initiallyExpanded: expanded,
          tilePadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
          leading: CircleAvatar(
            backgroundColor: cs.primaryContainer,
            foregroundColor: cs.onPrimaryContainer,
            child: const Icon(Icons.folder_rounded),
          ),
          title: Text(g.name,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis),
          subtitle: Text(
            g.items.isEmpty ? 'Пусто' : '${g.items.length} поз. · $total ₽',
            style: theme.textTheme.bodySmall,
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'rename') _rename(g);
              if (v == 'delete') _delete(g);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'rename',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.edit),
                  title: Text('Переименовать'),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.delete, color: cs.error),
                  title: Text('Удалить', style: TextStyle(color: cs.error)),
                ),
              ),
            ],
          ),
          children: [
            if (g.items.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Добавьте блюда из меню',
                      style: theme.textTheme.bodySmall),
                ),
              ),
            for (final item in g.items) _itemTile(theme, item),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _addGroupToCart(g),
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('Добавить всё в корзину'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemTile(ThemeData theme, FavoriteItemDTO item) {
    final name = '${item.productName ?? 'Товар'}'
        '${item.variantName != null ? ' · ${item.variantName}' : ''}';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: _thumb(theme, item),
      title: Text(name, overflow: TextOverflow.ellipsis),
      subtitle: item.modifierNames.isEmpty
          ? null
          : Text('+ ${item.modifierNames.join(', ')}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${item.price} ₽',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'Убрать',
            onPressed: () => _removeItem(item),
          ),
        ],
      ),
    );
  }

  Widget _thumb(ThemeData theme, FavoriteItemDTO item) {
    final url = item.fullImageUrl;
    final placeholder = Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.fastfood,
          color: theme.colorScheme.onSurfaceVariant, size: 22),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 48,
        height: 48,
        child: url == null
            ? placeholder
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => placeholder,
              ),
      ),
    );
  }
}
