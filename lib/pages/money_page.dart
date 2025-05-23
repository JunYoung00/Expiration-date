// 📁 lib/pages/money_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design/money_view.dart';

class MoneyPage extends StatefulWidget {
  @override
  _MoneyPageState createState() => _MoneyPageState();
}

class _MoneyPageState extends State<MoneyPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<FoodItem> allFoodItems = [];

  @override
  void initState() {
    super.initState();
    loadExpensesFromStorage().then((list) {
      setState(() => allFoodItems = list);
    });
  }

  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
    });
  }

  Future<List<FoodItem>> loadExpensesFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys().where((k) => k.startsWith('expenses_'));
    List<FoodItem> items = [];

    for (var key in allKeys) {
      final dateStr = key.replaceFirst('expenses_', '');
      final date = DateTime.parse(dateStr);
      final list = prefs.getStringList(key) ?? [];

      for (var entry in list) {
        final decoded = jsonDecode(entry);
        items.add(FoodItem(name: decoded['name'], price: decoded['amount'], date: date));
      }
    }
    return items;
  }

  void _editExpense(FoodItem oldItem) async {
    String newName = oldItem.name;
    String newPrice = oldItem.price.toString();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('지출 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: '이름'),
              controller: TextEditingController(text: newName),
              onChanged: (v) => newName = v,
            ),
            TextField(
              decoration: InputDecoration(labelText: '가격'),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: newPrice),
              onChanged: (v) => newPrice = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('취소')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              final key = 'expenses_${oldItem.date.toIso8601String().split("T")[0]}';
              List<String> list = prefs.getStringList(key) ?? [];
              list.removeWhere((e) {
                final decoded = jsonDecode(e);
                return decoded['name'] == oldItem.name && decoded['amount'] == oldItem.price;
              });
              list.add(jsonEncode({'name': newName, 'amount': int.parse(newPrice)}));
              await prefs.setStringList(key, list);
              final updated = await loadExpensesFromStorage();
              setState(() => allFoodItems = updated);
            },
            child: Text('저장'),
          ),
        ],
      ),
    );
  }

  void _deleteExpense(FoodItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'expenses_${item.date.toIso8601String().split("T")[0]}';
    List<String> list = prefs.getStringList(key) ?? [];
    list.removeWhere((e) {
      final decoded = jsonDecode(e);
      return decoded['name'] == item.name && decoded['amount'] == item.price;
    });
    await prefs.setStringList(key, list);
    final updated = await loadExpensesFromStorage();
    setState(() => allFoodItems = updated);
  }

  void _showAddExpenseDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    TextEditingController priceController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('직접 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: '음식 이름'),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: '가격'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  selectedDate = picked;
                }
              },
              child: Text(
                selectedDate == null
                    ? '날짜 선택'
                    : '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('취소')),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final priceText = priceController.text.trim();

              if (name.isEmpty || priceText.isEmpty || selectedDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('모든 항목을 입력하세요')));
                return;
              }

              final prefs = await SharedPreferences.getInstance();
              final key = 'expenses_${selectedDate!.toIso8601String().split("T")[0]}';
              List<String> list = prefs.getStringList(key) ?? [];
              list.add(jsonEncode({'name': name, 'amount': int.parse(priceText)}));
              await prefs.setStringList(key, list);

              final updated = await loadExpensesFromStorage();
              setState(() => allFoodItems = updated);

              Navigator.pop(context);
            },
            child: Text('추가'),
          ),
        ],
      ),
    );
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
        onEdit: _editExpense,
        onDelete: _deleteExpense,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddExpenseDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }
}