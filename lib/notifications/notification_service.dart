import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static Future<void> triggerExpirationCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getString('expirationList');
    print('🔥 savedList: $savedList');
    if (savedList == null) {
      print('🚫 expirationList가 없음');
      return;
    };

    final List<Map<String, dynamic>> list =
    List<Map<String, dynamic>>.from(json.decode(savedList));
    print('📦 expirationList 로드됨: $list');

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    int id = 0; // 🔢 알림 ID를 구분하기 위한 카운터

    for (var item in list) {
      print('⏱️ 처리 중인 항목: $item');
      if (item['expirationDate'] != null) {
        final expirationDate = DateTime.parse(item['expirationDate']);
        final dday = expirationDate.difference(todayOnly).inDays;

        print('🔔 알림 조건 확인 중: $dday일 남음 → ${item['name']}');

        if (dday >= 0 && dday <= 7) {
          await showNotification(
            '${item['name']} 유통기한 임박!',
            '남은 일수: D-$dday',
            id: id++, // 🔥 각 알림에 고유 ID 부여
          );
        }
      }
    }

    await prefs.setBool('notificationShown', true);
  }

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(android: androidInit);

    await flutterLocalNotificationsPlugin.initialize(initSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'expiration_channel',
      '유통기한 알림',
      description: '유통기한 임박 품목 알림',
      importance: Importance.max,
    );

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(channel);
  }

  static Future<void> showNotification(String title, String body, {required int id}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'expiration_channel',           // 채널 ID
      '유통기한 알림',                   // 채널 이름
      channelDescription: '유통기한 임박 품목 알림',
      importance: Importance.max,      // 중요도: 상단 표시되게
      priority: Priority.high,         // 우선순위 높음
      playSound: true,                 // 🔔 소리 설정
      enableVibration: true,           // 📳 진동 설정
    );

    const NotificationDetails platformDetails =
    NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      id,         // 🔥 여기서 ID를 다르게 줘야 겹치지 않음
      title,
      body,
      platformDetails,
    );
  }
}

