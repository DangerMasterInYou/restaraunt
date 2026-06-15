import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '/core/repositories/promotions/promotion.dart';

Future<void> showPromotionsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => const _PromotionsSheet(),
  );
}

class _PromotionsSheet extends StatefulWidget {
  const _PromotionsSheet();

  @override
  State<_PromotionsSheet> createState() => _PromotionsSheetState();
}

class _PromotionsSheetState extends State<_PromotionsSheet> {
  late Future<List<PromotionDTO>> _future;

  @override
  void initState() {
    super.initState();
    _future = GetIt.I<AbstractPromotionsRepository>().getActive();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FractionallySizedBox(
      heightFactor: 0.7,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Акции', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<PromotionDTO>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Не удалось загрузить акции',
                          style: theme.textTheme.bodyMedium),
                    );
                  }
                  final promos = snapshot.data ?? const [];
                  if (promos.isEmpty) {
                    return Center(
                      child: Text('Сейчас активных акций нет',
                          style: theme.textTheme.bodyMedium),
                    );
                  }
                  return ListView.separated(
                    itemCount: promos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => _PromoCard(promo: promos[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({required this.promo});
  final PromotionDTO promo;

  String get _conditions {
    final parts = <String>[];
    if (promo.minOrderAmount != null && promo.minOrderAmount! > 0) {
      parts.add('от ${promo.minOrderAmount} ₽');
    }
    if (promo.startTime != null && promo.endTime != null) {
      parts.add('${promo.startTime}–${promo.endTime}');
    }
    if (promo.daysOfWeek != null && promo.daysOfWeek!.isNotEmpty) {
      const names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
      final days = promo.daysOfWeek!
          .split(',')
          .where((e) => e.isNotEmpty)
          .map((e) => int.tryParse(e))
          .where((e) => e != null && e >= 0 && e < 7)
          .map((e) => names[e!])
          .join(', ');
      if (days.isNotEmpty) parts.add(days);
    }
    if (promo.endDate != null) parts.add('до ${promo.endDate}');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = promo.discountLabel ??
        (promo.promoType == 'percent' && promo.discountValue != null
            ? '-${promo.discountValue}%'
            : promo.promoType == 'fixed' && promo.discountValue != null
                ? '-${promo.discountValue} ₽'
                : 'Акция');
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.primary, width: 1.5),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(promo.title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                if (promo.description != null &&
                    promo.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(promo.description!, style: theme.textTheme.bodySmall),
                ],
                if (_conditions.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 14,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(_conditions,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            )),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
