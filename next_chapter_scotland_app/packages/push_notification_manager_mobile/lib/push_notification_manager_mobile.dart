import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase_options.dart';
import 'notification_service.dart';
import 'package:push_notification_manager_platform_interface/push_notification_manager_platform_interface.dart';

class PushNotificationManagerMobile extends PushNotificationManagerPlatform {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  StreamSubscription<String>? _fcmTokenRefreshSub;

  static void registerWith() {
    PushNotificationManagerPlatform.instance = PushNotificationManagerMobile();
  }

  @override
  Future<void> initNotifications({
    required bool notificationsEnabled,
    required Future<void> Function(String token) onToken,
  }) async {
    if (!notificationsEnabled) return;

    await FirebaseMessaging.instance.requestPermission();
    await FirebaseMessaging.instance.getAPNSToken();

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await onToken(token);
    }

    _fcmTokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await onToken(newToken);
    });
  }

  @override
  Future<void> initFirebaseAndLocalNotifications() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await _initLocalNotifications();
    await NotificationService().init(flutterLocalNotificationsPlugin);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  @override
  Future<void> requestPermissionsIfNeeded() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  @override
  Future<void> removeFcmToken({
    required Future<void> Function(String token) onRemove,
  }) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await onRemove(token);
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await flutterLocalNotificationsPlugin.initialize(settings);
  }

  @override
  Future<void> dispose() async {
    await _fcmTokenRefreshSub?.cancel();
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final plugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: androidSettings);
  await plugin.initialize(settings);

  final notification = message.notification;
  if (notification != null) {
    plugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'default_channel',
          'Default Channel',
          importance: Importance.max,
        ),
      ),
    );
  }
}

// class PushNotificationManager {
//   final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//   late StreamSubscription<String>? _fcmTokenRefreshSub;
//   late StreamSubscription<AuthState>? _authStateSub;
//   late SupabaseClient _supabase;

//   Future<void> initNotifications(SupabaseClient supabase) async {
//     _supabase = supabase;

//     await FirebaseMessaging.instance.requestPermission();
//     await FirebaseMessaging.instance.getAPNSToken();

//     final fcmToken = await FirebaseMessaging.instance.getToken();     
//     if (fcmToken != null) {
//       await _setFcmToken(fcmToken);
//     }

//     _fcmTokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) async {
//       await _setFcmToken(fcmToken);
//     });

//     _authStateSub = supabase.auth.onAuthStateChange.listen((event) async {
//       if (event.event == AuthChangeEvent.signedIn) {
//         final fcmToken = await FirebaseMessaging.instance.getToken();     
//         if (fcmToken != null) {
//           await _setFcmToken(fcmToken);
//         }
//       }
//     });
//   }

//   Future<void> initFirebase() async {
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
//     await _initLocalNotifications();    
//     await NotificationService().init(flutterLocalNotificationsPlugin);
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//   }

//   Future<void> removeFcmToken() async {
//     final user = _supabase.auth.currentUser;
//     if (user == null) return;

//     final token = await FirebaseMessaging.instance.getToken();

//     if (token != null) {
//       await _supabase
//         .from('user_fcm_tokens')
//         .delete()
//         .eq('user_id', user.id)
//         .eq('fcm_token', token);
//     }
//   }

//   Future<void> requestPermissionsIfNeeded() async {
//     NotificationSettings settings = await FirebaseMessaging.instance.getNotificationSettings();
//     if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
//       await FirebaseMessaging.instance.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//       );
//     }

//     if (settings.authorizationStatus == AuthorizationStatus.authorized || settings.authorizationStatus == AuthorizationStatus.provisional) {
//       final token = await FirebaseMessaging.instance.getToken();
//       if (token != null) {
//         await _setFcmToken(token);
//       }
//     }
//   }
  
//   void dispose() {
//     _fcmTokenRefreshSub?.cancel();
//     _authStateSub?.cancel();
//   }

//   Future<void> _initLocalNotifications() async {
//     const AndroidInitializationSettings androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');

//     const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

//     const InitializationSettings initSettings =
//         InitializationSettings(android: androidSettings, iOS: iosSettings);

//     await flutterLocalNotificationsPlugin.initialize(initSettings);
//   }

//   // For displaying notifications when app is running in background
//   Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//     // Initialize FlutterLocalNotificationsPlugin
//     final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//     final InitializationSettings initializationSettings =
//         InitializationSettings(android: initializationSettingsAndroid);
//     await flutterLocalNotificationsPlugin.initialize(initializationSettings);

//     // Show notification
//     RemoteNotification? notification = message.notification;
//     if (notification != null) {
//       flutterLocalNotificationsPlugin.show(
//         notification.hashCode,
//         notification.title,
//         notification.body,
//         NotificationDetails(
//           android: AndroidNotificationDetails(
//             'default_channel', // Must match channel ID in manifest
//             'Default Channel',
//             importance: Importance.max,
//           ),
//         ),
//       );
//     }
//   }

//   Future<void> _setFcmToken(String fcmToken) async {
//     final userId = _supabase.auth.currentUser?.id;
//     if (userId != null) {
//       await _supabase
//         .from('user_fcm_tokens')
//         .upsert({
//           'user_id': userId,
//           'fcm_token': fcmToken,
//         }, onConflict: 'user_id, fcm_token');
//     }
//   }
// }

