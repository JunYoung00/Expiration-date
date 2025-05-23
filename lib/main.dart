import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notifications/notification_service.dart';
import 'pages/home_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter 엔진 초기화// 앱 시작 시 사전 로딩
  SharedPreferences prefs = await SharedPreferences.getInstance(); // 저장된 값 불러오기
  bool isDarkMode = prefs.getBool('isDarkMode') ?? false; // 저장된 테마값 읽기

  await prefs.setBool('notificationShown', false);
  await NotificationService.initialize();
  print('🔧 알림 초기화 완료');

  final isEnabled = prefs.getBool('isNotificationEnabled') ?? true;
  final alreadyShown = prefs.getBool('notificationShown') ?? false;
  print('🔎 알림 조건 확인: isEnabled=$isEnabled / alreadyShown=$alreadyShown');

  if (isEnabled && !alreadyShown) {
    print('✅ 조건 만족 → 알림 트리거 실행');
    await NotificationService.triggerExpirationCheck();
    await prefs.setBool('notificationShown', true);
  }
  runApp(MyApp(isDarkMode: isDarkMode)); // 읽은 테마값 넘기기
}

class MyApp extends StatefulWidget {
  final bool isDarkMode; // 처음 받을 때 다크모드 여부

  MyApp({required this.isDarkMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.isDarkMode ? ThemeMode.dark : ThemeMode.light; // 최초 테마 적용
    _loadPrefs(); // SharedPreferences 준비
  }

  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> addExpenseDetail(String date, String name, int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'expenses_$date';
    List<String> existing = prefs.getStringList(key) ?? [];
    existing.add(jsonEncode({'name': name, 'amount': amount}));
    await prefs.setStringList(key, existing);
  }

  void toggleTheme(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });
    if (mode == ThemeMode.dark) {
      await _prefs.setBool('isDarkMode', true);
    } else {
      await _prefs.setBool('isDarkMode', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedTheme(
      data: _themeMode == ThemeMode.dark ? _darkTheme() : _lightTheme(),
      duration: Duration(milliseconds: 300), // 전환 애니메이션 속도
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: _themeMode,
        theme: _lightTheme(),
        darkTheme: _darkTheme(),
        home: HomePage(toggleTheme: toggleTheme),
      ),
    );
  }


  // 라이트 테마
  ThemeData _lightTheme() => ThemeData(
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600),
    ),
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: TextStyle(color: Colors.black),
      unselectedLabelStyle: TextStyle(color: Colors.grey),
      selectedIconTheme: IconThemeData(color: Colors.black),
      unselectedIconTheme: IconThemeData(color: Colors.grey),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.light(
      primary: Colors.black,
    ),
  );

  // 다크 테마
  ThemeData _darkTheme() => ThemeData(
    scaffoldBackgroundColor: Colors.black,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.black,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
    ),
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.black,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: TextStyle(color: Colors.white),
      unselectedLabelStyle: TextStyle(color: Colors.grey),
      selectedIconTheme: IconThemeData(color: Colors.white),
      unselectedIconTheme: IconThemeData(color: Colors.grey),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    ),
    colorScheme: ColorScheme.dark(
      primary: Colors.white,
    ),
  );
}
