// 📁 lib/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:capstone/services/storage_service.dart';
import 'package:capstone/services/expiration_processor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  // 🔔 플러그인 인스턴스 (싱글턴)
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  // ⚙️ 초기화 (main.dart에서 앱 시작 시 1회 호출 권장)
  static Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      'expiration_channel',
      '유통기한 알림',
      description: '유통기한 임박 품목 알림',
      importance: Importance.max,
    );
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.createNotificationChannel(channel);
  }

  /// ✅ 알림 권한 요청 (Android 13+)
  static Future<void> requestPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  /// ✅ 날짜가 바뀌면 notificationShown 플래그 초기화
  static Future<void> resetIfNewDay() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final last = (await StorageService.getString('lastNotificationDate')) ?? '';
    final prefs = await SharedPreferences.getInstance();
    if (last != today) {
      await StorageService.setBool('notificationShown', false);
      await prefs.setString('lastNotificationDate', today);
    }
  }

  /// ✅ D-7 이내 항목 알림 전송 (여러 개)
  static Future<void> triggerExpirationCheck() async {
    final list = await StorageService.loadExpirationList();
    int id = 0;
    for (final item in list) {
      if (item['expirationDate'] != null) {
        final dday = ExpirationProcessor.calculateDday(item['expirationDate']);
        if (dday >= 0 && dday <= 7) {
          await showNotification(
            '${item['name']} 유통기한 임박!',
            '남은 일수: D-$dday',
            id: id++,
          );
        }
      }
    }
  }

  /// ✅ 개별 알림 표시
  static Future<void> showNotification(String title, String body, {required int id}) async {
    const androidDetails = AndroidNotificationDetails(
      'expiration_channel',
      '유통기한 알림',
      channelDescription: '유통기한 임박 알림',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details);
  }

  /// ❗ OCR 등록 실패 안내 다이얼로그
  static Future<void> showFailDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('일부 품목 등록 실패',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 22),
              const Text('유통기한 리스트/가계부는\n다른 기능을 이용해 주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
