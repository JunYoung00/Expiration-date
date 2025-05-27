// 📁 lib/services/expiration_processor.dart
// 서버 요청, 유통기한 계산 및 리스트 추가

import 'dart:convert';
import 'package:http/http.dart' as http;

class ExpirationProcessor {
  // 🌐 백엔드 서버 엔드포인트 (필요하면 환경변수/Flavor로 대체)
  static const String _baseUrl = 'https://3910-39-120-34-174.ngrok-free.app';

  /// D‑Day 계산: "yyyy-MM-ddTHH:mm:ss" 문자열 → 남은 일수(int)
  static int calculateDday(String expirationDateStr) {
    final today = DateTime.now();
    final expiration = DateTime.parse(expirationDateStr);
    return expiration.difference(DateTime(today.year, today.month, today.day)).inDays;
  }

  /// OCR로 추출된 [ocrText]를 기반으로 서버에서 유통기한 정보를 검색한 뒤,
  ///   * 찾으면 [existingItems] / [newItems] 중복을 체크해 추가
  ///   * 성공 여부(bool) 반환
  ///
  /// [existingItems] : 이미 화면에 표시 중인 리스트 (중복 방지)
  /// [newItems]      : 이번 OCR 처리에서 새로 추가된 항목 누적 리스트
  static Future<bool> fetchAndAddItem(
      String ocrText,
      List<Map<String, dynamic>> existingItems,
      List<Map<String, dynamic>> newItems,
      ) async {
    try {
      final foodName = _extractFoodNameOnly(ocrText);
      if (foodName.isEmpty) return false;

      // 1️⃣ 풀네임 먼저 검색
      if (await _searchAndAppend(foodName, foodName, existingItems, newItems)) {
        return true;
      }

      // 2️⃣ 부분 매칭 (앞 글자씩 제거, 최소 2글자)
      final koreanOnly = RegExp(r'[가-힣]+').allMatches(foodName).map((m) => m.group(0)!).join('');
      for (int i = 1; i < koreanOnly.length - 1; i++) {
        final keyword = koreanOnly.substring(i);
        if (keyword.length < 2) break;
        if (await _searchAndAppend(keyword, foodName, existingItems, newItems)) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// ----------------------- helpers ----------------------- ///

  static Future<bool> _searchAndAppend(
      String query,
      String fallbackName,
      List<Map<String, dynamic>> existingItems,
      List<Map<String, dynamic>> newItems,
      ) async {
    final encoded = Uri.encodeComponent(query);
    final url = Uri.parse('$_baseUrl/search?name=$encoded');
    final response = await http.get(url);
    if (response.statusCode != 200) return false;

    final body = json.decode(response.body);
    if (body is List && body.isEmpty) return false;
    final data = body is List ? body.first : body;

    return _appendIfNotDuplicate(data, fallbackName, existingItems, newItems);
  }

  static bool _appendIfNotDuplicate(
      Map<String, dynamic> data,
      String fallbackName,
      List<Map<String, dynamic>> existingItems,
      List<Map<String, dynamic>> newItems,
      ) {
    final now = DateTime.now();
    final shelfLifeDays = _extractShelfLifeDays(data['shelfLife']);
    final expirationDate = now.add(Duration(days: shelfLifeDays));

    final itemName = fallbackName; // OCR 인식 단어를 우선 사용
    // 이미 존재하는지 중복 체크
    final duplicate = existingItems.any((e) => e['name'] == itemName) ||
        newItems.any((e) => e['name'] == itemName);
    if (duplicate) return false;

    newItems.add({
      'name': itemName,
      'expirationDate': expirationDate.toIso8601String(),
    });
    return true;
  }

  /// "12개월" → 360  |  "90일" → 90 | 파싱 실패 시 0
  static int _extractShelfLifeDays(String? raw) {
    if (raw == null) return 0;
    final dayMatch = RegExp(r'(\d+)\s*일').firstMatch(raw);
    final monthMatch = RegExp(r'(\d+)\s*개월').firstMatch(raw);
    if (dayMatch != null) return int.parse(dayMatch.group(1)!);
    if (monthMatch != null) return int.parse(monthMatch.group(1)!) * 30;
    return 0;
  }

  /// 가격 숫자 제거 → 음식명만 남김
  static String _extractFoodNameOnly(String text) {
    final pricePattern = RegExp(r'\s*\d{1,3}(?:,\d{3})+|\d{4,}\s*');
    return text.replaceAll(pricePattern, '').trim();
  }
}
