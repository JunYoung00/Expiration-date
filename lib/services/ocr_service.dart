// 📁 lib/services/ocr_service.dart
// 이미지 선택, OCR 처리, 품목+가격 추출 담당

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:capstone/services/expiration_processor.dart';
import 'package:capstone/services/storage_service.dart';
import 'package:capstone/services/notification_service.dart';

class OCRService {
  static final ImagePicker _picker = ImagePicker();

  // 📸 카메라 촬영
  static Future<File?> pickImageFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  // 🖼️ 갤러리에서 선택
  static Future<File?> pickImageFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  // 📌 OCR 분석 + DB 요청 + 리스트 아이템 반환
  static Future<List<Map<String, dynamic>>> processImageAndExtractItems(
      BuildContext context,
      File image,
      List<Map<String, dynamic>> existingItems,
      ) async {
    final inputImage = InputImage.fromFile(image);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
    final result = await textRecognizer.processImage(inputImage);

    final now = DateTime.now();
    final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final Set<String> processedNames = {};
    final Set<int> processedPrices = {};
    bool registerFail = false;
    List<Map<String, dynamic>> newItems = [];

    for (final line in result.text.split('\n')) {
      if (_isValidLine(line)) {
        final parsed = _extractProductAndPrice(line);
        if (parsed != null) {
          String name = parsed['name'];
          int price = parsed['price'];

          if (!processedNames.contains(name) && name.isNotEmpty) {
            processedNames.add(name);
            bool found = await ExpirationProcessor.fetchAndAddItem(name, existingItems, newItems);

            if (found && !processedPrices.contains(price)) {
              processedPrices.add(price);
              await StorageService.addExpense(dateStr, name, price);
            } else if (!found) {
              registerFail = true;
            }
          }
        }
      }
    }

    if (registerFail) {
      NotificationService.showFailDialog(context);
    }

    textRecognizer.close();
    return newItems;
  }

  static bool _isValidLine(String line) =>
      RegExp(r'[가-힣]').hasMatch(line) && RegExp(r',').hasMatch(line) && RegExp(r'\d').hasMatch(line);

  static Map<String, dynamic>? _extractProductAndPrice(String line) {
    final priceMatch = RegExp(r'(\d{1,3}(?:,\d{3})+)').firstMatch(line);
    if (priceMatch != null) {
      final priceStr = priceMatch.group(0)!;
      final price = int.parse(priceStr.replaceAll(',', ''));
      final name  = line.split(priceStr)[0].replaceAll(RegExp(r'[^가-힣a-zA-Z\s]'), '').trim();
      if (RegExp(r'[가-힣]').hasMatch(name)) return {'name': name, 'price': price};
    }
    return null;
  }
}