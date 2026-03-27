import 'package:push_notification_manager_platform_interface/push_notification_manager_platform_interface.dart';

class PushNotificationManager {
  static final PushNotificationManager _instance = PushNotificationManager._internal();

  factory PushNotificationManager() => _instance;
  PushNotificationManager._internal();

  Future<void> initNotifications({
    required bool notificationsEnabled, 
    required Future<void> Function(String token) onToken
  }) {
    return PushNotificationManagerPlatform.instance.initNotifications(
      notificationsEnabled: notificationsEnabled,
      onToken: onToken,
    );
  }

  Future<void> initFirebaseAndLocalNotifications() {
    return PushNotificationManagerPlatform.instance.initFirebaseAndLocalNotifications();
  }

  Future<void> requestPermissionsIfNeeded() {
    return PushNotificationManagerPlatform.instance.requestPermissionsIfNeeded();
  }

  Future<void> removeFcmToken({
    required Future<void> Function(String token) onRemove,
  }) {
    return PushNotificationManagerPlatform.instance.removeFcmToken(onRemove: onRemove);
  }

  Future<void> dispose() {
    return PushNotificationManagerPlatform.instance.dispose();
  }
}