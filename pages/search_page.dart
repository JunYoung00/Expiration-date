import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  final Function(Map<String, dynamic>) onItemSelected;

  SearchPage({required this.onItemSelected});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _searchTried = false; // 검색 시도 여부

  Future<void> _searchItem() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults = [];
      _searchTried = false;
    });

    try {
      final encodedName = Uri.encodeComponent(query);
      final url = Uri.parse('https://63e2-39-120-34-174.ngrok-free.app/search?name=$encodedName');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          _searchResults = List<Map<String, dynamic>>.from(data);
        } else if (data is Map<String, dynamic>) {
          _searchResults = [data];
        } else {
          _searchResults = [];
        }
      }
    } catch (e) {
      print('❗ 검색 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
        _searchTried = true;
      });
    }
  }

  Future<void> _addItem(Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getString('expirationList');
    List<Map<String, dynamic>> expirationList = [];

    if (savedList != null) {
      expirationList = List<Map<String, dynamic>>.from(json.decode(savedList));
    }

    final now = DateTime.now();
    int shelfLifeDays = 0;
    final shelfLifeStr = item['shelfLife'];

    final exp = RegExp(r'(\d+)\s*(일|개월)').firstMatch(shelfLifeStr ?? '');
    if (exp != null) {
      int number = int.parse(exp.group(1)!);
      String unit = exp.group(2)!;
      shelfLifeDays = unit == '개월' ? number * 30 : number;
    }

    final expirationDate = now.add(Duration(days: shelfLifeDays));

    final newItem = {
      'name': item['productName'] ?? _controller.text.trim(),
      'expirationDate': expirationDate.toIso8601String(),
    };

    expirationList.add(newItem);
    await prefs.setString('expirationList', json.encode(expirationList));

    widget.onItemSelected(newItem);
    Navigator.pop(context);
  }

  Future<void> _addManualItem() async {
    final prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getString('expirationList');
    List<Map<String, dynamic>> expirationList = [];

    if (savedList != null) {
      expirationList = List<Map<String, dynamic>>.from(json.decode(savedList));
    }

    final now = DateTime.now();
    final expirationDate = now.add(Duration(days: 30)); // 기본 30일짜리

    final newItem = {
      'name': '${_controller.text.trim()} (수정 필요!)', // ✅ 이름에 (수정 필요!) 붙이기
      'expirationDate': expirationDate.toIso8601String(),
    };

    expirationList.add(newItem);
    await prefs.setString('expirationList', json.encode(expirationList));

    widget.onItemSelected(newItem);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('음식 검색', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: '음식 이름 입력',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchItem,
                ),
              ),
              onSubmitted: (_) => _searchItem(),
            ),
            SizedBox(height: 20),
            _isLoading
                ? CircularProgressIndicator()
                : Expanded(
              child: _searchResults.isNotEmpty
                  ? ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final item = _searchResults[index];
                  return Card(
                    child: ListTile(
                      title: Text(item['productName'] ?? _controller.text.trim()),
                      subtitle: Text('예상 유통기한: ${item['shelfLife'] ?? '정보 없음'}'),
                      onTap: () => _addItem(item),
                    ),
                  );
                },
              )
                  : _searchTried
                  ? Column(
                children: [
                  Text('검색 결과가 없습니다.', style: TextStyle(fontSize: 16)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addManualItem,
                    child: Text('직접 등록하기'),
                  )
                ],
              )
                  : Container(),
            ),
          ],
        ),
      ),
    );
  }
}
