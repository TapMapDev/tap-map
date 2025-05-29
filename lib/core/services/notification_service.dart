import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tap_map/core/network/dio_client.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final SharedPreferences _prefs = GetIt.instance<SharedPreferences>();
  final DioClient _dioClient = DioClient();

  Future<void> initialize() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('User granted permission: ${settings.authorizationStatus}');

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('ic_notification');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
        },
      );

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
      }

      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground message received: ${message.notification?.title}');
        _showNotification(message);
      });

      // Оборачиваем в try-catch, чтобы приложение не блокировалось при ошибке с токеном
      try {
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          try {
            await _dioClient.registerFcmToken(token);
            debugPrint('FCM token registered successfully: $token');
          } catch (e) {
            debugPrint('FCM token registration failed: $e');
          }
        }
      } catch (e) {
        debugPrint('Failed to get FCM token: $e');
        // Продолжаем работу приложения, даже если не получили токен
      }

      _firebaseMessaging.onTokenRefresh.listen((token) async {
        try {
          await _dioClient.registerFcmToken(token);
          debugPrint('FCM token refreshed and registered successfully: $token');
        } catch (e) {
          debugPrint('FCM token refresh failed: $e');
        }
      });
    } catch (e) {
      // Обрабатываем все ошибки инициализации, чтобы не блокировать запуск приложения
      debugPrint('Notification service initialization failed: $e');
    }
  }

  Future<void> _showNotification(RemoteMessage message) async {
    final title = message.notification?.title ?? message.data['title'] ?? 'Новое уведомление';
    final body = message.notification?.body ?? message.data['body'] ?? '';

    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        icon: 'ic_notification',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _flutterLocalNotificationsPlugin.show(
        title.hashCode ^ body.hashCode,
        title,
        body,
        details,
        payload: message.data.isNotEmpty ? message.data.toString() : null,
      );
      debugPrint('Foreground notification shown');
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }
}
