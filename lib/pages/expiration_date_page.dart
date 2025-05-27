// 📁 lib/pages/expiration_date_page.dart
// ────────────────────────────────────────────────────────────────
// 📌  "냉장코치" 유통기한 리스트 메인 페이지 (상태 관리 전용)
//      · 이미지 선택 / OCR / 서버요청 / 저장 · 알림 → 모두 서비스로 위임
//      · 화면에는 ExpirationListView(공통 위젯)만 렌더링
// ────────────────────────────────────────────────────────────────

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:capstone/services/ocr_service.dart';          // 이미지→OCR→DB 로직
import 'package:capstone/services/expiration_processor.dart'; // D‑Day 계산
import 'package:capstone/services/storage_service.dart';      // SharedPreferences 래퍼
import 'package:capstone/services/notification_service.dart'; // 알림 초기화/발송
import 'package:capstone/pages/search_page.dart';             // 텍스트 검색 페이지
import 'package:capstone/widgets/expiration_list_view.dart';  // 목록 UI 위젯

class ExpirationDatePage extends StatefulWidget {
  @override
  State<ExpirationDatePage> createState() => _ExpirationDatePageState();
}

class _ExpirationDatePageState extends State<ExpirationDatePage> {
  // 🔹 상태: 화면에 표시할 유통기한 리스트
  List<Map<String, dynamic>> expirationList = [];

  // ───────────────────────── init ─────────────────────────
  @override
  void initState() {
    super.initState();
    _initializePage(); // 서비스 초기화 & 데이터 로드
  }

  /// 앱 진입 시 1회 실행: 알림 권한, 알림 초기화, 데이터 로드
  Future<void> _initializePage() async {
    await NotificationService.requestPermission();
    await NotificationService.resetIfNewDay();

    // 1) 로컬에 저장된 리스트 로드
    expirationList = await StorageService.loadExpirationList();

    // 2) 알림 조건 확인 & 트리거
    final enabled = await StorageService.getBool('isNotificationEnabled', defaultValue: true);
    final shown   = await StorageService.getBool('notificationShown',      defaultValue: false);
    if (enabled && !shown) {
      await StorageService.setBool('notificationShown', true);
      await NotificationService.triggerExpirationCheck();
    }
    setState(() {}); // 상태 갱신
  }

  // ───────────────────────── 이미지 OCR 핸들러 ─────────────────────────
  Future<void> _onPickImage() async {
    final File? image = await OCRService.pickImageFromCamera();
    if (image != null) {
      final newItems = await OCRService.processImageAndExtractItems(context, image, expirationList);
      setState(() => expirationList.addAll(newItems));
      await StorageService.saveExpirationList(expirationList);
    }
  }

  Future<void> _onPickFromGallery() async {
    final File? image = await OCRService.pickImageFromGallery();
    if (image != null) {
      final newItems = await OCRService.processImageAndExtractItems(context, image, expirationList);
      setState(() => expirationList.addAll(newItems));
      await StorageService.saveExpirationList(expirationList);
    }
  }

  // ───────────────────────── CRUD 콜백 ─────────────────────────
  void _editItem(int index, String name, DateTime date) {
    setState(() {
      expirationList[index] = {
        'name': name,
        'expirationDate': date.toIso8601String(),
      };
    });
    StorageService.saveExpirationList(expirationList);
  }

  void _deleteItem(int index) {
    setState(() => expirationList.removeAt(index));
    StorageService.saveExpirationList(expirationList);
  }

  /// 수동 추가 다이얼로그 호출
  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => ExpirationListView.buildAddDialog(
        context: ctx,
        onAdd: (item) {
          setState(() => expirationList.add(item));
          StorageService.saveExpirationList(expirationList);
        },
      ),
    );
  }

  // ───────────────────────── build ─────────────────────────
  @override
  Widget build(BuildContext context) {
    return ExpirationListView(
      expirationList   : expirationList,
      calculateDday    : ExpirationProcessor.calculateDday,
      onEdit           : _editItem,
      onDelete         : _deleteItem,
      onPickImage      : _onPickImage,
      onPickFromGallery: _onPickFromGallery,
      onShowAddDialog  : _showAddDialog,
      onSearchPage: (ctx) {
        Navigator.push(ctx, MaterialPageRoute(
          builder: (_) => SearchPage(
            onItemSelected: (item) {
              setState(() => expirationList.add(item));
              StorageService.saveExpirationList(expirationList);
            },
          ),
        ));
      },
    );
  }
}