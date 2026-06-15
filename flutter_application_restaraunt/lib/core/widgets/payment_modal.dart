import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '/core/services/pending_payment.dart';

Future<void> showPaymentModal(
  BuildContext context, {
  required String confirmationUrl,
  required int amount,
  int? orderId,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return AlertDialog(
        title: const Text('Оплата заказа'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Сумма к оплате: $amount ₽',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              'Вы будете перенаправлены на защищённую страницу ЮKassa. '
              'После оплаты вернётесь обратно — статус обновится автоматически.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Позже'),
          ),
          FilledButton.icon(
            onPressed: () async {
              // На мобильных нет авто-возврата из браузера: запоминаем заказ,
              // чтобы подтвердить оплату при возврате в приложение (см. app.dart).
              if (!kIsWeb && orderId != null) {
                pendingOnlinePaymentOrderId = orderId;
              }
              await launchUrl(
                Uri.parse(confirmationUrl),
                webOnlyWindowName: '_self',
                mode: LaunchMode.platformDefault,
              );
              if (ctx.mounted && !kIsWeb) Navigator.of(ctx).pop();
            },
            icon: const Icon(Icons.payment),
            label: const Text('Перейти к оплате'),
          ),
        ],
      );
    },
  );
}
