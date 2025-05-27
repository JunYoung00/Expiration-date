// 📁 lib/services/storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // 🔹 Keys
  static const _expirationKey = 'expirationList';

  /// 📥 expirationList 읽기
  static Future<List<Map<String, dynamic>>> loadExpirationList() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_expirationKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(raw));
  }

  /// 📤 expirationList 저장
  static Future<void> saveExpirationList(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_expirationKey, json.encode(list));
  }

  /// 💸 가계부 항목 추가 (날짜별 key: expenses_yyyy-MM-dd)
  static Future<void> addExpense(String dateStr, String name, int amount) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'expenses_$dateStr';
    final existing = prefs.getStringList(key) ?? [];
    existing.add(jsonEncode({'name': name, 'amount': amount}));
    await prefs.setStringList(key, existing);
  }

// ────────── Generic helpers (bool / string) ──────────
  static Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }

  static Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}