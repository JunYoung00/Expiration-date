import 'package:flutter/material.dart';
import 'expiration_date_page.dart';
import 'calorie_calculator_page.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedIndex = 2;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ExpirationDatePage()));
    } else if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => CalorieCalculatorPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('설정', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text('알림 설정'),
            leading: Icon(Icons.notifications),
            onTap: () {},
          ),
          ListTile(
            title: Text('테마 설정'),
            leading: Icon(Icons.color_lens),
            onTap: () {},
          ),
          ListTile(
            title: Text('기타 설정'),
            leading: Icon(Icons.settings),
            onTap: () {},
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate), label: '칼로리 계산'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}
