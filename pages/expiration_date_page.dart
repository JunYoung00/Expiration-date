import 'dart:convert';
import 'dart:io';
import 'package:capstone/design/expiration_list_view.dart';
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
  List<Map<String, dynamic>> expirationList = [];
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();
  late SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('expirationList');
    if (saved != null) {
      setState(() {
        expirationList = List<Map<String, dynamic>>.from(json.decode(saved));
      });
    }

    final isEnabled = prefs.getBool('isNotificationEnabled') ?? true;
    final alreadyNotified = prefs.getBool('notificationShown') ?? false;
    if (isEnabled && !alreadyNotified) {
      await prefs.setBool('notificationShown', true);
      _checkAndNotify();
    }
  }

  Future<void> _saveData() async {
    await prefs.setString('expirationList', json.encode(expirationList));
  }

  int _calculateDday(String expirationDateStr) {
    final today = DateTime.now();
    final expiration = DateTime.parse(expirationDateStr);
    return expiration.difference(DateTime(today.year, today.month, today.day)).inDays;
  }

  Future<void> _pickImageAndRecognize() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _pickedImage = File(pickedFile.path);
      final inputImage = InputImage.fromFile(_pickedImage!);
      final recognizer = TextRecognizer(script: TextRecognitionScript.korean);
      final result = await recognizer.processImage(inputImage);
      for (var block in result.blocks) {
        for (var line in block.lines) {
          final name = line.text.trim();
          if (name.isNotEmpty && name.length >= 2 && name.length <= 20) {
            final exists = expirationList.any((e) => e['name'] == name);
            if (!exists) {
              await _fetchAndAdd(name);
              await Future.delayed(Duration(milliseconds: 150));
            }
          }
        }
      }
    }
  }

  Future<void> _fetchAndAdd(String ocrText) async {
    try {
      final url = Uri.parse("https://63e2-39-120-34-174.ngrok-free.app/search?name=${Uri.encodeComponent(ocrText)}");
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data is List && data.isNotEmpty) {
          await _addItem(data[0], ocrText);
        } else if (data is Map<String, dynamic>) {
          await _addItem(data, ocrText);
        }
      }
    } catch (e) {
      print("❗ 오류: $e");
    }
  }

  Future<void> _addItem(Map<String, dynamic> data, String fallbackName) async {
    final now = DateTime.now();
    final match = RegExp(r'(\d+)\s*(일|개월)').firstMatch(data['shelfLife'] ?? '');
    int days = 0;
    if (match != null) {
      final number = int.parse(match.group(1)!);
      final unit = match.group(2);
      days = (unit == '개월') ? number * 30 : number;
    }
    final newItem = {
      'name': data['productName'] ?? fallbackName,
      'expirationDate': now.add(Duration(days: days)).toIso8601String(),
    };
    setState(() => expirationList.add(newItem));
    await _saveData();
  }

  void _editItem(int index, String name, DateTime date) {
    setState(() {
      expirationList[index] = {
        'name': name,
        'expirationDate': date.toIso8601String(),
      };
    });
    _saveData();
  }

  void _deleteItem(int index) {
    setState(() => expirationList.removeAt(index));
    _saveData();
  }

  Future<void> _checkAndNotify() async {
    for (final item in expirationList) {
      final date = item['expirationDate'];
      if (date != null) {
        final dday = _calculateDday(date);
        if (dday <= 7 && dday >= 0) {
          await NotificationService.showNotification(
            '${item['name']} 유통기한 임박!',
            '남은 일수: D-$dday',
          );
        }
      }
    }
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
                _saveData();
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

  @override
  Widget build(BuildContext context) {
    return ExpirationListView(
      expirationList: expirationList,
      calculateDday: _calculateDday,
      onEdit: _editItem,
      onDelete: _deleteItem,
      onPickImage: _pickImageAndRecognize,
      onShowAddDialog: (ctx) => _showAddDialog(ctx),
      onSearchPage: (ctx) {
        Navigator.push(ctx, MaterialPageRoute(
          builder: (_) => SearchPage(
            onItemSelected: (item) {
              setState(() => expirationList.add(item));
              _saveData();
            },
          ),
        ));
      },
    );
  }
}
