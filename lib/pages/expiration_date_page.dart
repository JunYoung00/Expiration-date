import 'dart:convert';
import 'dart:io';
import 'package:capstone/pages/search_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../notifications/notification_service.dart';

class ExpirationDatePage extends StatefulWidget {
  @override
  _ExpirationDatePageState createState() => _ExpirationDatePageState();
}

class _ExpirationDatePageState extends State<ExpirationDatePage> {
  bool _isExpanded = false;
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> expirationList = [];
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    loadSavedData().then((_) async {
      prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('isNotificationEnabled') ?? true;
      final alreadyNotified = prefs.getBool('notificationShown') ?? false;

      if (isEnabled && !alreadyNotified) {
        await prefs.setBool('notificationShown', true);
        checkAndNotifyExpirations();
      }
    });
  }

  Future<void> loadSavedData() async {
    prefs = await SharedPreferences.getInstance();
    final savedList = prefs.getString('expirationList');
    if (savedList != null) {
      setState(() {
        expirationList = List<Map<String, dynamic>>.from(json.decode(savedList));
      });
    }
  }

  Future<void> saveData() async {
    await prefs.setString('expirationList', json.encode(expirationList));
  }

  Future<void> pickImageAndRecognize() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 100, maxWidth: 3000, maxHeight: 3000);

    if (pickedFile != null) {
      _pickedImage = File(pickedFile.path);
      final inputImage = InputImage.fromFile(_pickedImage!);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
      final RecognizedText result = await textRecognizer.processImage(inputImage);

      final blocks = result.blocks;
      for (var block in blocks) {
        for (var line in block.lines) {
          final name = line.text.trim();
          if (name.isNotEmpty && name.length >= 2 && name.length <= 20) {
            bool isDuplicate = expirationList.any((item) => item['name'] == name);
            if (!isDuplicate) {
              await fetchExpirationInfo(name);
              await Future.delayed(Duration(milliseconds: 150));
            }
          }
        }
      }
    }
  }

  Future<void> fetchExpirationInfo(String ocrText) async {
    try {
      final encodedName = Uri.encodeComponent(ocrText);
      final url = Uri.parse("http://192.168.35.33:8080/search?name=$encodedName");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List && data.isNotEmpty) {
          final firstItem = data[0];
          await _addItemFromData(firstItem, ocrText);
        } else if (data is Map<String, dynamic>) {
          await _addItemFromData(data, ocrText);
        }
      }
    } catch (e) {
      print('❗ 오류 발생: $e');
    }
  }

  Future<void> _addItemFromData(Map<String, dynamic> data, String fallbackName) async {
    final now = DateTime.now();
    int shelfLifeDays = 0;
    final shelfLifeStr = data['shelfLife'];

    final exp = RegExp(r'(\d+)\s*(일|개월)').firstMatch(shelfLifeStr ?? '');
    if (exp != null) {
      int number = int.parse(exp.group(1)!);
      String unit = exp.group(2)!;
      shelfLifeDays = unit == '개월' ? number * 30 : number;
    }

    final expirationDate = now.add(Duration(days: shelfLifeDays));

    final newItem = {
      'name': data['productName'] ?? fallbackName,
      'expirationDate': expirationDate.toIso8601String(),
    };

    setState(() {
      expirationList.add(newItem);
    });

    await saveData();
  }

  Future<void> checkAndNotifyExpirations() async {
    for (var item in expirationList) {
      if (item['expirationDate'] != null) {
        final expirationDate = DateTime.parse(item['expirationDate']);
        final todayOnly = DateTime.now();
        final dday = expirationDate.difference(todayOnly).inDays;

        if (dday <= 7) {
          await NotificationService.showNotification(
            '${item['name']} 유통기한 임박!',
            '남은 일수: D-$dday',
          );
        }
      }
    }
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _collapseIfExpanded() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
      });
    }
  }

  void _showOptionsDialog(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('수정'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(index);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('삭제'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  expirationList.removeAt(index);
                });
                saveData();
              },
            ),
          ],
        );
      },
    );
  }
  void _showAddDialog() {
    TextEditingController nameController = TextEditingController();
    DateTime? expirationDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('직접 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: '음식 이름'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      expirationDate = pickedDate;
                    });
                  }
                },
                child: Text(
                  expirationDate == null
                      ? '유통기한일자 선택'
                      : '${expirationDate!.toLocal()}'.split(' ')[0],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('취소'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('추가'),
              onPressed: () {
                if (nameController.text.trim().isEmpty || expirationDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('이름과 유통기한을 모두 입력하세요.')),
                  );
                  return;
                }

                final newItem = {
                  'name': nameController.text.trim(),
                  'expirationDate': expirationDate!.toIso8601String(),
                };

                setState(() {
                  expirationList.add(newItem);
                });

                saveData();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
  void _showEditDialog(int index) {
    TextEditingController nameController = TextEditingController(text: expirationList[index]['name']);
    DateTime? expirationDate;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: '음식 이름'),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      expirationDate = pickedDate;
                    });
                  }
                },
                child: Text(
                  expirationDate == null ? '유통기한일자 선택' : '${expirationDate!.toLocal()}'.split(' ')[0],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('저장'),
              onPressed: () {
                if (expirationDate != null) {
                  setState(() {
                    // 🔥 "수정 필요!" 라는 문구가 이름에 남아있으면 자동 제거
                    String newName = nameController.text.replaceAll('(수정 필요!)', '').trim();

                    expirationList[index]['name'] = newName;
                    expirationList[index]['expirationDate'] = expirationDate!.toIso8601String();
                  });
                  saveData();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('유통기한일자를 선택하세요.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayOnly = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    final validItems = expirationList.where((item) {
      final name = item['name'];
      final expirationDateStr = item['expirationDate'];
      if (name.contains('수정 필요!')) return true;
      if (expirationDateStr == null) return false;
      final expirationDate = DateTime.parse(expirationDateStr);
      return expirationDate.difference(todayOnly).inDays >= 0;
    }).toList();

    final expiredItems = expirationList.where((item) {
      final name = item['name'];
      final expirationDateStr = item['expirationDate'];
      if (name.contains('수정 필요!')) return false;
      if (expirationDateStr == null) return false;
      final expirationDate = DateTime.parse(expirationDateStr);
      return expirationDate.difference(todayOnly).inDays < 0;
    }).toList();
// 🔥 여기에 추가 (D-Day 오름차순 정렬)
    validItems.sort((a, b) {
      final aDateStr = a['expirationDate'];
      final bDateStr = b['expirationDate'];

      if (aDateStr == null) return -1; // 수정 필요! (유통기한 없는 것) 가장 위에 올려
      if (bDateStr == null) return 1;

      final aDate = DateTime.parse(aDateStr);
      final bDate = DateTime.parse(bDateStr);

      return aDate.difference(todayOnly).inDays.compareTo(bDate.difference(todayOnly).inDays);
    });

    return GestureDetector(
      onTap: _collapseIfExpanded,
      child: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(16),
          child: ListView(
            children: [
              Text('✅ 지나지 않은 항목', style: TextStyle(fontWeight: FontWeight.bold)),
              ...validItems.map((item) => _buildListTile(item, todayOnly)),
              SizedBox(height: 16),
              Text('⚠️ 지난 항목', style: TextStyle(fontWeight: FontWeight.bold)),
              ...expiredItems.map((item) => _buildListTile(item, todayOnly)),
            ],
          ),
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_isExpanded) ...[
              FloatingActionButton(
                heroTag: "searchButton",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SearchPage(
                        onItemSelected: (newItem) {
                          setState(() {
                            expirationList.add(newItem);
                          });
                          saveData();
                        },
                      ),
                    ),
                  );
                },
                backgroundColor: Colors.grey[700],
                child: Icon(Icons.search),
              ),
              SizedBox(height: 20),
              FloatingActionButton(
                heroTag: "cameraButton",
                onPressed: pickImageAndRecognize,
                backgroundColor: Colors.grey[700],
                child: Icon(Icons.camera_alt),
              ),
              SizedBox(height: 20),
              FloatingActionButton(
                heroTag: "manualAddButton",
                onPressed: _showAddDialog, // ✅ 직접 추가 다이얼로그 호출
                backgroundColor: Colors.grey[700],
                child: Icon(Icons.add),
              ),
              SizedBox(height: 20),
            ],
            FloatingActionButton(
              heroTag: "mainButton",
              onPressed: _toggleExpand,
              backgroundColor: Colors.grey[800],
              child: Icon(_isExpanded ? Icons.close : Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(Map<String, dynamic> item, DateTime todayOnly) {
    final name = item['name'];
    final expirationDateStr = item['expirationDate'];

    String subtitleText;
    TextStyle subtitleStyle = TextStyle(); // 기본 스타일
    if (name.contains('수정 필요!')) {
      subtitleText = '수정 필요!';
    } else if (expirationDateStr != null) {
      final expirationDate = DateTime.parse(expirationDateStr);
      final dday = expirationDate.difference(todayOnly).inDays;

      if (dday > 0) {
        subtitleText = 'D-$dday';
      } else if (dday == 0) {
        subtitleText = 'D-DAY';
      } else {
        subtitleText = 'D+${-dday} (지남)';
      }
      if (dday <= 3) {
        subtitleStyle = TextStyle(color: Colors.red, fontWeight: FontWeight.bold); // 🔥 빨간색 강조
      }
    } else {
      subtitleText = '유통기한 미지정';
    }

    return Card(
      child: Row(
        children: [
          Expanded(
            child: ListTile(
              title: Text(name),
              subtitle: Text(subtitleText, style: subtitleStyle), // 🔥 여기 적용
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showEditDialog(expirationList.indexOf(item));
              } else if (value == 'delete') {
                setState(() {
                  expirationList.remove(item);
                });
                saveData();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text('수정')),
              PopupMenuItem(value: 'delete', child: Text('삭제')),
            ],
          ),
        ],
      ),
    );
  }
}