import 'package:push_notification_manager_platform_interface/push_notification_manager_platform_interface.dart';

class PushNotificationManagerDesktop extends PushNotificationManagerPlatform {
  static void registerWith() {
    PushNotificationManagerPlatform.instance = PushNotificationManagerDesktop();
  }

  @override
  Future<void> initNotifications({
    required bool notificationsEnabled,
    required Future<void> Function(String token) onToken,
  }) async {}

  @override
  Future<void> initFirebaseAndLocalNotifications() async {}

  @override
  Future<void> requestPermissionsIfNeeded() async {}

  @override
  Future<void> removeFcmToken({
    required Future<void> Function(String token) onRemove,
  }) async {}

  @override
  Future<void> dispose() async {}
}