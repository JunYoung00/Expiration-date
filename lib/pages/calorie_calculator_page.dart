import 'package:flutter/material.dart';
import 'expiration_date_page.dart';
import 'settings_page.dart';

class CalorieCalculatorPage extends StatefulWidget {
  @override
  _CalorieCalculatorPageState createState() => _CalorieCalculatorPageState();
}

class _CalorieCalculatorPageState extends State<CalorieCalculatorPage> {
  int _selectedIndex = 1;

  // 검색 관련 변수
  TextEditingController _searchController = TextEditingController();
  List<String> filteredFoods = [];

  @override
  void initState() {
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ExpirationDatePage()));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
    }
  }

  void _filterFoods(String query) {
    setState(() {
      // 검색어에 맞는 필터링 로직 추가 (예: 미리 정의된 음식 목록을 기반으로 필터링)
      filteredFoods = []; // 나중에 음식을 추가하면 여기에 필터링 로직 추가
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('칼로리 계산', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '품목 검색',
                prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterFoods, // 검색어가 변경될 때마다 필터링
            ),
          ),
          Expanded(
            child: Center(
              child: Text('검색된 음식 항목이 여기에 표시됩니다.', style: TextStyle(fontSize: 18)),
            ),
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