import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../main.dart';
import 'package:capstone/widgets/custom_notification_toggle.dart';
import 'package:capstone/widgets/custom_theme_toggle.dart';// 커스텀 알림 버튼 import

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

  void _toggleNotification(bool value) async {
    setState(() {
      _isNotificationEnabled = value;
    });
    await _prefs.setBool('isNotificationEnabled', value);

    if (!value) {
      await _prefs.setBool('notificationShown', false);
      await flutterLocalNotificationsPlugin.cancelAll();
      print("알림 모두 취소됨");
    } else {
      print("알림 허용됨");
    }
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('설정', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          // 테마 설정
          Row(
            children: [
              Icon(Icons.color_lens, color: Colors.grey),
              SizedBox(width: 12),
              Text('테마 설정', style: TextStyle(fontSize: 18)),
              Spacer(),
              Switch(
                value: isDarkMode,
                onChanged: (value) {
                  widget.toggleTheme(value ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(),

          // 알림 설정
          Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.grey),
              SizedBox(width: 12),
              Text('알림 설정', style: TextStyle(fontSize: 18)),
              Spacer(),
              NotificationToggle(
                isEnabled: _isNotificationEnabled,
                onToggle: () => _toggleNotification(!_isNotificationEnabled),
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(),

          // 앱 정보
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
