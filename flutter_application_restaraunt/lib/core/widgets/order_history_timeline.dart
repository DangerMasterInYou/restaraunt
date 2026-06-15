import 'package:flutter/material.dart';

import '/core/repositories/users/client/restaraunt/orders/dto/dto.dart';

class OrderHistoryTimeline extends StatelessWidget {
  const OrderHistoryTimeline({super.key, required this.history});

  final List<OrderStatusHistoryDTO> history;

  static String _fmt(DateTime d) {
    final l = d.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(l.day)}.${two(l.month)}.${l.year} ${two(l.hour)}:${two(l.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < history.length; i++)
          _HistoryTile(
            time: _fmt(history[i].createdAt),
            status: history[i].status,
            note: history[i].note,
            isFirst: i == 0,
            isLast: i == history.length - 1,
          ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.time,
    required this.status,
    required this.note,
    required this.isFirst,
    required this.isLast,
  });

  final String time;
  final String status;
  final String? note;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final segments = _segments(theme);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Column(
            children: [
              Container(
                width: 2,
                height: 6,
                color: isFirst ? Colors.transparent : cs.outlineVariant,
              ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 2),
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : cs.outlineVariant,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(status,
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(time,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  ...segments,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _segments(ThemeData theme) {
    final cs = theme.colorScheme;
    final note = this.note;
    if (note == null || note.trim().isEmpty) return const [];
    final parts = note
        .split(RegExp(r'[.;]\s+'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty);
    final widgets = <Widget>[];
    for (final p in parts) {
      final lower = p.toLowerCase();
      var color = cs.onSurfaceVariant;
      var icon = Icons.notes;
      if (lower.startsWith('добавлено')) {
        color = Colors.green.shade600;
        icon = Icons.add_circle_outline;
      } else if (lower.startsWith('убрано')) {
        color = cs.error;
        icon = Icons.remove_circle_outline;
      } else if (lower.contains('доплат')) {
        color = cs.primary;
        icon = Icons.price_change_outlined;
      } else if (lower.contains('возврат')) {
        color = cs.error;
        icon = Icons.keyboard_return;
      } else if (lower.startsWith('сумма')) {
        color = cs.onSurface;
        icon = Icons.payments_outlined;
      }
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(p,
                  style: theme.textTheme.bodySmall?.copyWith(color: color)),
            ),
          ],
        ),
      ));
    }
    return widgets;
  }
}
