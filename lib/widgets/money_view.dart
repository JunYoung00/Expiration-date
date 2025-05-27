import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:capstone/widgets/custom_checkbox.dart';

class FoodItem {
  final String name;
  final int price;
  final DateTime date;

  FoodItem({required this.name, required this.price, required this.date});

  String get key => '$name|$price|${date.toIso8601String().split("T")[0]}';
}

class MoneyView extends StatefulWidget {
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

  @override
  State<MoneyView> createState() => _MoneyViewState();
}

class _MoneyViewState extends State<MoneyView> {
  bool isEditing = false;
  Set<int> selectedIndexes = {};

  int getTotalForDay(DateTime date) {
    return widget.allExpenses
        .where((e) => isSameDay(e.date, date))
        .fold(0, (sum, item) => sum + item.price);
  }

  int getTotalForMonth(DateTime month) {
    return widget.allExpenses
        .where((e) => e.date.year == month.year && e.date.month == month.month)
        .fold(0, (sum, item) => sum + item.price);
  }

  List<FoodItem> getExpensesForDay(DateTime date) {
    return widget.allExpenses
        .where((e) => isSameDay(e.date, date))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedExpenses = getExpensesForDay(widget.selectedDay);
    final monthlyTotal = getTotalForMonth(widget.selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: Text('가계부', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                isEditing = !isEditing;
                selectedIndexes.clear();
              });
            },
            child: Text(
              isEditing ? '취소' : '편집',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2026, 12, 31),
            focusedDay: widget.focusedDay,
            selectedDayPredicate: (day) => isSameDay(widget.selectedDay, day),
            onDaySelected: widget.onDaySelected,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, _) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final total = getTotalForDay(day);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${day.day}",
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    if (total > 0)
                      Text(
                        "-$total",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                );
              },
              todayBuilder: (context, day, _) {
                final total = getTotalForDay(day);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${day.day}",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.grey.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                    if (total > 0)
                      Text(
                        "-$total",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                );
              },
              selectedBuilder: (context, day, _) {
                final total = getTotalForDay(day);
                final isToday = isSameDay(day, DateTime.now());

                return FittedBox(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blueAccent.withOpacity(0.5),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.all(4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "${day.day}",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: isToday ? 20 : 14,
                            fontWeight: isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                            shadows: isToday
                                ? [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                            ]
                                : [],
                          ),
                        ),
                        if (total > 0)
                          Text(
                            "-$total",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          Divider(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "🍱 ${widget.selectedDay.month}월 ${widget.selectedDay.day}일 음식 지출",
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

          Expanded(
            child: SlidableAutoCloseBehavior(
              child: ListView.builder(
                itemCount: selectedExpenses.length,
                itemBuilder: (context, index) {
                  final item = selectedExpenses[index];
                  final globalIndex = widget.allExpenses.indexOf(item);
                  final isSelected = selectedIndexes.contains(globalIndex);

                  return InkWell(
                    onTap: isEditing
                        ? () {
                      setState(() {
                        if (isSelected) {
                          selectedIndexes.remove(globalIndex);
                        } else {
                          selectedIndexes.add(globalIndex);
                        }
                      });
                    }
                        : null,
                    child: Opacity(
                      opacity: isEditing && !isSelected ? 0.6 : 1.0,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Slidable(
                          enabled: !isEditing,
                          key: ValueKey(item.key),
                          endActionPane: ActionPane(
                            motion: DrawerMotion(),
                            extentRatio: 0.4,
                            children: [
                              SlidableAction(
                                onPressed: (_) => widget.onEdit?.call(item),
                                backgroundColor: Colors.grey,
                                foregroundColor: Colors.white,
                                icon: Icons.edit,
                                label: '수정',
                              ),
                              SlidableAction(
                                onPressed: (_) => widget.onDelete?.call(item),
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: '삭제',
                              ),
                            ],
                          ),
                          child: Container(
                            margin: EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                if (isEditing)
                                  CustomCheckbox(
                                    isChecked: isSelected,
                                    onChanged: () {
                                      setState(() {
                                        if (isSelected) {
                                          selectedIndexes.remove(globalIndex);
                                        } else {
                                          selectedIndexes.add(globalIndex);
                                        }
                                      });
                                    },
                                  ),
                                Expanded(
                                  child: Text(
                                    item.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                Text(
                                  "-${item.price}원",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: isEditing && selectedIndexes.isNotEmpty
          ? Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton.icon(
          onPressed: () {
            final indexes = selectedIndexes.toList()
              ..sort((a, b) => b.compareTo(a));
            for (final index in indexes) {
              widget.onDelete?.call(widget.allExpenses[index]);
            }
            setState(() {
              selectedIndexes.clear();
              isEditing = false;
            });
          },
          icon: Icon(Icons.delete),
          label: Text('선택 삭제 (${selectedIndexes.length})'),
          style:
          ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
        ),
      )
          : null,
    );
  }
}
