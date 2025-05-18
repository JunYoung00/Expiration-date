import 'dart:convert';
import 'dart:io';
import 'package:capstone/pages/search_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../notifications/notification_service.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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

  int calculateDday(String expirationDateStr) {
    final today = DateTime.now();
    final expirationDate = DateTime.parse(expirationDateStr);
    return expirationDate.difference(DateTime(today.year, today.month, today.day)).inDays;
  }

  Future<void> pickImageAndRecognize() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _pickedImage = File(pickedFile.path);
      final inputImage = InputImage.fromFile(_pickedImage!);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
      final result = await textRecognizer.processImage(inputImage);
      for (var block in result.blocks) {
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
          await _addItemFromData(data[0], ocrText);
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
    setState(() => expirationList.add(newItem));
    await saveData();
  }

  void _toggleExpand() => setState(() => _isExpanded = !_isExpanded);
  void _collapseIfExpanded() => setState(() => _isExpanded = false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Container(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).drawerTheme.backgroundColor ?? Colors.grey[900]
              : Colors.white, // ✅ 밝은 모드일 땐 흰색 배경 통일
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).primaryColor
                    : Colors.white, // ✅ 헤더도 흰색으로
                padding: EdgeInsets.fromLTRB(16, 100, 16, 8), // ✅ 아래 패딩 줄임
                child: Text(
                  '기능 메뉴',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
              Divider(height: 1), // ✅ 헤더와 리스트 사이 구분선
              ListTile(
                dense: true, // ✅ 리스트 간 간격 축소
                leading: Icon(Icons.camera_alt),
                title: Text('카메라 인식'),
                onTap: () {
                  Navigator.pop(context);
                  pickImageAndRecognize();
                },
              ),
              ListTile(
                dense: true,
                leading: Icon(Icons.search),
                title: Text('음식 검색'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchPage(onItemSelected: (newItem) {
                        setState(() => expirationList.add(newItem));
                        saveData();
                      }),
                    ),
                  );
                },
              ),
              ListTile(
                dense: true,
                leading: Icon(Icons.add),
                title: Text('직접 추가'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddDialog();
                },
              ),
            ],
          ),
        ),
      ),

      appBar: AppBar(
        title: Text('유통기한 확인', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _collapseIfExpanded();
          FocusScope.of(context).unfocus();
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SlidableAutoCloseBehavior(
            child: ListView(
              children: [
                _buildSection("📌 D-DAY", (item) => calculateDday(item['expirationDate']) == 0),
                _buildSection("⏳ 근접", (item) {
                  final d = calculateDday(item['expirationDate']);
                  return d >= 1 && d <= 7;
                }),
                _buildSection("🍀 여유 있음", (item) => calculateDday(item['expirationDate']) > 7),
                _buildSection("⚠️ 지난 항목", (item) => calculateDday(item['expirationDate']) < 0),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildSection(String title, bool Function(Map<String, dynamic>) condition) {
    final filtered = expirationList.where((item) {
      final date = item['expirationDate'];
      if (date == null) return false;
      return condition(item);
    }).toList();

    filtered.sort((a, b) {
      final dateA = DateTime.parse(a['expirationDate']);
      final dateB = DateTime.parse(b['expirationDate']);
      return dateA.compareTo(dateB);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            final offsetAnimation = Tween<Offset>(
              begin: Offset(0.0, 0.05),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offsetAnimation, child: child),
            );
          },
          child: Column(
            key: ValueKey(json.encode(filtered)),
            children: filtered.map((item) => _buildCardItem(context, item)).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
  Widget _animatedFabButton(IconData icon, VoidCallback onPressed) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(32),
        child: Ink(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.indigo, Colors.deepPurple]),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 4))],
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _buildCardItem(BuildContext context, Map<String, dynamic> item) {
    final name = item['name'];
    final expirationDateStr = item['expirationDate'];
    final dday = calculateDday(expirationDateStr);
    final ddayLabel = dday == 0 ? 'D-DAY' : (dday > 0 ? 'D-$dday' : 'D+${-dday}');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;

    return Slidable(
      key: ValueKey(name + expirationDateStr),
      endActionPane: ActionPane(
        motion: DrawerMotion(),
        extentRatio: 0.4,
        children: [
          SlidableAction(
            onPressed: (_) => _showEditDialog(expirationList.indexOf(item)),
            backgroundColor: Color(0xFFC1BFBF),
            foregroundColor: Colors.black87,
            icon: Icons.edit,
            label: '수정',
            borderRadius: BorderRadius.circular(12),
          ),
          SlidableAction(
            onPressed: (_) async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('삭제 확인'),
                  content: Text('정말로 "${item['name']}" 항목을 삭제하시겠습니까?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text('취소')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: Text('삭제')),
                  ],
                ),
              );
              if (confirm == true) {
                setState(() => expirationList.remove(item));
                saveData();
              }
            },
            backgroundColor: Color(0xFFFF5C5C),
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '삭제',
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dday <= 3 && dday >= 0 ? Colors.redAccent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  ddayLabel,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
              TextField(controller: nameController, decoration: InputDecoration(labelText: '음식 이름')),
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
                    setState(() => expirationDate = pickedDate);
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
            TextButton(onPressed: () => Navigator.pop(context), child: Text('취소')),
            TextButton(
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
                setState(() => expirationList.add(newItem));
                saveData();
                Navigator.pop(context);
              },
              child: Text('추가'),
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
              TextField(controller: nameController, decoration: InputDecoration(labelText: '음식 이름')),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() => expirationDate = pickedDate);
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
              onPressed: () => Navigator.pop(context),
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                if (expirationDate != null) {
                  setState(() {
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
              child: Text('저장'),
            ),
          ],
        );
      },
    );
  }

  Future<void> checkAndNotifyExpirations() async {
    for (var item in expirationList) {
      if (item['expirationDate'] != null) {
        final expirationDate = DateTime.parse(item['expirationDate']);
        final todayOnly = DateTime.now();
        final dday = expirationDate.difference(DateTime(todayOnly.year, todayOnly.month, todayOnly.day)).inDays;
        if (dday <= 7 && dday >= 0) {
          await NotificationService.showNotification(
            '${item['name']} 유통기한 임박!',
            '남은 일수: D-$dday',
          );
        }
      }
    }
  }
}
