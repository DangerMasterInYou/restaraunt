import 'package:flutter/foundation.dart' show kIsWeb;

import '/api_config.dart';

/// URL возврата для ЮKassa после оплаты.
///
/// - Web: origin текущей страницы (туда ЮKassa вернёт клиента, backend добавит
///   `?paid_order=<id>` для авто-подтверждения).
/// - Мобайл: своя страница backend `/payments/return` (просит закрыть браузер и
///   вернуться в приложение). Берём абсолютный адрес из `ApiConfig.apiSiteUrl`,
///   чтобы внешний браузер устройства мог её открыть. Раньше использовался
///   дефолт backend `example.com`, из-за которого браузер подвисал
///   (нужен внешний интернет). Подтверждение оплаты — при возврате в приложение.
String? paymentReturnUrl() {
  if (kIsWeb) return Uri.base.origin;
  final base = ApiConfig.apiSiteUrl;
  if (base.isEmpty) return null;
  return '$base/payments/return';
}
