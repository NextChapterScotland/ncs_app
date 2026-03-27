import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  StreamSubscription<RemoteMessage>? _notificationSub;
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;

  Future<void> init(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    _notificationSub = FirebaseMessaging.onMessage.listen(_handleMessage);
    _flutterLocalNotificationsPlugin = flutterLocalNotificationsPlugin;
  }

  void _handleMessage(RemoteMessage message, ) {
    final notification = message.notification;
    if (notification != null) {
      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'channel_id', 'Channel Name',
            channelDescription: 'Important notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }

  void dispose() {
    _notificationSub?.cancel();
  }
}