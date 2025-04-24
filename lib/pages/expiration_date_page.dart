import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'camera_page.dart';
import 'calorie_calculator_page.dart';
import 'settings_page.dart';
import '../notifications/notification_service.dart';

class ExpirationDatePage extends StatefulWidget {
  @override
  _ExpirationDatePageState createState() => _ExpirationDatePageState();
}

class _ExpirationDatePageState extends State<ExpirationDatePage> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String resultText = "";

  // ✅ shelfLife 텍스트에서 숫자만 파싱하는 함수
  int parseShelfLife(String shelfLife) {
    final dayMatch = RegExp(r'(\d+)\s*일').firstMatch(shelfLife);
    final monthMatch = RegExp(r'(\d+)\s*개월').firstMatch(shelfLife);
    final onlyNumber = RegExp(r'^\d+$').firstMatch(shelfLife.trim()); // 🔥 숫자만 있는 경우

    if (dayMatch != null) {
      return int.parse(dayMatch.group(1)!);
    } else if (monthMatch != null) {
      return int.parse(monthMatch.group(1)!) * 30;
    } else if (onlyNumber != null) {
      return int.parse(onlyNumber.group(0)!); // ✅ 그냥 숫자만 있을 경우 그대로 사용
    }
    return 0;
  }

  // ✅ 서버에서 DB 검색 후 D-Day 계산(새로 추가)
  Future<void> fetchAndShowDday(String name) async {
    final encodedName = Uri.encodeComponent(name); // 한글 안전하게 인코딩
    final url = "http://10.0.2.2:8080/search?name=$encodedName";

    print("🛰️ 서버로 검색 요청 보냄: $encodedName");

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final rawShelfLife = data['shelfLife'] ?? '';
        final shelfLife = parseShelfLife(rawShelfLife); // "12개월", "7일" → 숫자로 변환

        // ✅ 날짜만 사용해서 D-Day 정확하게 계산
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final expirationDate = today.add(Duration(days: shelfLife));
        final dday = expirationDate.difference(today).inDays;
        print("🧪 서버 응답 shelfLife: ${data['shelfLife']}");
        print("🔎 파싱된 shelfLife 일수: $shelfLife");
        print("📅 expirationDate: $expirationDate");
        print("📆 today: $today");
        print("📉 D-Day: $dday");
        setState(() {
          resultText = "[$name] D-$dday";
        });

        if (dday <= 7) {
          NotificationService.showExpirationNotification(name, dday);
        }
      } else {
        setState(() {
          resultText = "DB에 등록된 품목이 없습니다.";
        });
      }
    } catch (e) {
      setState(() {
        resultText = "오류 발생: $e";
      });
    }
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => CalorieCalculatorPage()));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('유통기한 확인', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Column(
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
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final input = _searchController.text.trim();
                  if (input.isNotEmpty) {
                    fetchAndShowDday(input);
                  }
                },
                child: Text('D-Day 확인'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  NotificationService.testDummyExpirationAlert(); // 테스트용 알림
                },
                child: Text('유통기한 테스트 알림 보내기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                resultText,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Expanded(child: Container()),
            ],
          ),
          Positioned(
            bottom: 40,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CameraPage()));
              },
              child: Icon(Icons.camera_alt),
              backgroundColor: Colors.blueAccent,
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
