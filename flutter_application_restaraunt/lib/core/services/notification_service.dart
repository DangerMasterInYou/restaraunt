import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _channelId = 'orders_channel';
  static const _channelName = 'Заказы';

  Future<void> init() async {

    if (kIsWeb) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/launcher_icon');
      const settings = InitializationSettings(android: android);
      await _plugin.initialize(settings);

      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Уведомления о заказах',
        importance: Importance.high,
      );
      final android13 = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android13?.createNotificationChannel(channel);

      await android13?.requestNotificationsPermission();

      _ready = true;
    } catch (e) {

      debugPrint('NotificationService init failed: $e');
    }
  }

  Future<void> show(String title, String body, {int? id}) async {
    if (kIsWeb || !_ready) return;
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      );
      await _plugin.show(
        id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('NotificationService show failed: $e');
    }
  }
}
