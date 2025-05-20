import 'package:flutter/material.dart';
import '../design/money_view.dart';

class MoneyPage extends StatefulWidget {
  @override
  _MoneyPageState createState() => _MoneyPageState();
}

class _MoneyPageState extends State<MoneyPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // 📌 샘플 음식 지출 데이터
  final List<FoodItem> allFoodItems = [
    FoodItem(name: '삼각김밥', price: 2200, date: DateTime(2025, 5, 20)),
    FoodItem(name: '햄버거', price: 3000, date: DateTime(2025, 5, 20)),
    FoodItem(name: '샌드위치', price: 5000, date: DateTime(2025, 5, 21)),
    FoodItem(name: '라면', price: 3200, date: DateTime(2025, 5, 19)),
    FoodItem(name: '김밥', price: 2500, date: DateTime(2025, 5, 19)),
  ];

  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("가계부"),
        centerTitle: true,
      ),
      body: MoneyView(
        selectedDay: _selectedDay,
        focusedDay: _focusedDay,
        onDaySelected: _onDaySelected,
        allExpenses: allFoodItems,
      ),
    );
  }
}
