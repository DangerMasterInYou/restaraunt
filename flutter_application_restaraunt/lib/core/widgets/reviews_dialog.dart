import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '/core/repositories/reviews/reviews.dart';
import '/core/services/app_toast.dart';
import '/core/utils/responsive.dart';

class ReviewsDialog extends StatefulWidget {
  const ReviewsDialog({super.key, this.canManage = false});

  final bool canManage;

  @override
  State<ReviewsDialog> createState() => _ReviewsDialogState();
}

class _ReviewsDialogState extends State<ReviewsDialog> {
  final _repo = GetIt.I<AbstractReviewsRepository>();
  late Future<List<ReviewDTO>> _future;

  String _query = '';
  int _starFilter = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _repo.getAllReviews();
  }

  List<ReviewDTO> _applyFilters(List<ReviewDTO> reviews) {
    final q = _query.trim().toLowerCase();
    return reviews.where((r) {
      if (_starFilter != 0 && r.rating != _starFilter) return false;
      if (q.isEmpty) return true;
      final haystack = [
        r.customerName,
        r.customerEmail,
        r.customerPhone,
        r.orderNumber,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  Future<void> _respond(ReviewDTO r) async {
    final controller = TextEditingController(text: r.response ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ответ заведения'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Ваш ответ клиенту'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
    if (text == null || text.isEmpty) return;
    try {
      await _repo.respond(r.id, text);
      if (mounted) {
        AppToast.success(context, 'Ответ отправлен');
        setState(_reload);
      }
    } catch (e) {
      if (mounted) AppToast.fromError(context, e);
    }
  }

  Future<void> _delete(ReviewDTO r) async {
    try {
      await _repo.deleteReview(r.id);
      if (mounted) {
        AppToast.success(context, 'Отзыв удалён');
        setState(_reload);
      }
    } catch (e) {
      if (mounted) AppToast.fromError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Отзывы'),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: dialogBodyWidth(context, max: 560),
        height: dialogBodyHeight(context, max: 540),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                isDense: true,
                prefixIcon: Icon(Icons.search),
                hintText: 'Поиск: имя, почта, телефон, № заказа',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                children: [
                  ChoiceChip(
                    label: const Text('Все'),
                    selected: _starFilter == 0,
                    onSelected: (_) => setState(() => _starFilter = 0),
                  ),
                  for (var s = 5; s >= 1; s--)
                    ChoiceChip(
                      label: Text('$s★'),
                      selected: _starFilter == s,
                      onSelected: (_) => setState(() => _starFilter = s),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                      theme.colorScheme.surface,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: FutureBuilder<List<ReviewDTO>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Ошибка: ${snap.error}'));
                    }
                    final reviews = _applyFilters(snap.data ?? []);
                    if (reviews.isEmpty) {
                      return const Center(child: Text('Отзывов не найдено'));
                    }
                    return ListView.separated(
                      itemCount: reviews.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, i) =>
                          _reviewTile(theme, reviews[i]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }

  Widget _reviewTile(ThemeData theme, ReviewDTO r) {
    final contact = [r.customerName, r.customerPhone, r.customerEmail]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Stars(rating: r.rating),
            const Spacer(),
            Text(r.orderNumber ?? '#${r.orderId}',
                style: theme.textTheme.bodySmall),
          ],
        ),
        if (contact.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(contact, style: theme.textTheme.bodySmall),
          ),
        if (r.text != null && r.text!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(r.text!),
          ),
        if (r.response != null && r.response!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Ответ: ${r.response!}',
                style: theme.textTheme.bodySmall),
          ),
        if (widget.canManage)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _respond(r),
                child: Text(r.response == null || r.response!.isEmpty
                    ? 'Ответить'
                    : 'Изменить ответ'),
              ),
              IconButton(
                tooltip: 'Удалить',
                icon: Icon(Icons.delete, color: theme.colorScheme.error),
                onPressed: () => _delete(r),
              ),
            ],
          ),
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});
  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: 18,
          color: Colors.amber.shade700,
        ),
      ),
    );
  }
}
