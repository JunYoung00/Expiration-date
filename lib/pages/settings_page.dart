import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../main.dart';
import '../notifications/notification_service.dart';
import '../widgets/custom_notification_toggle.dart'; // ✅ 알림 커스텀 버튼 위젯 import

class SettingsPage extends StatefulWidget {
  final Function(ThemeMode) toggleTheme;

  SettingsPage({required this.toggleTheme});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isNotificationEnabled = true;
  bool _isDarkMode = false;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _isNotificationEnabled = _prefs.getBool('isNotificationEnabled') ?? true;
      _isDarkMode = _prefs.getString('theme') == 'dark';
    });
  }

  void _toggleNotification(bool value) async {
    setState(() {
      _isNotificationEnabled = value;
    });
    await _prefs.setBool('isNotificationEnabled', value);

    if (value) {
      await _prefs.setBool('notificationShown', false);
      await NotificationService.triggerExpirationCheck();
      print("🔔 알림 허용됨");
    } else {
      await _prefs.setBool('notificationShown', false);
      await flutterLocalNotificationsPlugin.cancelAll();
      print("🔕 알림 모두 취소됨");
    }
  }

  void _toggleTheme(bool isDark) async {
    setState(() {
      _isDarkMode = isDark;
    });
    await _prefs.setString('theme', isDark ? 'dark' : 'light');
    widget.toggleTheme(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  void _showAppInfoDialog(BuildContext context) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('앱 정보', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('버전: $version', style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            child: Text('닫기'),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // 🌗 테마 설정 토글
          SwitchListTile(
            secondary: Icon(Icons.dark_mode, color: Colors.grey),
            title: Text('다크 모드', style: TextStyle(fontSize: 18)),
            value: _isDarkMode,
            onChanged: _toggleTheme,
          ),
          Divider(),

          // 🔔 알림 설정 커스텀 버튼
          ListTile(
            leading: Icon(Icons.notifications_active, color: Colors.grey),
            title: Text('알림 설정', style: TextStyle(fontSize: 18)),
            trailing: NotificationToggle(
              isEnabled: _isNotificationEnabled,
              onToggle: () => _toggleNotification(!_isNotificationEnabled),
            ),
            onTap: () => _toggleNotification(!_isNotificationEnabled),
          ),
          Divider(),

          // ℹ️ 앱 정보
          ListTile(
            leading: Icon(Icons.info_outline, color: Colors.grey),
            title: Text('앱 정보', style: TextStyle(fontSize: 18)),
            onTap: () => _showAppInfoDialog(context),
          ),
        ],
      ),
    );
  }
}
