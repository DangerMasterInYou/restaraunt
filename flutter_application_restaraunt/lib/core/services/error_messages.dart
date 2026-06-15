import 'package:dio/dio.dart';

String friendlyError(Object? error, {String fallback = 'Что-то пошло не так'}) {
  if (error is DioException) {

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Сервер не отвечает. Попробуйте позже';
      case DioExceptionType.connectionError:
        return 'Нет соединения с сервером';
      default:
        break;
    }

    final res = error.response;
    final code = res?.statusCode;
    if (code == null) return 'Нет соединения с сервером';

    final detail = _extractDetail(res?.data);
    final status = _statusText(code);

    if (detail != null && _hasCyrillic(detail)) {
      return '$status · $detail';
    }
    return '$status (код $code)';
  }

  var s = (error?.toString() ?? '').trim();
  s = s.replaceFirst(RegExp(r'^Exception:\s*'), '');
  if (s.isEmpty) return fallback;
  if (_hasCyrillic(s)) return s;
  return fallback;
}

String? _extractDetail(dynamic data) {
  if (data is Map) {
    final d = data['detail'];
    if (d is String) return d;
    if (d is Map && d['message'] is String) return d['message'] as String;
    if (d is List && d.isNotEmpty) {
      final first = d.first;
      if (first is Map && first['msg'] is String) return first['msg'] as String;
    }
  }
  return null;
}

bool _hasCyrillic(String s) => RegExp(r'[А-Яа-яЁё]').hasMatch(s);

String _statusText(int code) {
  switch (code) {
    case 400:
      return 'Неверный запрос';
    case 401:
      return 'Требуется вход';
    case 403:
      return 'Недостаточно прав';
    case 404:
      return 'Не найдено';
    case 409:
      return 'Конфликт данных';
    case 422:
      return 'Проверьте введённые данные';
    case 429:
      return 'Слишком много попыток';
    case 500:
      return 'Ошибка сервера';
    case 502:
    case 503:
    case 504:
      return 'Сервер временно недоступен';
    default:
      return 'Ошибка';
  }
}
