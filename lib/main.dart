import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'pages/home_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeNotifications();
  await requestNotificationPermission();

  runApp(MyApp());

  // 앱 실행 시 테스트용 알림 실행
  // testDummyExpirationAlert();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[200],
      ),
      home: HomePage(),
    );
  }
}

// ✅ 알림 초기화
Future<void> initializeNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

// ✅ Android 13 이상에서 알림 권한 요청
Future<void> requestNotificationPermission() async {
  final deviceInfo = await DeviceInfoPlugin().androidInfo;
  if (deviceInfo.version.sdkInt >= 33) {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }
}

// ✅ 알림 보내는 함수
Future<void> showExpirationNotification(String itemName, int daysLeft) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'expiration_channel',
    '유통기한 알림',
    channelDescription: '유통기한이 임박한 품목에 대한 알림',
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


