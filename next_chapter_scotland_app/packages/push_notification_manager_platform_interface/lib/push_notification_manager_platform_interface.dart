import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class PushNotificationManagerPlatform extends PlatformInterface {
  PushNotificationManagerPlatform() : super(token: _token);

  static final Object _token = Object();
  static PushNotificationManagerPlatform _instance =
      _DefaultPushNotificationManagerPlatform();

  static PushNotificationManagerPlatform get instance => _instance;

  static set instance(PushNotificationManagerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> initNotifications({
    required bool notificationsEnabled,
    required Future<void> Function(String token) onToken,
  });

  Future<void> initFirebaseAndLocalNotifications();

  Future<void> requestPermissionsIfNeeded();

  Future<void> removeFcmToken({
    required Future<void> Function(String token) onRemove,
  }); 

  Future<void> dispose();
}

class _DefaultPushNotificationManagerPlatform extends PushNotificationManagerPlatform {
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