// 📁 lib/design/money_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:table_calendar/table_calendar.dart';

class FoodItem {
  final String name;
  final int price;
  final DateTime date;

  FoodItem({required this.name, required this.price, required this.date});

  String get key => '$name|$price|${date.toIso8601String().split("T")[0]}';
}

class MoneyView extends StatelessWidget {
  final DateTime selectedDay;
  final DateTime focusedDay;
  final void Function(DateTime selected, DateTime focused) onDaySelected;
  final List<FoodItem> allExpenses;
  final void Function(FoodItem item)? onDelete;
  final void Function(FoodItem item)? onEdit;

  const MoneyView({
    Key? key,
    required this.selectedDay,
    required this.focusedDay,
    required this.onDaySelected,
    required this.allExpenses,
    this.onDelete,
    this.onEdit,
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
          // ✅ 오늘 날짜 배경 제거
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(), // 🔥 회색 배경 제거
          ),

          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
          calendarBuilders: CalendarBuilders(
            // 오늘 날짜 포함해서 모두 같은 방식으로 처리
            defaultBuilder: (context, day, _) {
              final isDark = Theme.of(context).brightness == Brightness.dark; // ✅ 다크모드 체크

              final total = getTotalForDay(day);
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ✅ 날짜는 항상 표시
                  Text("${day.day}",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black, // ✅ 모드에 따른 색상
                    ),
                  ),
                  if (total > 0)
                    Text(
                      "-$total",
                      style: TextStyle(color: Colors.red, fontSize: 10),
                    ),
                ],
              );
            },

            // ✅ 오늘 날짜도 날짜 + 금액 표시되게 커스텀
            todayBuilder: (context, day, _) {
              final total = getTotalForDay(day);
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${day.day}", style: TextStyle(color: Colors.black)),
                  if (total > 0)
                    Text(
                      "-$total",
                      style: TextStyle(color: Colors.red, fontSize: 10),
                    ),
                ],
              );
            },
            // ✅ 선택된 날짜만 파란색으로 표시
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
                "🍱 ${selectedDay.month}월 ${selectedDay.day}일 음식 지출",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                "이번달 지출:${monthlyTotal}원",
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
              return Slidable(
                key: ValueKey(item.key),
                endActionPane: ActionPane(
                  motion: DrawerMotion(),
                  extentRatio: 0.4,
                  children: [
                    SlidableAction(
                      onPressed: (_) => onEdit?.call(item),
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                      icon: Icons.edit,
                      label: '수정',
                    ),
                    SlidableAction(
                      onPressed: (_) => onDelete?.call(item),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      icon: Icons.delete,
                      label: '삭제',
                    ),
                  ],
                ),
                child: ListTile(
                  title: Text(item.name),
                  trailing: Text(
                    "${item.price}원",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}