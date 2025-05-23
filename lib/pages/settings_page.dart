import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../main.dart';
import '../notifications/notification_service.dart'; // main.dart에 있는 flutterLocalNotificationsPlugin을 가져다 씀

class SettingsPage extends StatefulWidget {
  final Function(ThemeMode) toggleTheme;

  SettingsPage({required this.toggleTheme});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isNotificationEnabled = true;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _isNotificationEnabled = _prefs.getBool('isNotificationEnabled') ?? true;
    });
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
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('테마 선택', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('라이트 모드'),
              onTap: () {
                widget.toggleTheme(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('다크 모드'),
              onTap: () {
                widget.toggleTheme(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleNotification(bool value) async {
    setState(() {
      _isNotificationEnabled = value;
    });
    await _prefs.setBool('isNotificationEnabled', value);

    if (value) {
      await _prefs.setBool('notificationShown', false); // ✅ 초기화
      await NotificationService.triggerExpirationCheck(); // ✅ 즉시 알림
      print("🔔 알림 허용됨");
    } else {
      await _prefs.setBool('notificationShown', false);
      await flutterLocalNotificationsPlugin.cancelAll();
      print("🔕 알림 모두 취소됨");
    }
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
          ListTile(
            leading: Icon(Icons.color_lens, color: Colors.grey),
            title: Text('테마 설정', style: TextStyle(fontSize: 18)),
            onTap: () => _showThemeDialog(context),
          ),
          Divider(),
          SwitchListTile(
            secondary: Icon(Icons.notifications_active, color: Colors.grey),
            title: Text('알림 설정', style: TextStyle(fontSize: 18)),
            value: _isNotificationEnabled,
            onChanged: (bool value) {
              _toggleNotification(value); // ✅ 여기 연결!
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.info_outline, color: Colors.grey),
            title: Text('앱 정보', style: TextStyle(fontSize: 18)),
            onTap: () => _showAppInfoDialog(context),
          ),
        ],
      ),
    );
  }}