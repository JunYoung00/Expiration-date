import 'dart:convert';
import 'dart:io';
import 'package:capstone/pages/search_page.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../notifications/notification_service.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:capstone/design/expiration_list_view.dart';


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

  // 음식명과 가격 추출 도우미
  String extractFoodNameOnly(String line) {
    final pricePattern = RegExp(r'\s*\d{1,3}(?:,\d{3})+|\d{4,}\s*');
    return line.replaceAll(pricePattern, '').trim();
  }

  int? extractPrice(String line) {
    final pricePattern = RegExp(r'(\d{1,3}(,\d{3})+|\d{4,})');
    final match = pricePattern.firstMatch(line);
    if (match != null) {
      return int.parse(match.group(0)!.replaceAll(',', ''));
    }
    return null;
  }

  Future<void> addExpenseDetail(String date, String name, int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'expenses_$date';
    List<String> existing = prefs.getStringList(key) ?? [];
    existing.add(jsonEncode({'name': name, 'amount': amount}));
    await prefs.setStringList(key, existing);
  }

  Future<void> requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }
  @override
  void initState() {
    super.initState();
    requestNotificationPermission();
    _initNotificationLogic();
  }

  Future<void> _initNotificationLogic() async {
    await resetNotificationIfNewDay();
    await loadSavedData(); // 먼저 데이터 로드

    final isEnabled = prefs.getBool('isNotificationEnabled') ?? true;
    final alreadyNotified = prefs.getBool('notificationShown') ?? false;

    if (isEnabled && !alreadyNotified) {
      await prefs.setBool('notificationShown', false);
      await NotificationService.triggerExpirationCheck(); // 그 다음 호출

    }
  }

  Future<void> resetNotificationIfNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final last = prefs.getString('lastNotificationDate');

    if (last != today) {
      await prefs.setBool('notificationShown', false);
      await prefs.setString('lastNotificationDate', today);
    }
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

      print("🧾 전체 인식 텍스트: ${result.text}");

      final lines = result.text.split('\n');
      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final Set<String> processedItems = {};  // 🔒 중복 방지 세트

      for (final line in lines) {
        final name = extractFoodNameOnly(line);
        final price = extractPrice(line);
        final key = "$name|${price ?? 'null'}";

        if (name.isEmpty || processedItems.contains(key)) continue;
        processedItems.add(key);

        print('🔎 OCR 분석: $line → 이름: $name, 가격: ${price ?? '없음'}');

        // ✅ 유통기한 리스트 등록 (가격이 없어도)
        bool isDuplicate = expirationList.any((item) => item['name'] == name);
        if (!isDuplicate) {
          print('📡 유통기한 요청 시작: $name');
          await fetchExpirationInfo(name);
          await Future.delayed(Duration(milliseconds: 150));
        }

        // ✅ 가계부는 가격 있을 때만
        if (price != null) {
          print('💰 가계부 저장: $name $price');
          await addExpenseDetail(dateStr, name, price);
        }
      }

      textRecognizer.close();
    }
  }
//앨범인식
  Future<void> pickImageFromGalleryAndRecognize() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _pickedImage = File(pickedFile.path);
      await recognizeImage(_pickedImage!);
    }
  }
  //앨범인식
  Future<void> recognizeImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
    final result = await textRecognizer.processImage(inputImage);

    print("🧾 전체 인식 텍스트: ${result.text}");

    final lines = result.text.split('\n');
    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final Set<String> processedItems = {};

    for (final line in lines) {
      final name = extractFoodNameOnly(line);
      final price = extractPrice(line);
      final key = "$name|${price ?? 'null'}";

      if (name.isEmpty || processedItems.contains(key)) continue;
      processedItems.add(key);

      print('🔎 OCR 분석: $line → 이름: $name, 가격: ${price ?? '없음'}');

      // 유통기한 리스트 추가
      bool isDuplicate = expirationList.any((item) => item['name'] == name);
      if (!isDuplicate) {
        print('📡 유통기한 요청 시작: $name');
        await fetchExpirationInfo(name);
        await Future.delayed(Duration(milliseconds: 150));
      }

      // 가계부에 추가 (가격 있을 때만)
      if (price != null) {
        await addExpenseDetail(dateStr, name, price);
      }
    }

    textRecognizer.close();
  }

  Future<void> fetchExpirationInfo(String ocrText) async {
    try {
      final foodName = extractFoodNameOnly(ocrText); // ✅ 가격 제거
      final encodedName = Uri.encodeComponent(foodName);
      final url = Uri.parse("https://c036-39-120-34-174.ngrok-free.app/search?name=$encodedName");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          await _addItemFromData(data[0], foodName);
        } else if (data is Map<String, dynamic>) {
          await _addItemFromData(data, foodName);
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
      'name': fallbackName, // ← 무조건 OCR로 인식된 단어만 사용
      'expirationDate': expirationDate.toIso8601String(),
    };
    // ✅ 추가: 위젯이 아직 살아있을 때만 setState
    if (!mounted) return;

    // ✅ 최종 이름 기준으로 중복 필터
    bool isDuplicate = expirationList.any((item) => item['name'] == (data['productName'] ?? fallbackName));
    if (isDuplicate) return;

    setState(() => expirationList.add(newItem));
    await saveData();
  }




  void _toggleExpand() => setState(() => _isExpanded = !_isExpanded);
  void _collapseIfExpanded() => setState(() => _isExpanded = false);


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
    final ddayLabel = dday < 0 ? '' : (dday == 0 ? 'D-DAY' : 'D-$dday');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
          ),
        ],
      ),
      child: Material(
        color: isDarkMode ? Colors.black : Colors.white,
        child: InkWell(
          onTap: () { Slidable.of(context)?.close();
          },
          splashColor: Colors.grey.withOpacity(0.2),
          highlightColor: Colors.grey.withOpacity(0.1),
          child: Container(
            margin: EdgeInsets.symmetric(vertical: 6),
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
                if (ddayLabel.isNotEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(32), // 네모 모양
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
      ),
    );
  }



  void _showAddDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    DateTime? expirationDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) expirationDate = pickedDate;
              },
              child: Text('유통기한 선택'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('취소')),
          TextButton(
            onPressed: () {
              if (expirationDate != null && nameController.text.trim().isNotEmpty) {
                setState(() {
                  expirationList.add({
                    'name': nameController.text.trim(),
                    'expirationDate': expirationDate!.toIso8601String(),
                  });
                });
                saveData();
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('입력 값을 확인하세요.')));
              }
            },
            child: Text('추가'),
          ),
        ],
      ),
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
    int id = 0; // 고유 ID 카운터
    for (var item in expirationList) {
      if (item['expirationDate'] != null) {
        final expirationDate = DateTime.parse(item['expirationDate']);
        final todayOnly = DateTime.now();
        final dday = expirationDate.difference(DateTime(todayOnly.year, todayOnly.month, todayOnly.day)).inDays;
        if (dday <= 7 && dday >= 0) {
          await NotificationService.showNotification(
            '${item['name']} 유통기한 임박!',
            '남은 일수: D-$dday',
            id: id++, // 🔥 고유 알림 ID 부여
          );
        }
      }
    }
  }

  void _editItem(int index, String name, DateTime date) {
    setState(() {
      expirationList[index] = {
        'name': name,
        'expirationDate': date.toIso8601String(),
      };
    });
    saveData();
  }

  void _deleteItem(int index) {
    setState(() => expirationList.removeAt(index));
    saveData();
  }

  @override
  Widget build(BuildContext context) {
    return ExpirationListView(
      expirationList: expirationList,
      calculateDday: calculateDday,
      onEdit: _editItem,
      onDelete: _deleteItem,
      onPickImage: pickImageAndRecognize,
      onPickFromGallery: pickImageFromGalleryAndRecognize,
      onShowAddDialog: (ctx) => _showAddDialog(ctx),
      onSearchPage: (ctx) {
        Navigator.push(ctx, MaterialPageRoute(
          builder: (_) => SearchPage(
            onItemSelected: (item) {
              setState(() => expirationList.add(item));
              saveData();
            },
          ),
        ));
      },
    );
  }
}