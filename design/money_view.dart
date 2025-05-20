import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class FoodItem {
  final String name;
  final int price;
  final DateTime date;

  FoodItem({required this.name, required this.price, required this.date});
}

class MoneyView extends StatelessWidget {
  final DateTime selectedDay;
  final DateTime focusedDay;
  final void Function(DateTime selected, DateTime focused) onDaySelected;
  final List<FoodItem> allExpenses;

  const MoneyView({
    Key? key,
    required this.selectedDay,
    required this.focusedDay,
    required this.onDaySelected,
    required this.allExpenses,
  }) : super(key: key);

  // 하루 지출 총합
  int getTotalForDay(DateTime date) {
    return allExpenses
        .where((e) => isSameDay(e.date, date))
        .fold(0, (sum, item) => sum + item.price);
  }

  // 한 달 전체 지출 총합
  int getTotalForMonth(DateTime month) {
    return allExpenses
        .where((e) => e.date.year == month.year && e.date.month == month.month)
        .fold(0, (sum, item) => sum + item.price);
  }

  // 선택된 날짜의 상세 항목
  List<FoodItem> getExpensesForDay(DateTime date) {
    return allExpenses.where((e) => isSameDay(e.date, date)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedExpenses = getExpensesForDay(selectedDay);
    final monthlyTotal = getTotalForMonth(selectedDay);

    return Column(
      children: [
        // 📅 달력 위젯
        TableCalendar(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2026, 12, 31),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          onDaySelected: onDaySelected,
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {
            CalendarFormat.month: 'Month',
          },
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, _) {
              final total = getTotalForDay(day);
              if (total > 0) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("${day.day}"),
                    Text(
                      "-$total",
                      style: TextStyle(color: Colors.red, fontSize: 10),
                    ),
                  ],
                );
              }
              return null;
            },
            selectedBuilder: (context, day, _) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: EdgeInsets.all(6),
                child: Center(
                  child: Text(
                    "${day.day}",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
        ),

        Divider(height: 20),

        // 📌 날짜별 지출 + 월간 총액
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${selectedDay.month}월 ${selectedDay.day}일 음식 지출",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                "${monthlyTotal}원",
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // 🍜 지출 상세
        Expanded(
          child: ListView.builder(
            itemCount: selectedExpenses.length,
            itemBuilder: (context, index) {
              final item = selectedExpenses[index];
              return ListTile(
                title: Text(item.name),
                trailing: Text(
                  "-${item.price}원",
                  style: TextStyle(color: Colors.blue),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
