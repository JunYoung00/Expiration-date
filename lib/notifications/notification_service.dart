// lib/notifications/notification_service.dart
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // ✅ 알림 초기화
  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    await _requestPermissionIfNeeded();
  }

  // ✅ Android 13+ 알림 권한 요청
  static Future<void> _requestPermissionIfNeeded() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        var status = await Permission.notification.status;
        if (!status.isGranted) {
          await Permission.notification.request();
        }
      }
    }
  }

  // ✅ 알림 띄우는 함수
  static Future<void> showExpirationNotification(String itemName, int daysLeft) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'expiration_channel',
      '유통기한 알림',
      channelDescription: '유통기한 임박 품목 알림',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      '$itemName 유통기한 주의',
      '$daysLeft일 남았습니다!',
      platformDetails,
    );
  }

  // ✅ 테스트용 더미 알림
  static void testDummyExpirationAlert() {
    final dummyItems = [
      {'name': 'milk', 'expiration': DateTime.now().add(Duration(days: 3))},
      {'name': 'egg', 'expiration': DateTime.now().add(Duration(days: 3))},
      {'name': 'dooboo', 'expiration': DateTime.now().add(Duration(days: 3))},
    ];

    for (var item in dummyItems) {
      final name = item['name'] as String;
      final expiration = item['expiration'] as DateTime;
      final daysLeft = expiration.difference(DateTime.now()).inDays;

      if (daysLeft <= 7) {
        showExpirationNotification(name, daysLeft);
      }
    }
  }
}